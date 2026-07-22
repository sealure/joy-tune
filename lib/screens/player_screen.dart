import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../services/audio_cache.dart';
import '../api/gdmusic_client.dart';
import '../theme/player_colors.dart';
import '../utils/lyric_utils.dart';
import '../widgets/player_seek_bar.dart';
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

  late AnimationController _rotationCtrl;
  late AnimationController _favCtrl;

  StreamSubscription<PlayState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

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
    // 注册歌曲切换回调（用于自动前进和手动切歌）
    // 回调模式不存在 stream 时序问题，stop() 后 insertNext() 不会触发任何事件
    ref.read(audioServiceProvider).onSongAdvance = (song) => _onQueueAdvance(song);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  @override
  void dispose() {
    // 注销回调，防止旧 PlayerScreen 干扰新 PlayerScreen
    ref.read(audioServiceProvider).onSongAdvance = null;
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _lyricScrollCtrl.dispose();
    _rotationCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  void _initPlayer() {
    if (!mounted) return;
    final audio = ref.read(audioServiceProvider);
    _initSubscriptions();

    final song = GoRouterState.of(context).extra as Song?;
    print('[Player] _initPlayer: song=${song?.name}, id=${song?.id}, currentSongId=${audio.currentSongId}, queueLen=${audio.queue.length}');
    if (song == null) return;

    if (audio.currentSongId != null && audio.currentSongId == song.id) {
      print('[Player] 跳过: 已在播放');
      _loadSongMetadata(song);
      _checkFavorite(song);
      return;
    }

    print('[Player] 调用 _onQueueAdvance');
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
      return;
    }

    // 无缓存 → 搜索 + 播放
    _loadSongMetadata(song);
    _checkFavorite(song);

    final result = await resolver.resolve(song);
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

  // ── 收藏 ──

  Future<void> _checkFavorite(Song song) async {
    final repo = ref.read(favoriteRepositoryProvider);
    final fav = await repo.isFavorited(song.id);
    if (mounted) setState(() => _isFavorited = fav);
  }

  Future<void> _toggleFavorite(Song song) async {
    final repo = ref.read(favoriteRepositoryProvider);
    if (_isFavorited) {
      await repo.remove(song.id);
      setState(() => _isFavorited = false);
    } else {
      await repo.add(song);
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
      body: Builder(
        builder: (context) {
          final safeHeight = MediaQuery.sizeOf(context).height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              SafeArea(
                child: isDesktop
                    ? Center(
                        child: SizedBox(
                          width: 480,
                          height: safeHeight,
                          child: _buildPlayerColumn(song),
                        ),
                      )
                    : _buildPlayerColumn(song),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerColumn(Song song) {
    return Column(
      children: [
        _buildTopBar(song),
        Expanded(child: _buildMainContent()),
        PlayerSeekBar(
          position: _position,
          duration: _duration,
          onSeek: (pos) => ref.read(audioServiceProvider).seek(pos),
        ),
        const SizedBox(height: 12),
        _buildBottomRow(song),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
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
        child: _showLyrics ? _buildLyricsPage() : _buildCoverPage(),
      ),
    );
  }

  Widget _buildCoverPage() {
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
              width: 280, height: 280,
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
                borderRadius: BorderRadius.circular(140),
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

  // ── 底部控制栏 ──

  Widget _buildBottomRow(Song song) {
    final audio = ref.watch(audioServiceProvider);
    final hasPrev = audio.currentQueueIndex > 0;
    final hasNext = audio.currentQueueIndex < audio.queue.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: _buildSongInfo(song)),
          Expanded(
            flex: 1,
            child: _buildPlaybackControls(song, hasPrev, hasNext),
          ),
          Expanded(flex: 1, child: _buildQueueButton()),
        ],
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    final audio = ref.watch(audioServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _bottomIcon(
              _isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              _isFavorited ? const Color(0xFFEF4444) : null,
              () => _toggleFavorite(song),
            ),
            const SizedBox(width: 4),
            _bottomIcon(Icons.chat_bubble_outline_rounded, null, () => context.push('/comments', extra: song)),
            const SizedBox(width: 4),
            _bottomIcon(_playModeIcon(audio.playMode), null, _cyclePlayMode),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(Song song, bool hasPrev, bool hasNext) {
    final audio = ref.read(audioServiceProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrlBtn(Icons.skip_previous_rounded, 28, hasPrev ? () => audio.playPrevious() : null),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => _onPlayToggle(song),
          child: Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 4))],
            ),
            child: Icon(
              _playState == PlayState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 32,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 20),
        _ctrlBtn(Icons.skip_next_rounded, 28, hasNext ? () => audio.playNext() : null),
      ],
    );
  }

  Widget _buildQueueButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _bottomIcon(Icons.playlist_play_rounded, null, () => PlaylistQueueSheet.show(context)),
      ],
    );
  }

  // ── 通用按钮 ──

  Widget _ctrlBtn(IconData icon, double size, VoidCallback? onTap) {
    return SizedBox(
      width: 44, height: 44,
      child: IconButton(
        icon: Icon(icon, color: onTap != null ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2), size: size),
        onPressed: onTap,
        splashRadius: 22,
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
