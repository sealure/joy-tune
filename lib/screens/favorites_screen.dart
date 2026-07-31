import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player_bar.dart';
import '../utils/player_utils.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
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
          return Column(
            children: [
              // 头部区域：播放全部
              _buildHeader(context, ref, songs),
              // 歌曲列表
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                  itemBuilder: (_, i) => SongTile(
                    song: songs[i],
                    onTap: () => playSong(context, ref, songs[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                      onPressed: () async {
                        await ref.read(favoriteRepositoryProvider).remove(songs[i].id);
                        ref.invalidate(favoritesProvider);
                      },
                    ),
                  ),
                ),
              ),
              // 迷你播放栏
              const MiniPlayerBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, List<Song> songs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF6D28D9), Color(0xFF312E81)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '我的收藏',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '悦听 · 共 ${songs.length} 首',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final audio = ref.read(audioServiceProvider);
                      audio.stop();
                      audio.setQueue(songs, startIndex: 0);
                      context.push('/player', extra: songs[0]);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF6366F1), size: 22),
                          SizedBox(width: 6),
                          Text('播放全部', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
