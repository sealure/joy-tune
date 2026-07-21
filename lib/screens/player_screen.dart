import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../api/gdmusic_client.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  PlayState _playState = PlayState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // 封面 & 歌词
  String? _coverUrl;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  bool _showLyrics = false;
  final ScrollController _lyricScrollCtrl = ScrollController();

  // 专辑旋转动画
  late AnimationController _rotationCtrl;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _lyricScrollCtrl.dispose();
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _initPlayer() {
    if (!mounted) return;
    _initSubscriptions();
    final song = GoRouterState.of(context).extra as Song?;
    if (song == null) return;
    final audio = ref.read(audioServiceProvider);
    _loadSongMetadata(song);
    if (audio.currentSongId != song.id) {
      _playSong(song);
    }
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

  @override
  Widget build(BuildContext context) {
    final song = GoRouterState.of(context).extra as Song?;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('无播放内容')));
    }

    final isCurrentSong = ref.read(audioServiceProvider).currentSongId == song.id;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 模糊背景 ──
          _buildBackground(),

          // ── 主内容 ──
          SafeArea(
            child: Column(
              children: [
                // ── 顶栏 ──
                _buildTopBar(song),

                // ── 封面/歌词区域 ──
                Expanded(child: _buildMainContent()),

                // ── 歌名 + 歌手 ──
                _buildSongInfo(song),

                const SizedBox(height: 16),

                // ── 进度条 + 时间 ──
                _buildProgressBar(progress),

                const SizedBox(height: 8),

                // ── 控制栏 ──
                _buildControls(song, isCurrentSong),

                const SizedBox(height: 16),

                // ── 底栏 ──
                _buildBottomBar(song),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 模糊背景 ──

  Widget _buildBackground() {
    if (_coverUrl == null) {
      return Container(color: Colors.black);
    }
    return Image.network(
      _coverUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              // 暗色渐变遮罩
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          );
        }
        return Container(color: Colors.black);
      },
      errorBuilder: (_, __, ___) => Container(color: Colors.black),
    );
  }

  // ── 顶栏 ──

  Widget _buildTopBar(Song song) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              song.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── 主内容区域 ──

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

  // ── 封面页 ──

  Widget _buildCoverPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          // 圆形专辑封面（带旋转）
          AnimatedBuilder(
            animation: _rotationCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotationCtrl.value * 2 * math.pi,
              child: child,
            ),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
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
          const SizedBox(height: 28),
          // 切换歌词提示
          if (_lyrics.isNotEmpty)
            Text(
              '轻点显示歌词',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
      ),
    );
  }

  // ── 歌词页 ──

  Widget _buildLyricsPage() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
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
              color: isCurrent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
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

  // ── 歌曲信息 ──

  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            song.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── 进度条 ──

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // 进度条轨道
          LayoutBuilder(
            builder: (_, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final p = details.localPosition.dx / constraints.maxWidth;
                  final seekPos = Duration(
                    milliseconds: (_duration.inMilliseconds * p).round(),
                  );
                  ref.read(audioServiceProvider).seek(seekPos);
                },
                child: Container(
                  height: 20,
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 背景轨道
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      // 已播放轨道
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
                      // 拖动圆点
                      Positioned(
                        left: (progress.clamp(0.0, 1.0) * constraints.maxWidth) - 6,
                        top: -4,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
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
          // 时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 控制栏 ──

  Widget _buildControls(Song song, bool isCurrentSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一首
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
            onPressed: () {},
          ),
          const SizedBox(width: 32),
          // 播放/暂停
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _playState == PlayState.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 36,
                color: Colors.black87,
              ),
              onPressed: () => _onPlayToggle(song, isCurrentSong),
            ),
          ),
          const SizedBox(width: 32),
          // 下一首
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── 底栏 ──

  Widget _buildBottomBar(Song song) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 收藏
          _bottomIcon(Icons.favorite_outline_rounded, () => _toggleFavorite(song)),
          // 下载
          _bottomIcon(Icons.download_outlined, () {}),
          // 评论
          _bottomIcon(Icons.chat_bubble_outline_rounded, () {}),
          // 菜单
          _bottomIcon(Icons.playlist_play_rounded, () {}),
        ],
      ),
    );
  }

  Widget _bottomIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 24),
      onPressed: onTap,
      splashRadius: 20,
    );
  }

  // ── 工具 ──

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onPlayToggle(Song song, bool isCurrentSong) {
    final audio = ref.read(audioServiceProvider);
    if (isCurrentSong && _playState == PlayState.playing) {
      audio.pause();
    } else if (isCurrentSong && _playState == PlayState.paused) {
      audio.resume();
    } else {
      _playSong(song);
    }
  }

  Future<void> _playSong(Song song) async {
    final client = ref.read(gdMusicClientProvider);
    final audioService = ref.read(audioServiceProvider);
    try {
      final playUrl = await client.getPlayUrl(songId: song.id, source: song.source);
      await audioService.play(playUrl.url, songId: song.id, song: song);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Song song) async {
    final repo = ref.read(favoriteRepositoryProvider);
    final isFav = await repo.isFavorited(song.id);
    if (isFav) {
      await repo.remove(song.id);
    } else {
      await repo.add(song);
    }
  }
}
