// 歌单表单底部弹层（新建 / 编辑共用）
// 我的歌单列表页与详情页复用；支持从歌单现有歌曲中选择封面
// 本地 SQLite 优先：创建/编辑写本地（is_synced=0），由 SyncService 同步服务端

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/playlist_repository.dart';
import '../services/providers.dart';
import 'playlist_cover.dart';
import 'song_cover.dart';

/// 弹出新建/编辑歌单底部表单
/// [songs] 为当前歌单的歌曲列表（编辑时传入，用于"从歌曲选择封面"）
Future<void> showPlaylistFormSheet(
  BuildContext context,
  WidgetRef ref, {
  LocalPlaylistInfo? existing,
  List<LocalPlaylistSongInfo>? songs,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PlaylistFormSheet(existing: existing, songs: songs),
  );
}

/// 新建 / 编辑歌单底部表单
class PlaylistFormSheet extends ConsumerStatefulWidget {
  final LocalPlaylistInfo? existing;
  final List<LocalPlaylistSongInfo>? songs;
  const PlaylistFormSheet({super.key, this.existing, this.songs});

  @override
  ConsumerState<PlaylistFormSheet> createState() => _PlaylistFormSheetState();
}

class _PlaylistFormSheetState extends ConsumerState<PlaylistFormSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.existing?.description ?? '');
  late bool _isPublic = widget.existing?.isPublic ?? true;
  late String _coverUrl = widget.existing?.coverUrl ?? '';
  /// 封面来源歌曲 pic_id（选中歌曲封面时落库，展示走懒加载）
  late String? _coverPicId = widget.existing?.coverPicId;
  late String? _coverSource = widget.existing?.coverSource;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// 从歌单现有歌曲中选择封面
  Future<void> _pickCoverFromSongs() async {
    final songs = widget.songs;
    if (songs == null || songs.isEmpty) return;
    final selected = await showModalBottomSheet<LocalPlaylistSongInfo>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('选择封面歌曲', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: songs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (_, i) {
                  final s = songs[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(ctx, s),
                    leading: SongCover(
                      song: s.toSong(),
                      size: 44,
                      borderRadius: 8,
                    ),
                    title: Text(s.songName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      // 封面来源 = 选中歌曲的 pic_id + source（本地歌曲 coverUrl 通常为空，靠 picId 懒加载）
      setState(() {
        _coverUrl = selected.coverUrl ?? '';
        _coverPicId = selected.picId;
        _coverSource = selected.source;
      });
    }
  }

  /// 创建 / 更新歌单（本地写，后台同步）
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入歌单名称')));
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    final repo = ref.read(playlistRepositoryProvider);
    final desc = _descCtrl.text.trim().isEmpty ? '' : _descCtrl.text.trim();
    debugPrint('[PlaylistForm] ${widget.existing == null ? "创建" : "更新"}歌单: name=$name, isPublic=$_isPublic');
    if (widget.existing == null) {
      await repo.create(
        name: name,
        description: desc,
        coverUrl: _coverUrl,
        coverPicId: _coverPicId,
        coverSource: _coverSource,
        isPublic: _isPublic,
      );
    } else {
      await repo.update(
        widget.existing!.localId,
        name: name,
        description: desc,
        coverUrl: _coverUrl,
        coverPicId: _coverPicId,
        coverSource: _coverSource,
        isPublic: _isPublic,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
    // 本地写即时生效，刷新列表与详情（编辑时）
    ref.invalidate(myPlaylistsProvider);
    if (widget.existing != null) {
      ref.invalidate(myPlaylistProvider(widget.existing!.localId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Center(
                child: Text(widget.existing == null ? '新建歌单' : '编辑歌单',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              // 封面区：预览 + 从歌单歌曲中选择
              Row(
                children: [
                  PlaylistCover(
                    coverUrl: _coverUrl,
                    coverPicId: _coverPicId,
                    coverSource: _coverSource,
                    size: 64,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('歌单封面', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        if (widget.songs != null && widget.songs!.isNotEmpty)
                          TextButton.icon(
                            onPressed: _pickCoverFromSongs,
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('从歌单歌曲中选择'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          Text('添加歌曲后可从歌曲中选择封面',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: '歌单名称（必填）',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  hintText: '歌单描述（选填）',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                activeTrackColor: const Color(0xFF6366F1),
                title: const Text('公开歌单'),
                subtitle: const Text('公开后其他用户可查看'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _submit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            alignment: Alignment.center,
                            child: Text(_submitting ? '保存中...' : '保存',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
