// 首页
// 展示推荐歌单（从后端获取），支持下拉刷新

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../api/backend_client.dart';
import '../services/providers.dart';
import '../widgets/mini_player_bar.dart';

/// 渐变色列表
const _gradients = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  [Color(0xFF10B981), Color(0xFF34D399)],
  [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  [Color(0xFFEF4444), Color(0xFFF87171)],
  [Color(0xFF06B6D4), Color(0xFF22D3EE)],
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(recommendPlaylistsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: playlistsAsync.when(
                // 后端推荐歌单加载成功
                data: (playlists) {
                  if (playlists.isEmpty) {
                    // 后端无数据时 fallback 到 mock 数据
                    return _buildWithMockData(context, ref);
                  }
                  return _buildWithBackendData(context, ref, playlists);
                },
                // 加载中
                loading: () => const Center(child: CircularProgressIndicator()),
                // 加载失败，fallback 到 mock 数据
                error: (_, __) => _buildWithMockData(context, ref),
              ),
            ),
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  /// 使用后端数据构建
  Widget _buildWithBackendData(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> playlists,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 推荐歌单
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text('推荐歌单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final playlist = playlists[i];
              final gradient = _gradients[i % _gradients.length];
              return _BackendPlaylistCard(
                playlist: playlist,
                gradient: gradient,
                onTap: () => context.push(
                  '/playlist/${playlist.id}',
                  extra: {
                    'id': playlist.id,
                    'name': playlist.name,
                    'subtitle': playlist.description.isNotEmpty
                        ? playlist.description
                        : '${playlist.songCount} 首',
                    'backendId': playlist.id,
                    'isBackendPlaylist': true,
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 使用 mock 数据构建（fallback）
  Widget _buildWithMockData(BuildContext context, WidgetRef ref) {
    return ListView(
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
            itemBuilder: (_, i) => _MockPlaylistCard(
              playlist: recommendedPlaylists[i],
              gradient: recommendationGradients[i % recommendationGradients.length],
              onTap: () => context.push(
                '/playlist/${recommendedPlaylists[i].id}',
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
    );
  }
}

// ── 后端歌单卡片 ──

class _BackendPlaylistCard extends StatelessWidget {
  final RecommendPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _BackendPlaylistCard({
    required this.playlist,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                '${playlist.songCount} 首',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mock 歌单卡片（兼容旧数据）──

class _MockPlaylistCard extends ConsumerWidget {
  final MockPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MockPlaylistCard({required this.playlist, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
