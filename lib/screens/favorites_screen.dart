import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../widgets/song_tile.dart';

final _favoritesProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.getAll();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(_favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline_rounded, size: 64, color: theme.colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text('还没有收藏的歌曲', style: theme.textTheme.bodySmall),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (_, i) => SongTile(
              song: songs[i],
              onTap: () => context.push('/player', extra: songs[i]),
              trailing: IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                onPressed: () async {
                  await ref.read(favoriteRepositoryProvider).remove(songs[i].id);
                  ref.invalidate(_favoritesProvider);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
