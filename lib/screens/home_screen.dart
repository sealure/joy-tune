// 首页
// 展示推荐歌单（从后端获取），支持下拉刷新

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../api/backend_client.dart';
import '../services/providers.dart';

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
        // 迷你播放栏由 _MainShell 统一提供
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
    );
  }

  /// 使用后端数据构建
  Widget _buildWithBackendData(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> playlists,
  ) {
    // 系统推荐歌单（type=system）与用户公开分享歌单（type=user）分区展示
    final systemList = playlists.where((p) => p.type != 'user').toList();
    final sharedList = playlists.where((p) => p.type == 'user').toList();
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recommendPlaylistsProvider);
        // 等待新数据完成，避免下拉动画期间旧数据闪烁
        await ref.read(recommendPlaylistsProvider.future);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (systemList.isNotEmpty) ...[
            _sectionTitle('推荐歌单'),
            _buildCarousel(context, ref, systemList),
          ],
          if (sharedList.isNotEmpty) ...[
            _sectionTitle('分享歌单'),
            _buildCarousel(context, ref, sharedList),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 分区标题
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  /// 横向滚动歌单卡片区
  Widget _buildCarousel(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> list,
  ) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final playlist = list[i];
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
                'coverUrl': playlist.coverUrl,
              },
            ),
          );
        },
      ),
    );
  }

  /// 使用 mock 数据构建（fallback）
  Widget _buildWithMockData(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recommendPlaylistsProvider);
        // 等待新数据完成，避免下拉动画期间旧数据闪烁
        await ref.read(recommendPlaylistsProvider.future);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
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
    // 有封面时作为卡片背景图，否则用渐变背景
    final hasCover = playlist.coverUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasCover
              ? null
              : LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          image: hasCover
              ? DecorationImage(image: NetworkImage(playlist.coverUrl), fit: BoxFit.cover)
              : null,
          boxShadow: [
            BoxShadow(color: gradient.first.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // 底部暗色遮罩，保证文字可读
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 用户公开歌单：显示创建者头像 + 昵称；否则显示歌曲数
                  if (playlist.userName != null && playlist.userName!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: (playlist.userAvatar != null && playlist.userAvatar!.isNotEmpty)
                              ? Image.network(
                                  playlist.userAvatar!,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _defaultAvatar(),
                                )
                              : _defaultAvatar(),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            playlist.userName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                          ),
                        ),
                      ],
                    )
              else
                Text(
                  '${playlist.songCount} 首',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  /// 创建者默认头像占位
  Widget _defaultAvatar() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: const Icon(Icons.person_rounded, size: 10, color: Colors.white70),
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
