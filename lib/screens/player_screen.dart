import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../api/gdmusic_client.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  PlayState _playState = PlayState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // 封面 & 歌词
  String? _coverUrl;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  final ScrollController _lyricScrollCtrl = ScrollController();

  StreamSubscription<PlayState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _lyricScrollCtrl.dispose();
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
      if (mounted) setState(() => _playState = s);
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
    _position = audio.position ?? Duration.zero;
    _duration = audio.duration ?? Duration.zero;
  }

  Future<void> _loadSongMetadata(Song song) async {
    final client = ref.read(gdMusicClientProvider);
    // 重置
    setState(() {
      _coverUrl = null;
      _lyrics = [];
      _currentLyricIndex = -1;
    });

    // 并行获取封面 & 歌词
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
    final offset = (_currentLyricIndex * 44.0) - 88; // 居中的偏移
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

    final theme = Theme.of(context);
    final isCurrentSong = ref.read(audioServiceProvider).currentSongId == song.id;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶栏
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text('正在播放', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_outline_rounded),
                    onPressed: () => _toggleFavorite(song),
                  ),
                ],
              ),
            ),

            // 封面 + 歌词区域
            Expanded(
              child: _lyrics.isNotEmpty ? _buildLyricsView(theme) : _buildCoverView(theme),
            ),

            // 歌名 & 歌手
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(song.name, style: theme.textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(song.artist, style: theme.textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 进度条 + 时间
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: theme.textTheme.labelSmall),
                  Text(_formatDuration(_duration), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: LinearProgressIndicator(
                value: _playState == PlayState.stopped ? 0 : progress,
                backgroundColor: theme.colorScheme.surface,
                color: theme.colorScheme.primary,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 控制栏
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 32),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _playState == PlayState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                      onPressed: () => _onPlayToggle(song, isCurrentSong),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 32),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 封面视图 ──

  Widget _buildCoverView(ThemeData theme) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 260,
          height: 260,
          child: _coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _coverPlaceholder(theme),
                  errorWidget: (_, __, ___) => _coverPlaceholder(theme),
                )
              : _coverPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.music_note_rounded, size: 80, color: theme.colorScheme.primary),
      ),
    );
  }

  // ── 歌词视图 ──

  Widget _buildLyricsView(ThemeData theme) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor, Colors.transparent],
        stops: const [0.0, 0.08, 0.92, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstOut,
      child: ListView.builder(
        controller: _lyricScrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        itemCount: _lyrics.length,
        itemExtent: 44,
        itemBuilder: (_, i) {
          final isCurrent = i == _currentLyricIndex;
          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isCurrent ? 16 : 13,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              height: 1.4,
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
