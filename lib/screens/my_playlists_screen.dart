// 我的歌单列表页
// 展示本地 SQLite 歌单（登录后 SyncService 同步到服务端），支持新建/编辑/删除/分享
// 对应设计稿 ui/my-playlists/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../repositories/playlist_repository.dart';
import '../services/providers.dart';
import '../utils/playlist_share.dart';
import '../widgets/playlist_form_sheet.dart';
import '../widgets/playlist_cover.dart';

/// 我的歌单列表页
class MyPlaylistsScreen extends ConsumerWidget {
  const MyPlaylistsScreen({super.key});

  /// 格式化创建日期
  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d 创建';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的歌单'),
        actions: [
          // 新建歌单按钮（渐变胶囊）
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
      ),
      body: playlistsAsync.when(
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
      ),
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
}

/// 列表行 ⋮ 菜单动作
enum _RowAction { edit, share, delete }

/// 空状态
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
