import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../services/audio_cache.dart';
import '../api/gdmusic_client.dart';
import 'playlist_queue_sheet.dart';

enum PlayMode { listLoop, singleLoop, shuffle }

const _emeraldStart = Color(0xFF064E3B);
const _emeraldMid = Color(0xFF065F46);
const _emeraldEnd = Color(0xFF022C22);
const _placeholderStart = Color(0xFF065F46);
const _placeholderMid = Color(0xFF059669);
const _placeholderEnd = Color(0xFF10B981);

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
  PlayMode _playMode = PlayMode.listLoop;

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

    // 监听队列自动前进
    _nextSub = audio.nextSongStream.listen((song) {
      _onQueueAdvance(song);
    });

    final song = GoRouterState.of(context).extra as Song?;
    if (song == null) return;

    // 已在播放同一首歌 → 只加载元数据
    if (audio.currentSongId != null && audio.currentSongId == song.id) {
      _loadSongMetadata(song);
      _checkFavorite(song);
      return;
    }

    // 未播放或播不同歌 → 搜索 + 播放（_onQueueAdvance 处理一切）
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

  /// 队列自动前进或手动切歌时调用
  Future<void> _onQueueAdvance(Song song) async {
    final audio = ref.read(audioServiceProvider);
    final cache = AudioCache.instance;
    final cacheKey = AudioCache.cacheKey(song.name, song.artist, songId: song.id);

    // 有缓存 → 直接本地播放，零网络
    final localPath = await cache.getLocalPath(cacheKey);
    if (localPath != null) {
      _loadSongMetadata(song);
      _checkFavorite(song);
      if (!mounted) return;
      await audio.play(localPath, songId: song.id, song: song);
      return;
    }

    // 无缓存 → 先加载元数据（封面/歌词），再重试搜索 + 播放
    _loadSongMetadata(song);
    _checkFavorite(song);

    final client = ref.read(gdMusicClientProvider);

    for (int attempt = 0; attempt < 3; attempt++) {
      if (!mounted) return;

      Song playable = song;
      // 搜歌曲（无真实 ID 时）
      if (song.id.isEmpty) {
        final searchService = ref.read(searchServiceProvider);
        try {
          final results = await searchService.search(
            keyword: '${song.name} ${song.artist}',
            source: 'netease',
          );
          if (results.isNotEmpty) playable = results.first;
        } catch (_) {
          if (attempt < 2) continue; // 重试
        }
      }

      try {
        final playUrl = await client.getPlayUrl(songId: playable.id, source: playable.source);
        if (!mounted) return;
        await audio.play(playUrl.url, songId: playable.id, song: playable);
        return; // 成功
      } catch (_) {
        if (attempt < 2) continue; // 重试
      }
    }

    // 3 次均失败 → 自动跳下一曲（不弹错误提示）
    if (!mounted) return;
    audio.playNext();
  }
  }

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

  void _cyclePlayMode() {
    setState(() {
      _playMode = switch (_playMode) {
        PlayMode.listLoop => PlayMode.singleLoop,
        PlayMode.singleLoop => PlayMode.shuffle,
        PlayMode.shuffle => PlayMode.listLoop,
      };
    });
  }

  String _playModeLabel(PlayMode mode) => switch (mode) {
    PlayMode.listLoop => '列表循环',
    PlayMode.singleLoop => '单曲循环',
    PlayMode.shuffle => '随机播放',
  };

  IconData _playModeIcon(PlayMode mode) => switch (mode) {
    PlayMode.listLoop => Icons.repeat_rounded,
    PlayMode.singleLoop => Icons.repeat_one_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final song = audio.currentSong ?? GoRouterState.of(context).extra as Song?;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('无播放内容')));
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final isDesktop = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: isDesktop
                ? Center(
                    child: SizedBox(
                      width: 480,
                      child: _buildPlayerColumn(song, progress),
                    ),
                  )
                : _buildPlayerColumn(song, progress),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerColumn(Song song, double progress) {
    return Column(
      children: [
        _buildTopBar(song),
        Expanded(child: _buildMainContent()),
        _buildSongInfo(song),
        const SizedBox(height: 8),
        _buildProgressBar(progress),
        const SizedBox(height: 2),
        _buildPlayMode(),
        const SizedBox(height: 2),
        _buildControls(song),
        const SizedBox(height: 4),
        _buildBottomBar(song),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
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
              colors: [_emeraldStart, _emeraldMid, _emeraldEnd],
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
          colors: [_placeholderStart, _placeholderMid, _placeholderEnd],
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

  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            song.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (_, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final p = details.localPosition.dx / constraints.maxWidth;
                  final seekPos = Duration(milliseconds: (_duration.inMilliseconds * p).round());
                  ref.read(audioServiceProvider).seek(seekPos);
                },
                child: Container(
                  height: 20,
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: (progress.clamp(0.0, 1.0) * constraints.maxWidth) - 6,
                        top: -4,
                        child: Container(
                          width: 12, height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
              Text(_formatDuration(_duration), style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayMode() {
    return Center(
      child: GestureDetector(
        onTap: _cyclePlayMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_playModeIcon(_playMode), size: 16, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(_playModeLabel(_playMode), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(Song song) {
    final audio = ref.read(audioServiceProvider);
    final hasPrev = audio.currentQueueIndex > 0;
    final hasNext = audio.currentQueueIndex < audio.queue.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlBtn(Icons.skip_previous_rounded, 30, hasPrev ? () => audio.playPrevious() : null),
          const SizedBox(width: 28),
          GestureDetector(
            onTap: () => _onPlayToggle(song),
            child: Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 4))],
              ),
              child: Icon(
                _playState == PlayState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 36,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 28),
          _ctrlBtn(Icons.skip_next_rounded, 30, hasNext ? () => audio.playNext() : null),
        ],
      ),
    );
  }

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

  Widget _buildBottomBar(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomIcon(_isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded, _isFavorited ? const Color(0xFFEF4444) : null, () => _toggleFavorite(song)),
          _bottomIcon(Icons.chat_bubble_outline_rounded, null, () => context.push('/comments', extra: song)),
          _bottomIcon(Icons.playlist_play_rounded, null, () => PlaylistQueueSheet.show(context)),
        ],
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
}
