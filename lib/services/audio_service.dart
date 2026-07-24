import 'dart:async';
import 'package:media_kit/media_kit.dart';
import '../models/song.dart';
import '../db/app_database.dart';
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

  /// 停止标志：stop() 后置 true，防止 _player.stop() 触发的 completed 事件干扰新 PlayerScreen
  /// 新 PlayerScreen 的 _initPlayer 中置 false 并重新触发事件
  bool _stopped = false;

  /// 防重入标志：_applyAndPlay 执行期间置 true，防止 _player.stop() 触发的 completed
  /// 事件连锁调用 _advanceToNext() 导致跳歌（A→B→C→D 连跳）
  bool _transitioning = false;

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
  set playMode(PlayMode mode) {
    _playMode = mode;
    _saveSession(); // 播放模式变化时保存
  }

  /// 定时保存播放进度（每5秒）
  Timer? _saveTimer;

  Duration? get position => _player.state.position;
  Duration? get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;

  AudioService() {
    AudioCache.instance.init().catchError((_) {});

    // 每5秒自动保存播放进度
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveSession());

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

    _player.stream.completed.listen((_) {
      // 防重入：_applyAndPlay 中 _player.stop() 触发的 completed 事件直接忽略
      if (_transitioning) return;
      _advanceToNext();
    });
  }

  // ── 队列管理 ──

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _queue
      ..clear()
      ..addAll(songs);
    _currentQueueIndex = startIndex.clamp(0, _queue.length - 1);
    _saveSession(); // 队列变化时保存
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
    print('[AudioService] _advanceToNext: queueLen=${_queue.length}');
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
    print('[AudioService] stop');
    _stopped = true;
    _transitioning = false;
    _queue.clear();
    _currentQueueIndex = -1;
    currentSongId = null;
    currentSong = null;
    _player.stop();
    AppDatabase.clearPlaySession(); // 停止时清除保存的会话
  }

  /// 清除停止标志，允许 stream 事件正常触发
  void clearStopped() {
    _stopped = false;
  }

  Future<void> seek(Duration position) => _player.seek(position);
  void setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  // ── 内部工具方法 ──

  /// 根据播放模式计算下一首歌的索引
  int _calculateNextIndex() {
    return _playMode.nextIndex(_currentQueueIndex, _queue.length);
  }

  /// 跳转到指定索引并开始播放
  void _applyAndPlay(int index) {
    print('[AudioService] _applyAndPlay: index=$index, stopped=$_stopped');
    // stop() 后的 completed 事件触发的 _applyAndPlay 直接返回，不干扰新 PlayerScreen
    if (_stopped) return;
    // 设置防重入标志，防止 _player.stop() 触发的 completed 事件连锁调用
    _transitioning = true;
    _currentQueueIndex = index;
    final song = _queue[index];
    currentSong = song;
    currentSongId = song.id.isEmpty ? null : song.id;
    _player.stop();
    _updateState(PlayState.loading);
    _nextSongController.add(song);
    // 延迟清除防重入标志，等待 PlayerScreen 接收事件并启动播放
    Future.delayed(const Duration(milliseconds: 200), () {
      _transitioning = false;
    });
  }

  void _updateState(PlayState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  // ── 播放会话持久化 ──

  /// 保存当前播放会话到本地存储
  void _saveSession() {
    if (_queue.isEmpty) return;
    final posMs = _player.state.position.inMilliseconds;
    AppDatabase.savePlaySession(
      queue: _queue,
      currentIndex: _currentQueueIndex,
      positionMs: posMs,
      playMode: _playMode.name,
    );
  }

  /// 从本地存储恢复播放会话（队列+索引+模式），不自动播放
  /// 返回 true 表示有可恢复的会话
  Future<bool> restoreSession() async {
    final session = await AppDatabase.getPlaySession();
    if (session == null) return false;

    final queue = session['queue'] as List<Song>;
    if (queue.isEmpty) return false;

    // 恢复队列和索引
    _queue
      ..clear()
      ..addAll(queue);
    _currentQueueIndex = (session['index'] as int).clamp(0, _queue.length - 1);

    // 恢复当前歌曲信息
    final song = _queue[_currentQueueIndex];
    currentSong = song;
    currentSongId = song.id.isEmpty ? null : song.id;

    // 恢复播放模式
    final modeStr = session['mode'] as String;
    _playMode = PlayMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => PlayMode.loop,
    );

    // 恢复播放位置（毫秒）
    final positionMs = session['position'] as int;

    print('[AudioService] 恢复会话: ${song.name}, 索引=$_currentQueueIndex, '
        '位置=${positionMs}ms, 模式=$_playMode');

    // 通知监听者（MiniPlayerBar 等）状态已更新
    _updateState(PlayState.stopped);

    return true;
  }

  /// 获取上次保存的播放位置（毫秒），用于恢复时 seek
  Future<int> getSavedPosition() async {
    final session = await AppDatabase.getPlaySession();
    return session?['position'] as int? ?? 0;
  }

  void dispose() {
    _saveTimer?.cancel();
    _player.dispose();
    _stateController.close();
    _nextSongController.close();
  }
}
