import 'dart:async';
import 'dart:math' as math;
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

  /// 当前播放模式
  PlayMode _playMode = PlayMode.loop;
  PlayMode get playMode => _playMode;
  set playMode(PlayMode mode) => _playMode = mode;

  Duration? get position => _player.state.position;
  Duration? get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;

  AudioService() {
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

    _player.stream.completed.listen((_) => _advanceToNext());
  }

  // ── 队列管理 ──

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue
      ..clear()
      ..addAll(songs);
    _currentQueueIndex = startIndex.clamp(0, _queue.length - 1);
  }

  void insertNext(Song song) {
    if (_currentQueueIndex < 0) {
      _queue.add(song);
      _currentQueueIndex = _queue.length - 1;
    } else {
      _queue.insert(_currentQueueIndex + 1, song);
      _currentQueueIndex++;
    }
  }

  // ── 播放控制 ──

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _applyAndPlay(index);
  }

  void playNext() {
    if (_queue.isEmpty) return;
    _applyAndPlay(_calculateNextIndex());
  }

  void playPrevious() {
    if (_queue.isEmpty || _currentQueueIndex <= 0) return;
    _applyAndPlay(_currentQueueIndex - 1);
  }

  void _advanceToNext() {
    if (_queue.isEmpty) {
      _updateState(PlayState.stopped);
      return;
    }
    _applyAndPlay(_calculateNextIndex());
  }

  Future<void> play(String url, {String? songId, Song? song}) async {
    _updateState(PlayState.loading);
    currentSongId = songId;
    currentSong = song;

    String? cacheKey;
    String playSource = url;
    if (song != null) {
      cacheKey = AudioCache.cacheKey(song.name, song.artist);
      final cache = AudioCache.instance;
      final localPath = await cache.getLocalPath(cacheKey);
      if (localPath != null) {
        playSource = localPath;
      } else {
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

  // ── 内部工具方法 ──

  /// 根据播放模式计算下一首歌的索引
  int _calculateNextIndex() {
    switch (_playMode) {
      case PlayMode.sequential:
        return _currentQueueIndex;
      case PlayMode.shuffle:
        if (_queue.length == 1) return 0;
        final rng = math.Random();
        int next;
        do {
          next = rng.nextInt(_queue.length);
        } while (next == _currentQueueIndex);
        return next;
      case PlayMode.loop:
        return (_currentQueueIndex + 1) % _queue.length;
    }
  }

  /// 跳转到指定索引并开始播放
  void _applyAndPlay(int index) {
    _currentQueueIndex = index;
    final song = _queue[index];
    currentSong = song;
    currentSongId = song.id.isEmpty ? null : song.id;
    _player.stop();
    _updateState(PlayState.loading);
    _nextSongController.add(song);
  }

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
