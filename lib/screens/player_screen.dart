import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../services/audio_cache.dart';
import '../services/audio_service.dart';
import '../services/prefetch_service.dart';
import '../api/gdmusic_client.dart';
import '../theme/player_colors.dart';
import '../utils/lyric_utils.dart';
import '../widgets/player_seek_bar.dart';
import '../widgets/favorite_button.dart';
import 'playlist_queue_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  PlayState _playState = PlayState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String? _coverUrl;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  bool _showLyrics = false;
  final ScrollController _lyricScrollCtrl = ScrollController();

  bool _isFavorited = false;
  bool _isRestoringSession = false; // 是否正在恢复播放会话

  late AnimationController _rotationCtrl;
  late AnimationController _favCtrl;

  StreamSubscription<PlayState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<Song>? _nextSub;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _favCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _nextSub?.cancel();
    _lyricScrollCtrl.dispose();
    _rotationCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  void _initPlayer() {
    if (!mounted) return;
    final audio = ref.read(audioServiceProvider);
    _initSubscriptions();

    final routeSong = GoRouterState.of(context).extra as Song?;
    print('[Player] _initPlayer: routeSong=${routeSong?.name}, '
        'currentSongId=${audio.currentSongId}, queueLen=${audio.queue.length}');

    // 清除 stop() 设置的标志，允许 stream 事件正常触发
    audio.clearStopped();

    // 设置 nextSongStream 监听器
    _nextSub?.cancel();
    _nextSub = audio.nextSongStream.listen((song) {
      _onQueueAdvance(song);
    });

    // 情况1：有恢复的会话且当前歌曲匹配，只加载元数据（不播放）
    if (audio.currentSongId != null && routeSong != null &&
        audio.currentSongId == routeSong.id) {
      print('[Player] 跳过: 已在播放');
      _loadSongMetadata(routeSong);
      _checkFavorite(routeSong);
      return;
    }

    // 情况2：有恢复的会话但用户打开了不同歌曲，使用当前会话的歌曲
    if (audio.currentSong != null && audio.queue.isNotEmpty && routeSong == null) {
      final song = audio.currentSong!;
      print('[Player] 使用恢复的歌曲: ${song.name}');
      _loadSongMetadata(song);
      _checkFavorite(song);
      return;
    }

    // 情况3：无恢复会话或打开了新歌曲，开始播放
    final song = routeSong ?? audio.currentSong;
    if (song == null) return;
    // 如果有恢复的会话，标记需要恢复播放位置
    if (audio.queue.isNotEmpty && routeSong != null &&
        audio.currentSongId != routeSong.id) {
      _isRestoringSession = true;
    }
    print('[Player] 调用 _onQueueAdvance: ${song.name}');
    _onQueueAdvance(song);
  }

  void _initSubscriptions() {
    if (!mounted) return;
    final audio = ref.read(audioServiceProvider);
    _stateSub = audio.stateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playState = s);
      if (s == PlayState.playing) {
        _rotationCtrl.repeat();
      } else {
        _rotationCtrl.stop();
      }
    });
    _posSub = audio.positionStream.listen((p) {
      _position = p;
      _updateCurrentLyric(p);
      if (mounted) setState(() {});
    });
    _durSub = audio.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
    _playState = audio.state;
    if (audio.isPlaying) _rotationCtrl.repeat();
    _position = audio.position ?? Duration.zero;
    _duration = audio.duration ?? Duration.zero;
  }

  // ── 播放流程 ──

  Future<void> _onQueueAdvance(Song song) async {
    print('[Player] _onQueueAdvance: ${song.name}');
    final audio = ref.read(audioServiceProvider);
    final resolver = ref.read(songResolverProvider);
    final cache = AudioCache.instance;
    final cacheKey = AudioCache.cacheKey(song.name, song.artist);

    // 保存播放前的位置，用于恢复时 seek
    final savedPos = _isRestoringSession ? await audio.getSavedPosition() : 0;
    _isRestoringSession = false;

    // 有缓存 → 直接本地播放
    final localPath = await cache.getLocalPath(cacheKey);
    print('[Player] 缓存: ${localPath ?? "无"}');
    if (localPath != null) {
      final meta = await cache.loadMetadata(cacheKey);
      if (meta != null && mounted) {
        setState(() {
          _coverUrl = meta['coverUrl'] as String?;
          if (meta['lyrics'] is String) {
            _lyrics = parseLrc(meta['lyrics'] as String);
          }
        });
      } else {
        _loadSongMetadata(song);
      }
      _checkFavorite(song);
      if (!mounted) return;
      await audio.play(localPath, songId: song.id, song: song);
      // 恢复播放位置
      if (savedPos > 0) await audio.seek(Duration(milliseconds: savedPos));
      // 播放成功后预缓存下一首
      _fetchPrefetchNext(audio);
      return;
    }

    // 无缓存 → 直接用已有 ID 解析（不重新搜索，避免匹配到翻唱/Live版本）
    _loadSongMetadata(song);
    _checkFavorite(song);

    final result = await resolver.resolveDirectly(song);
    print('[Player] resolve: ${result != null ? "OK" : "NULL"}');
    if (result == null || !mounted) {
      print('[Player] resolve失败或未挂载');
      audio.playNext();
      return;
    }

    try {
      final playUrl = await ref.read(gdMusicClientProvider).getPlayUrl(
        songId: result.playable.id,
        source: result.playable.source,
      );
      print('[Player] url: ${playUrl.url.isNotEmpty ? "有" : "空"}, mounted=$mounted');
      if (!mounted) return;
      print('[Player] 调用audio.play');
      await audio.play(playUrl.url, songId: result.playable.id, song: result.playable);
      // 恢复播放位置
      if (savedPos > 0) await audio.seek(Duration(milliseconds: savedPos));
      // 播放成功后预缓存下一首
      _fetchPrefetchNext(audio);
      print('[Player] 播放成功');
      if (mounted) {
        setState(() {
          if (result.coverUrl != null) _coverUrl = result.coverUrl;
          if (result.lyricsText != null) _lyrics = parseLrc(result.lyricsText!);
        });
      }
      if (result.coverUrl != null || result.lyricsText != null) {
        cache.saveMetadata(cacheKey, {
          'coverUrl': result.coverUrl,
          'lyrics': result.lyricsText,
        });
      }
    } catch (e) {
      print('[Player] 播放异常: $e');
      audio.playNext();
    }
  }

  void _onPlayToggle(Song song) {
    final audio = ref.read(audioServiceProvider);
    if (_playState == PlayState.playing) {
      audio.pause();
    } else if (_playState == PlayState.paused) {
      audio.resume();
    } else {
      _onQueueAdvance(song);
    }
  }

  /// 预缓存下一首歌的音频和元数据（异步，不阻塞播放）
  void _fetchPrefetchNext(AudioService audio) {
    if (!mounted) return;
    final queue = audio.queue;
    final currentIndex = audio.currentQueueIndex;
    if (queue.isEmpty || currentIndex < 0) return;

    // 计算下一首索引，仅一首歌时跳过
    final nextIdx = audio.playMode.nextIndex(currentIndex, queue.length);
    if (nextIdx == currentIndex) return;

    final resolver = ref.read(songResolverProvider);
    final client = ref.read(gdMusicClientProvider);
    PrefetchService.instance.prefetchNext(
      resolver: resolver,
      client: client,
      queue: queue,
      currentIndex: currentIndex,
      playMode: audio.playMode,
    );
  }

  // ── 收藏（本地 + 后端同步）──

  Future<void> _checkFavorite(Song song) async {
    // 同时检查本地和后端
    final repo = ref.read(favoriteRepositoryProvider);
    final fav = await repo.isFavorited(song.id);
    if (mounted) setState(() => _isFavorited = fav);
  }

  Future<void> _toggleFavorite(Song song) async {
    final repo = ref.read(favoriteRepositoryProvider);
    final backend = ref.read(backendClientProvider);

    if (_isFavorited) {
      // 取消收藏：本地 + 后端
      await repo.remove(song.id);
      await backend.unlikeSong(song.id);
      setState(() => _isFavorited = false);
    } else {
      // 收藏：本地 + 后端
      await repo.add(song);
      await backend.likeSong(
        song.id,
        songName: song.name,
        artist: song.artist,
        source: song.source,
      );
      setState(() => _isFavorited = true);
      _favCtrl.forward().then((_) => _favCtrl.reverse());
    }
  }

  // ── 元数据加载 ──

  Future<void> _loadSongMetadata(Song song) async {
    final client = ref.read(gdMusicClientProvider);
    setState(() {
      _coverUrl = null;
      _lyrics = [];
      _currentLyricIndex = -1;
      _showLyrics = false;
    });
    await Future.wait([
      _loadCover(client, song),
      _loadLyrics(client, song),
    ]);
  }

  Future<void> _loadCover(GdMusicClient client, Song song) async {
    if (song.picId == null || song.picId!.isEmpty) return;
    try {
      final url = await client.getCoverUrl(picId: song.picId!, source: song.source);
      if (mounted) setState(() => _coverUrl = url);
    } catch (_) {}
  }

  Future<void> _loadLyrics(GdMusicClient client, Song song) async {
    if (song.lyricId == null || song.lyricId!.isEmpty) return;
    try {
      final lyric = await client.getLyric(lyricId: song.lyricId!, source: song.source);
      if (mounted && lyric != null && lyric.lyric != null && lyric.lyric!.isNotEmpty) {
        setState(() => _lyrics = parseLrc(lyric.lyric!));
      }
    } catch (_) {}
  }

  // ── 歌词同步 ──

  void _updateCurrentLyric(Duration position) {
    if (_lyrics.isEmpty) return;
    int idx = _lyrics.length - 1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time > position) {
        idx = i - 1;
        break;
      }
    }
    if (idx != _currentLyricIndex) {
      _currentLyricIndex = idx;
      _scrollToCurrentLyric();
    }
  }

  void _scrollToCurrentLyric() {
    if (_currentLyricIndex < 0 || _lyricScrollCtrl.hasClients == false) return;
    final offset = (_currentLyricIndex * 48.0) - 120;
    _lyricScrollCtrl.animateTo(
      offset.clamp(0.0, _lyricScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── 播放模式 ──

  void _cyclePlayMode() {
    final audio = ref.read(audioServiceProvider);
    final next = switch (audio.playMode) {
      PlayMode.loop => PlayMode.sequential,
      PlayMode.sequential => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.loop,
    };
    audio.playMode = next;
    setState(() {});
  }

  IconData _playModeIcon(PlayMode mode) => switch (mode) {
    PlayMode.loop => Icons.repeat_rounded,
    PlayMode.sequential => Icons.repeat_one_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
  };

  // ── UI 构建 ──

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final song = audio.currentSong ?? GoRouterState.of(context).extra as Song?;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('无播放内容')));
    }

    final isDesktop = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              SafeArea(
                child: isDesktop
                    ? Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                          ),
                          child: _buildPlayerColumn(song),
                        ),
                      )
                    : _buildPlayerColumn(song),
              ),
            ],
          ),
    );
  }

  Widget _buildPlayerColumn(Song song) {
    return Column(
      children: [
        _buildTopBar(song),
        Expanded(child: _buildMainContent()),
        // 进度条
        PlayerSeekBar(
          position: _position,
          duration: _duration,
          onSeek: (pos) => ref.read(audioServiceProvider).seek(pos),
        ),
        const SizedBox(height: 8),
        // 名称-作者（居中）
        _buildSongInfoRow(song),
        const SizedBox(height: 4),
        // 底部控制栏：收藏、评论、播放控制、循环模式、播放列表
        _buildBottomControls(song),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PlayerColors.backgroundTop,
                PlayerColors.backgroundMid,
                PlayerColors.backgroundBottom,
              ],
            ),
          ),
        ),
        if (_coverUrl != null)
          Image.network(
            _coverUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox.shrink();
            },
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
                Colors.black,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Song song) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          _topBarBtn(Icons.keyboard_arrow_down_rounded, () => context.pop()),
          Expanded(
            child: Text(
              song.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0x99FFFFFF),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _topBarBtn(Icons.more_horiz_rounded, () {}),
        ],
      ),
    );
  }

  Widget _topBarBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 36, height: 36,
      child: IconButton(
        icon: Icon(icon, color: const Color(0x99FFFFFF), size: 24),
        onPressed: onTap,
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMainContent() {
    // 封面页需要根据可用空间动态计算尺寸，避免窗口缩小时溢出
    return LayoutBuilder(
      builder: (context, constraints) {
        // 封面页：封面 + 上下间距(各20) + 提示文字(约20)
        final maxCoverSize = (constraints.maxHeight - 60).clamp(120.0, 280.0);
        return GestureDetector(
          onTap: () {
            if (_lyrics.isNotEmpty) {
              setState(() => _showLyrics = !_showLyrics);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showLyrics
                ? _buildLyricsPage()
                : _buildCoverPage(coverSize: maxCoverSize),
          ),
        );
      },
    );
  }

  Widget _buildCoverPage({required double coverSize}) {
    final borderRadius = coverSize / 2;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _rotationCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotationCtrl.value * 2 * math.pi,
              child: child,
            ),
            child: Container(
              width: coverSize, height: coverSize,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: _coverUrl != null
                    ? Image.network(
                        _coverUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _coverPlaceholder();
                        },
                        errorBuilder: (_, __, ___) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_lyrics.isNotEmpty)
            Text(
              '轻点显示歌词',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PlayerColors.placeholderTop,
            PlayerColors.placeholderMid,
            PlayerColors.placeholderBottom,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildLyricsPage() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: const [0.0, 0.1, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _lyricScrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        itemCount: _lyrics.length,
        itemExtent: 48,
        itemBuilder: (_, i) {
          final isCurrent = i == _currentLyricIndex;
          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: isCurrent ? 17 : 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.3),
              height: 1.3,
            ),
            child: Text(
              _lyrics[i].text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  // ── 名称-作者行（居中）──

  Widget _buildSongInfoRow(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            song.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            song.artist,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 底部控制栏：收藏 | 评论 | 播放控制 | 循环模式 | 播放列表 ──

  Widget _buildBottomControls(Song song) {
    final audio = ref.watch(audioServiceProvider);
    final hasPrev = audio.currentQueueIndex > 0;
    final hasNext = audio.currentQueueIndex < audio.queue.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 收藏
          FavoriteButton(song: song),
          // 评论
          _bottomIcon(Icons.chat_bubble_outline_rounded, null, () => context.push('/comments', extra: song)),
          // 播放控制（上一步 / 播放暂停 / 下一步）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ctrlBtn(Icons.skip_previous_rounded, 26, hasPrev ? () => audio.playPrevious() : null),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _onPlayToggle(song),
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 4))],
                  ),
                  child: Icon(
                    _playState == PlayState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ctrlBtn(Icons.skip_next_rounded, 26, hasNext ? () => audio.playNext() : null),
            ],
          ),
          // 循环模式
          _bottomIcon(_playModeIcon(audio.playMode), null, _cyclePlayMode),
          // 播放列表
          _bottomIcon(Icons.playlist_play_rounded, null, () => PlaylistQueueSheet.show(context)),
        ],
      ),
    );
  }

  // ── 通用按钮 ──

  Widget _ctrlBtn(IconData icon, double size, VoidCallback? onTap) {
    return SizedBox(
      width: 36, height: 36,
      child: IconButton(
        icon: Icon(icon, color: onTap != null ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2), size: size),
        onPressed: onTap,
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _bottomIcon(IconData icon, Color? color, VoidCallback onTap) {
    return SizedBox(
      width: 44, height: 44,
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.6), size: 24),
        onPressed: onTap,
        splashRadius: 22,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
