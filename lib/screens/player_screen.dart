import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../api/gdmusic_client.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = GoRouterState.of(context).extra as Song?;
    if (song == null) return const Scaffold(body: Center(child: Text('无播放内容')));

    final theme = Theme.of(context);

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
                    onPressed: () => _toggleFavorite(ref, song),
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

            // 进度条
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
              child: LinearProgressIndicator(
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
                      icon: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                      onPressed: () => _playSong(ref, song),
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

  Future<void> _playSong(WidgetRef ref, Song song) async {
    final client = ref.read(gdMusicClientProvider);
    try {
      final playUrl = await client.getPlayUrl(songId: song.id, source: song.source);
      // TODO: 接入 AudioService 播放 playUrl.url
    } catch (e) {
      // 播放失败
    }
  }

  Future<void> _toggleFavorite(WidgetRef ref, Song song) async {
    final repo = ref.read(favoriteRepositoryProvider);
    final isFav = await repo.isFavorited(song.id);
    if (isFav) {
      await repo.remove(song.id);
    } else {
      await repo.add(song);
    }
  }
}
