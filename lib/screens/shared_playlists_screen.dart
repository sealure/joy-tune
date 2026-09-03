// 分享歌单列表页
// 首页「分享歌单」区「更多」进入的全量用户公开歌单列表（type=user 且 is_public=true），
// 数据与首页共用 recommendPlaylistsProvider（本地 SQLite 缓存流式读取），纵向下滑浏览全部，
// 支持下拉刷新（强制拉取后端并覆盖本地缓存）。对应设计稿 ui/shared-playlists/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/backend_client.dart';
import '../services/providers.dart';
import '../widgets/playlist_cover.dart';

/// 分享歌单列表页
class SharedPlaylistsScreen extends ConsumerWidget {
  const SharedPlaylistsScreen({super.key});

  /// 强制刷新推荐歌单：后台拉取后端并覆盖本地缓存，再失效 provider 重新读取（与首页一致）
  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(syncServiceProvider).syncRecommend(force: true);
    ref.invalidate(recommendPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(recommendPlaylistsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('分享歌单')),
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmptyState(ref),
        data: (playlists) {
          // 仅展示用户公开分享歌单（type=user），系统推荐歌单留在首页轮播
          final shared = playlists.where((p) => p.type == 'user').toList();
          if (shared.isEmpty) {
            return _buildEmptyState(ref);
          }
          return _buildList(context, theme, ref, shared);
        },
      ),
    );
  }

  /// 空态：本地无公开歌单缓存（新用户首开 / 后端不可用），下拉刷新引导
  Widget _buildEmptyState(WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Icon(Icons.library_music_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            '还没有分享歌单',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
            '下拉刷新，从服务器拉取大家的公开歌单',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  /// 分享歌单列表（纵向下滑查看全部）
  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<RecommendPlaylist> shared,
  ) {
    // 与首页宫格一致的渐变方案（无封面时占位）
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      [Color(0xFF10B981), Color(0xFF34D399)],
      [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      [Color(0xFFEC4899), Color(0xFFF472B6)],
      [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      [Color(0xFF06B6D4), Color(0xFF22D3EE)],
      [Color(0xFFEF4444), Color(0xFFF87171)],
    ];
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: shared.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final p = shared[i];
          final hasCreator = p.userName != null && p.userName!.isNotEmpty;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            // 点击进入公开歌单详情（与首页卡片一致）
            onTap: () => context.push('/playlist/${p.id}', extra: {
              'id': p.id,
              'name': p.name,
              'subtitle': hasCreator ? '${p.userName} · ${p.songCount} 首' : '${p.songCount} 首',
              'backendId': p.id,
              'isBackendPlaylist': true,
              'coverUrl': p.coverUrl,
              'coverPicId': p.coverPicId,
              'coverSource': p.coverSource,
            }),
            leading: PlaylistCover(
              coverUrl: p.coverUrl,
              coverPicId: p.coverPicId,
              coverSource: p.coverSource,
              size: 56,
              gradient: gradients[i % gradients.length],
            ),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                // 创建者 · 歌曲数（与「收藏的歌单」行信息一致）
                hasCreator ? '${p.userName} · ${p.songCount} 首' : '${p.songCount} 首',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          );
        },
      ),
    );
  }
}
