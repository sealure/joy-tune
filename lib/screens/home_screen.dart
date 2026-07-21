import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../services/providers.dart';
import '../widgets/mini_player_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 快捷入口
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _QuickCard(
                    icon: Icons.favorite_outline_rounded,
                    label: '我的收藏',
                    color: const Color(0xFFEF4444),
                    onTap: () => context.push('/favorites'),
                  ),
                  const SizedBox(width: 12),
                  _QuickCard(
                    icon: Icons.search_rounded,
                    label: '搜索歌曲',
                    color: theme.colorScheme.primary,
                    onTap: () => context.push('/search'),
                  ),
                ],
              ),
            ),

            // 推荐歌单
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Text('推荐歌单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: recommendedPlaylists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => _PlaylistCard(
                        playlist: recommendedPlaylists[i],
                        gradient: recommendationGradients[i % recommendationGradients.length],
                        onTap: () => context.push(
                          '/playlist/${recommendedPlaylists[i].id}',
                          // 传递歌单元数据，不含歌曲列表
                          extra: {
                            'id': recommendedPlaylists[i].id,
                            'name': recommendedPlaylists[i].name,
                            'subtitle': recommendedPlaylists[i].subtitle,
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // 迷你播放栏
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }
}

// ── 快捷入口卡片 ──

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: color.withValues(alpha: 0.05),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 10),
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 推荐歌单卡片 ──

class _PlaylistCard extends ConsumerWidget {
  final MockPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PlaylistCard({required this.playlist, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听歌单歌曲数量（使用 playlistId 作为 key）
    final songsAsync = ref.watch(playlistSongsProvider(playlist.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: gradient.first.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(Icons.album_rounded, size: 48, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
              Text(
                playlist.name,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // 根据 Provider 状态显示歌曲数量
              songsAsync.when(
                data: (songs) => Text(
                  '${songs.length} 首',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
                loading: () => Text(
                  '加载中...',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
                error: (_, __) => Text(
                  '加载失败',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
