// 我的歌单列表页
// 顶部「我的歌单 / 收藏的歌单」两个 Tab：
//  - 我的歌单：本地 SQLite 自建歌单（登录后 SyncService 同步到服务端），支持新建/编辑/删除/分享
//  - 收藏的歌单：收藏的他人公开歌单（订阅引用，只读，跟随创建者更新），支持取消收藏
// 对应设计稿 ui/my-playlists/、ui/follow-playlists/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../repositories/playlist_follow_repository.dart';
import '../repositories/playlist_repository.dart';
import '../services/providers.dart';
import '../utils/playlist_share.dart';
import '../widgets/playlist_form_sheet.dart';
import '../widgets/playlist_cover.dart';

/// 我的歌单列表页
class MyPlaylistsScreen extends ConsumerStatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  ConsumerState<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends ConsumerState<MyPlaylistsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 格式化创建日期
  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d 创建';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的歌单'),
        actions: [
          // 新建按钮仅「我的歌单」Tab 显示（收藏 Tab 为订阅引用，无需新建）
          if (_tabController.index == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showPlaylistForm(context, ref),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('新建', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: '我的歌单'), Tab(text: '收藏的歌单')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPlaylists(theme),
          _buildFollowedPlaylists(theme),
        ],
      ),
    );
  }

  // ── Tab1 我的歌单 ──

  Widget _buildMyPlaylists(ThemeData theme) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (playlists) {
        if (playlists.isEmpty) {
          return _EmptyState(onCreate: () => _showPlaylistForm(context, ref));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myPlaylistsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final p = playlists[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                onTap: () => context.push('/my-playlist/${p.localId}'),
                leading: PlaylistCover(coverUrl: p.coverUrl, size: 56),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      if (p.isPublic)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public_rounded, color: Color(0xFF6366F1), size: 11),
                              SizedBox(width: 2),
                              Text('公开', style: TextStyle(fontSize: 11, color: Color(0xFF6366F1))),
                            ],
                          ),
                        ),
                      Flexible(
                        child: Text(
                          '${p.songCount} 首 · ${_formatDate(p.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<_RowAction>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (action) => _onRowAction(context, ref, p, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _RowAction.edit, child: Text('编辑信息')),
                    PopupMenuItem(value: _RowAction.share, child: Text('分享')),
                    PopupMenuItem(value: _RowAction.delete, child: Text('删除歌单', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// ⋮ 菜单操作
  Future<void> _onRowAction(
      BuildContext context, WidgetRef ref, LocalPlaylistInfo playlist, _RowAction action) async {
    switch (action) {
      case _RowAction.edit:
        await _showPlaylistForm(context, ref, existing: playlist);
        break;
      case _RowAction.share:
        if (!playlist.synced) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('歌单同步到账号后即可分享')),
            );
          }
          break;
        }
        await showPlaylistShareSheet(context, ref, playlist);
        break;
      case _RowAction.delete:
        await _confirmDelete(context, ref, playlist);
        break;
    }
  }

  /// 删除歌单（本地 soft delete，后台同步服务端）
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, LocalPlaylistInfo playlist) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定删除「${playlist.name}」吗？歌单内歌曲不会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    debugPrint('[MyPlaylists] 删除歌单: localId=${playlist.localId}, name=${playlist.name}');
    await ref.read(playlistRepositoryProvider).delete(playlist.localId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除「${playlist.name}」')),
    );
  }

  /// 新建 / 编辑歌单底部表单弹层
  Future<void> _showPlaylistForm(BuildContext context, WidgetRef ref, {LocalPlaylistInfo? existing}) {
    return showPlaylistFormSheet(context, ref, existing: existing);
  }

  // ── Tab2 收藏的歌单 ──

  Widget _buildFollowedPlaylists(ThemeData theme) {
    final followedAsync = ref.watch(myFollowedPlaylistsProvider);

    return followedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (followed) {
        if (followed.isEmpty) {
          return const _FollowedEmptyState();
        }
        return RefreshIndicator(
          onRefresh: () async {
            // 拉取远端收藏列表并合并到本地（跟随创建者更新：创建者/歌曲数）
            await ref.read(syncServiceProvider).syncNow(forcePull: true);
            ref.invalidate(myFollowedPlaylistsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: followed.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final f = followed[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                // 点击进入只读公开歌单详情（recommend 接口实时读取，跟随创建者更新）
                onTap: () => context.push('/playlist/${f.playlistId}', extra: {
                  'name': f.name,
                  'subtitle': '${f.ownerNickname} · ${f.songCount} 首',
                  'isBackendPlaylist': true,
                  'backendId': f.playlistId,
                  'coverUrl': f.coverUrl,
                }),
                leading: PlaylistCover(coverUrl: f.coverUrl, size: 56),
                title: Row(
                  children: [
                    // 「收藏」角标
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDA4AF)),
                      ),
                      child: const Text('收藏', style: TextStyle(fontSize: 10, color: Color(0xFFF43F5E))),
                    ),
                    Expanded(
                      child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${f.ownerNickname} · ${f.songCount} 首 · ${_formatDate(f.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                // 已收藏红心：点击取消收藏
                trailing: IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Color(0xFFF43F5E)),
                  onPressed: () => _confirmUnfollow(context, ref, f),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 取消收藏（二次确认 + 本地 soft delete，后台同步服务端）
  Future<void> _confirmUnfollow(
      BuildContext context, WidgetRef ref, LocalPlaylistFollowInfo followed) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消收藏'),
        content: Text('确定取消收藏「${followed.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('取消收藏', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(playlistFollowRepositoryProvider).remove(followed.playlistId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已取消收藏「${followed.name}」')),
    );
  }
}

/// 列表行 ⋮ 菜单动作
enum _RowAction { edit, share, delete }

/// 我的歌单空状态
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
            child: const Icon(Icons.music_note_rounded, color: Color(0xFF6366F1), size: 36),
          ),
          const SizedBox(height: 16),
          Text('还没有创建歌单', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('创建歌单，收藏你喜欢的音乐', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onCreate,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  child: Text('创建歌单', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏的歌单空状态
class _FollowedEmptyState extends StatelessWidget {
  const _FollowedEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border_rounded, color: Color(0xFF6366F1), size: 36),
          ),
          const SizedBox(height: 16),
          Text('还没有收藏的歌单', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('在首页看到喜欢的歌单，点「收藏」就会出现在这里', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.go('/home'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  child: Text('去首页逛逛', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
