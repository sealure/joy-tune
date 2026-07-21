import 'dart:async';
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

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  PlayState _playState = PlayState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<PlayState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  void _initPlayer() {
    if (!mounted) return;
    _initSubscriptions();
    final song = GoRouterState.of(context).extra as Song?;
    if (song == null) return;
    final audio = ref.read(audioServiceProvider);
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
      if (mounted) setState(() => _position = p);
    });
    _durSub = audio.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
    // 同步当前状态
    _playState = audio.state;
    _position = audio.position ?? Duration.zero;
    _duration = audio.duration ?? Duration.zero;
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    super.dispose();
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

            const Spacer(),

            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 280,
                height: 280,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(Icons.music_note_rounded, size: 80, color: theme.colorScheme.primary),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 歌名 & 歌手
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(song.name, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(song.artist, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),

            const Spacer(),

            // 进度条 + 时间
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 4),
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
