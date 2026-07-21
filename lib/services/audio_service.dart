import 'dart:async';
import 'package:media_kit/media_kit.dart';
import '../models/song.dart';
import 'audio_cache.dart';

/// 音频播放服务（基于 media_kit）
class AudioService {
  final Player _player = Player();
  String? currentSongId;
  Song? currentSong;

  // ── 播放队列 ──
  final List<Song> _queue = [];
  int _currentQueueIndex = -1;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentQueueIndex => _currentQueueIndex;

  /// 当队列自动前进到下一首时触发，外部负责获取 URL 并调用 play
  final StreamController<Song> _nextSongController =
      StreamController<Song>.broadcast();
  Stream<Song> get nextSongStream => _nextSongController.stream;

  // ── 可观察状态 ──
  final StreamController<PlayState> _stateController =
      StreamController<PlayState>.broadcast();

  Stream<PlayState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration?> get durationStream => _player.stream.duration;

  PlayState _state = PlayState.stopped;
  PlayState get state => _state;

  Duration? get position => _player.state.position;
  Duration? get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;

  AudioService() {
    // 初始化音频缓存
    AudioCache.instance.init().catchError((_) {});

    _player.stream.error.listen((_) => _updateState(PlayState.stopped));

    _player.stream.buffering.listen((buffering) {
      if (buffering && !_player.state.playing) {
        _updateState(PlayState.loading);
      }
    });

    _player.stream.playing.listen((playing) {
      if (playing) {
        _updateState(PlayState.playing);
      } else if (_state == PlayState.playing || _state == PlayState.loading) {
        _updateState(PlayState.paused);
      }
    });

    // 播放完成 → 自动下一首
    _player.stream.completed.listen((_) => _advanceToNext());
  }

  /// 设置队列并播放下标为 [startIndex] 的歌曲
  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue
      ..clear()
      ..addAll(songs);
    _currentQueueIndex = startIndex.clamp(0, _queue.length - 1);
  }

  /// 跳转到队列中指定位置的歌曲
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentQueueIndex = index;
    final song = _queue[index];
    currentSong = song;
    currentSongId = song.id.isEmpty ? null : song.id;
    _player.stop();
    _updateState(PlayState.loading);
    _nextSongController.add(song);
  }

  /// 播放下⼀首（触发外部获取 URL）
  Future<void> playNext() async {
    if (_queue.isEmpty || _currentQueueIndex >= _queue.length - 1) {
      stop();
      return;
    }
    _currentQueueIndex++;
    final next = _queue[_currentQueueIndex];
    currentSong = next;
    currentSongId = next.id.isEmpty ? null : next.id;
    _player.stop();
    _updateState(PlayState.loading);
    _nextSongController.add(next);
  }

  /// 播放上一首
  Future<void> playPrevious() async {
    if (_queue.isEmpty || _currentQueueIndex <= 0) {
      return;
    }
    _currentQueueIndex--;
    final prev = _queue[_currentQueueIndex];
    currentSong = prev;
    currentSongId = prev.id.isEmpty ? null : prev.id;
    _player.stop();
    _updateState(PlayState.loading);
    _nextSongController.add(prev);
  }

  /// 播放单曲（替换当前内容，不入队列）
  /// 有缓存时从本地播放，无缓存时播放 URL 并在后台缓存
  Future<void> play(String url, {String? songId, Song? song}) async {
    _updateState(PlayState.loading);
    currentSongId = songId;
    currentSong = song;

    // 用名称生成缓存 key，检查本地缓存
    String? cacheKey;
    String playSource = url;
    if (song != null) {
      cacheKey = AudioCache.cacheKey(song.name, song.artist);
      final cache = AudioCache.instance;
      final localPath = await cache.getLocalPath(cacheKey);
      if (localPath != null) {
        playSource = localPath;
      } else {
        // 无缓存，后台下载
        cache.download(url, cacheKey).then((_) {}, onError: (_) {});
      }
    }

    try {
      await _player.open(Media(playSource));
      await _player.play();
    } catch (e) {
      currentSongId = null;
      currentSong = null;
      _updateState(PlayState.stopped);
      rethrow;
    }
  }

  void _advanceToNext() {
    if (_queue.isEmpty || _currentQueueIndex >= _queue.length - 1) {
      _updateState(PlayState.stopped);
      return;
    }
    _currentQueueIndex++;
    final next = _queue[_currentQueueIndex];
    currentSong = next;
    currentSongId = next.id.isEmpty ? null : next.id;
    _nextSongController.add(next);
  }

  void pause() => _player.pause();
  void resume() => _player.play();

  void stop() {
    _queue.clear();
    _currentQueueIndex = -1;
    currentSongId = null;
    currentSong = null;
    _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  void setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  void _updateState(PlayState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
    _nextSongController.close();
  }
}
