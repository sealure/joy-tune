import 'dart:async';
import 'dart:convert';
import 'package:media_kit/media_kit.dart';
import '../api/gdmusic_client.dart';
import '../models/song.dart';
import '../db/daos/session_dao.dart';
import 'audio_cache.dart';
import 'prefetch_service.dart';
import 'song_resolver.dart';

/// 音频播放服务（基于 media_kit）
class AudioService {
  /// 播放会话数据访问（本地 SQLite），可空以便脱离数据库的测试场景
  final SessionDao? _sessionDao;
  final Player _player = Player();
  String? currentSongId;
  Song? currentSong;

  /// 歌曲解析器（查缓存/解析播放地址），可空以便脱离数据库的测试场景
  final SongResolver? _songResolver;
  /// 音乐 API 客户端（取播放 URL），可空以便脱离数据库的测试场景
  final GdMusicClient? _gdMusicClient;

  /// 播放上报回调：一首歌成功开始播放时触发，外部用于埋点（如上报听歌总数）
  Future<void> Function(Song song)? onSongPlayed;

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

  /// 打开媒体标志：play() 打开新媒体期间置 true，抑制 media_kit 在 open 阶段
  /// 误触发的 completed 事件（否则刚 open 就被误判为播完，触发切歌/中断刚开始的播放）
  bool _opening = false;

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

  AudioService({
    SessionDao? sessionDao,
    SongResolver? songResolver,
    GdMusicClient? gdMusicClient,
  })  : _sessionDao = sessionDao,
        _songResolver = songResolver,
        _gdMusicClient = gdMusicClient {
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
      if (_transitioning) {
        print('[AudioService] completed 被 _transitioning 抑制');
        return;
      }
      // 防误触发：play() 打开新媒体阶段 media_kit 会发一次 completed，忽略避免误切歌/中断播放
      if (_opening) {
        print('[AudioService] completed 被 _opening 抑制(open阶段)');
        return;
      }
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
    // 手动「下一首」不应受播放模式限制：
    // 单曲循环(sequential)时 nextIndex 返回当前索引，会导致手动换歌无效（点击像没反应）。
    // 因此手动切歌统一按列表循环切到下一首（随机模式仍随机切），
    // 单曲循环只影响「自动播完」后的 _advanceToNext 行为。
    final next = _playMode == PlayMode.shuffle
        ? _calculateNextIndex()
        : (_currentQueueIndex + 1) % _queue.length;
    print('[AudioService] playNext: 当前=$_currentQueueIndex → 目标=$next (mode=$_playMode)');
    _applyAndPlay(next);
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
    print('[AudioService] play(): urlLen=${url.length}, songId=$songId, song=${song?.name}');
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

    // 打开新媒体阶段置位，抑制 media_kit open 时误触发的 completed（防止刚 open 就切歌）
    _opening = true;
    try {
      await _player.open(Media(playSource));
      await _player.play();
      // 播放成功后触发埋点回调（不阻塞播放流程）
      if (song != null) {
        unawaited(onSongPlayed?.call(song));
      }
    } catch (e) {
      _opening = false;
      currentSongId = null;
      currentSong = null;
      _updateState(PlayState.stopped);
      rethrow;
    }
    // 播放稳定后清除保护，使真正的 completed（播到结尾）能正常触发下一首
    Future.delayed(const Duration(milliseconds: 300), () {
      _opening = false;
    });
  }

  /// 播放指定歌曲（PlayerScreen 与 mini 播放器共用的统一播放入口）。
  /// 内部完成：查本地缓存 → 命中直接本地播放；未命中解析播放地址后播放；失败自动切下一首。
  /// 返回解析/缓存到的元数据（封面/歌词，可为空），供调用方更新 UI。
  /// [restorePosition] 为 true 时，播放成功后 seek 到上次保存的位置（会话恢复场景）。
  Future<SongResolveResult?> playSong(Song song, {bool restorePosition = false}) async {
    final cache = AudioCache.instance;
    final cacheKey = AudioCache.cacheKey(song.name, song.artist);
    final savedPos = restorePosition ? await getSavedPosition() : 0;
    print('[AudioService] playSong: ${song.name}, restorePosition=$restorePosition, savedPos=$savedPos');

    // 缓存命中 → 直接用本地文件播放（不重新解析）
    final localPath = await cache.getLocalPath(cacheKey);
    if (localPath != null) {
      print('[AudioService] playSong 命中缓存: ${song.name} → $localPath');
      await play(localPath, songId: song.id, song: song);
      if (savedPos > 0) await seek(Duration(milliseconds: savedPos));
      _prefetchNext();
      // 读取缓存中的封面/歌词元数据返回，供调用方展示
      final meta = await cache.loadMetadata(cacheKey);
      if (meta != null) {
        return SongResolveResult(
          playable: song,
          coverUrl: meta['coverUrl'] as String?,
          lyricsText: meta['lyrics'] is String ? meta['lyrics'] as String : null,
        );
      }
      return null;
    }

    // 无缓存 → 解析播放地址（song_id 每次拿新签名最可靠，不依赖后端 audio_url）
    if (_songResolver == null || _gdMusicClient == null) {
      print('[AudioService] playSong: 缺少解析依赖(songResolver/gdMusicClient)，自动切下一首');
      playNext();
      return null;
    }
    try {
      final result = await _songResolver.resolveDirectly(song);
      print('[AudioService] playSong resolve: ${result != null ? "OK" : "NULL"}');
      if (result == null) {
        print('[AudioService] playSong 解析失败 → 自动切下一首');
        playNext();
        return null;
      }
      final playUrl = await _gdMusicClient.getPlayUrl(
        songId: result.playable.id,
        source: result.playable.source,
      );
      print('[AudioService] playSong url: ${playUrl.url.isNotEmpty ? "有" : "空"}');
      await play(playUrl.url, songId: result.playable.id, song: result.playable)
          .timeout(const Duration(seconds: 15));
      if (savedPos > 0) await seek(Duration(milliseconds: savedPos));
      // 缓存音频与元数据（封面/歌词），离线可播可看
      if (result.coverUrl != null || result.lyricsText != null) {
        cache.saveMetadata(cacheKey, {
          'coverUrl': result.coverUrl,
          'lyrics': result.lyricsText,
        });
      }
      _prefetchNext();
      return result;
    } catch (e) {
      print('[AudioService] playSong 播放异常: $e');
      playNext();
      return null;
    }
  }

  /// 当前歌曲播放成功后，后台预缓存队列中下一首歌（无感切歌）
  void _prefetchNext() {
    if (_queue.isEmpty || _currentQueueIndex < 0) return;
    final nextIdx = _playMode.nextIndex(_currentQueueIndex, _queue.length);
    if (nextIdx == _currentQueueIndex) return; // 仅一首歌/单曲循环，无需预缓存
    final resolver = _songResolver;
    final client = _gdMusicClient;
    if (resolver == null || client == null) return;
    PrefetchService.instance.prefetchNext(
      resolver: resolver,
      client: client,
      queue: _queue,
      currentIndex: _currentQueueIndex,
      playMode: _playMode,
    );
  }

  void pause() {
    print('[AudioService] pause(): state=$_state');
    _player.pause();
  }

  void resume() {
    // 诊断日志：resume 直接裸调 _player.play()。若重启后仅恢复会话（未 open 媒体），
    // 此处 play() 因无可播放媒体而无效，表现为「点击播放无用」
    print('[AudioService] resume(): state=$_state, '
        'playerPlaying=${_player.state.playing}, '
        'mediaLoaded(duration>0)=${_player.state.duration.inMilliseconds > 0}, '
        'durationMs=${_player.state.duration.inMilliseconds}, '
        'currentSong=${currentSong?.name}');

    // 无媒体时裸 play() 无效（media_kit 会把 playing 置 true 造成假的播放态，实际无声）。
    // 此场景由调用方（mini 播放器/播放页）走 playSong() 真正解析+open 媒体，这里直接忽略。
    if (_player.state.duration.inMilliseconds <= 0) {
      print('[AudioService] resume(): 无媒体(duration=0)，忽略本次 play，避免假播放');
      return;
    }
    _player.play();
    // 播放后打印一次播放状态 200ms，确认 play 是否真正生效
    Future.delayed(const Duration(milliseconds: 200), () {
      print('[AudioService] resume() 后: playing=${_player.state.playing}, '
          'durationMs=${_player.state.duration.inMilliseconds}');
    });
  }

  void stop() {
    print('[AudioService] stop');
    _stopped = true;
    _transitioning = false;
    _opening = false;
    _queue.clear();
    _currentQueueIndex = -1;
    currentSongId = null;
    currentSong = null;
    _player.stop();
    _sessionDao?.clearSession(); // 停止时清除保存的会话
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

  /// 保存当前播放会话到本地 SQLite
  void _saveSession() {
    if (_queue.isEmpty) return;
    final posMs = _player.state.position.inMilliseconds;
    _sessionDao?.saveSession(
      queueJson: jsonEncode(_queue.map((s) => s.toJson()).toList()),
      currentIndex: _currentQueueIndex,
      positionMs: posMs,
      playMode: _playMode.name,
    );
  }

  /// 从本地 SQLite 恢复播放会话（队列+索引+模式），不自动播放
  /// 返回 true 表示有可恢复的会话
  Future<bool> restoreSession() async {
    final session = await _sessionDao?.loadSession();
    if (session == null || session.queueJson == null) return false;

    final queue = (jsonDecode(session.queueJson!) as List<dynamic>)
        .map((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList();
    if (queue.isEmpty) return false;

    // 恢复队列和索引
    _queue
      ..clear()
      ..addAll(queue);
    _currentQueueIndex = session.currentIndex.clamp(0, _queue.length - 1);

    // 恢复当前歌曲信息
    final song = _queue[_currentQueueIndex];
    currentSong = song;
    currentSongId = song.id.isEmpty ? null : song.id;

    // 恢复播放模式
    final modeStr = session.playMode;
    _playMode = PlayMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => PlayMode.loop,
    );

    // 恢复播放位置（毫秒）
    final positionMs = session.positionMs;

    print('[AudioService] 恢复会话: ${song.name}, 索引=$_currentQueueIndex, '
        '位置=${positionMs}ms, 模式=$_playMode');

    // 注意：此处仅恢复元数据（队列/索引/歌曲），未真正 open 媒体。
    // 此时 mini 播放器显示播放按钮，但若用户直接点播放，resume() 的裸 _player.play() 无媒体可播 → 点击无效。
    print('[AudioService] 会话已恢复，但 player 未加载媒体(需真正播放时走解析+open)');

    // 通知监听者（MiniPlayerBar 等）状态已更新
    _updateState(PlayState.stopped);

    return true;
  }

  /// 获取上次保存的播放位置（毫秒），用于恢复时 seek
  Future<int> getSavedPosition() async {
    final session = await _sessionDao?.loadSession();
    return session?.positionMs ?? 0;
  }

  void dispose() {
    _saveTimer?.cancel();
    _player.dispose();
    _stateController.close();
    _nextSongController.close();
  }
}
