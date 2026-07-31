// 选择歌单弹层
// 可复用组件：把当前歌曲加入用户自建歌单（AddSongToPlaylist）
// 入口：播放页 ⋮ 更多菜单「加入歌单」；后续搜索页/歌单详情复用
// 对应设计稿 ui/playlist-picker/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/backend_client.dart';
import '../models/song.dart';
import '../services/providers.dart';
import 'playlist_cover.dart';
import 'playlist_form_sheet.dart';

/// 弹出"选择歌单"底部弹层，把 song 加入选中的歌单
Future<void> showPlaylistPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required Song song,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PlaylistPickerSheet(song: song),
  );
}

/// 选择歌单弹层内容
class PlaylistPickerSheet extends ConsumerStatefulWidget {
  final Song song;
  const PlaylistPickerSheet({super.key, required this.song});

  @override
  ConsumerState<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends ConsumerState<PlaylistPickerSheet> {
  /// 已加入的歌单 id 集合
  final Set<int> _added = {};
  String _keyword = '';

  /// 加入歌单（幂等：已加入的跳过）
  Future<void> _addToPlaylist(UserPlaylist p) async {
    if (_added.contains(p.id)) return;
    debugPrint('[PlaylistPicker] 加入歌单: playlist=${p.id}, song=${widget.song.id}');
    final ok = await ref.read(backendClientProvider).addSongToPlaylist(
          p.id,
          songId: widget.song.id,
          songName: widget.song.name,
          artist: widget.song.artist,
          album: widget.song.album.isNotEmpty ? widget.song.album : null,
          coverUrl: widget.song.coverUrl,
          source: widget.song.source,
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _added.add(p.id));
      ref.invalidate(myPlaylistsProvider);
      ref.invalidate(myPlaylistDetailProvider(p.id));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('已加入「${p.name}」'), duration: const Duration(seconds: 2)),
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加入失败，请重试')),
      );
    }
  }

  /// 新建歌单：创建成功后刷新列表
  Future<void> _createPlaylist() async {
    await showPlaylistFormSheet(context, ref);
    ref.invalidate(myPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Text('选择歌单', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('选择要加入的歌单', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),

            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _keyword = v.trim()),
                decoration: InputDecoration(
                  hintText: '搜索歌单',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // 歌单列表
            playlistsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: Text('加载失败: $e'),
              ),
              data: (playlists) {
                final filtered = _keyword.isEmpty
                    ? playlists
                    : playlists.where((p) => p.name.contains(_keyword)).toList();
                return Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('暂无歌单', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final added = _added.contains(p.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _addToPlaylist(p),
                              leading: PlaylistCover(
                                coverUrl: p.coverUrl,
                                size: 44,
                                borderRadius: 10,
                              ),
                              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${p.songCount} 首'),
                              trailing: added
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                          SizedBox(width: 3),
                                          Text('已加入', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 18),
                                    ),
                            );
                          },
                        ),
                );
              },
            ),

            // 新建歌单入口
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: InkWell(
                onTap: _createPlaylist,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1), size: 20),
                      SizedBox(width: 12),
                      Text('新建歌单', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6366F1))),
                    ],
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
