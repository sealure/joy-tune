// 我的歌单详情页
// 展示本地 SQLite 歌单的歌曲列表，支持播放全部/添加歌曲/移除歌曲/编辑信息/分享/拖拽排序
// 本地优先：增删改先写本地（is_synced=0），SyncService 后台同步服务端
// 对应设计稿 ui/my-playlist-detail/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../repositories/playlist_repository.dart';
import '../services/providers.dart';
import '../utils/player_utils.dart';
import '../utils/playlist_share.dart';
import '../widgets/playlist_form_sheet.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/song_cover.dart';

/// 我的歌单详情页（playlistId 为本地歌单 UUID）
class MyPlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  const MyPlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<MyPlaylistDetailScreen> createState() => _MyPlaylistDetailScreenState();
}

class _MyPlaylistDetailScreenState extends ConsumerState<MyPlaylistDetailScreen> {
  /// 是否处于排序模式
  bool _sorting = false;

  /// 排序模式下的本地歌曲顺序（未排序时为 null）
  List<LocalPlaylistSongInfo>? _localSongs;

  /// 格式化创建日期
  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d 创建';
  }

  /// 进入排序模式
  void _enterSort(List<LocalPlaylistSongInfo> songs) {
    setState(() {
      _sorting = true;
      _localSongs = List.of(songs);
    });
  }

  /// 排序完成：提交新顺序到本地（后台同步）
  Future<void> _finishSort() async {
    final songs = _localSongs;
    if (songs == null) return;
    debugPrint('[MyPlaylistDetail] 提交排序: playlist=${widget.playlistId}, songs=${songs.map((s) => s.songId).toList()}');
    await ref
        .read(playlistRepositoryProvider)
        .reorder(widget.playlistId, songs.map((s) => s.songId).toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存排序')),
    );
    setState(() {
      _sorting = false;
      _localSongs = null;
    });
  }

  /// 从歌单移除歌曲（本地 soft delete，后台同步）
  Future<bool> _removeSong(LocalPlaylistSongInfo s) async {
    debugPrint('[MyPlaylistDetail] 移除歌曲: playlist=${widget.playlistId}, song=${s.songId}');
    await ref
        .read(playlistRepositoryProvider)
        .removeSong(widget.playlistId, s.songId, s.source);
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已从歌单移除')),
    );
    return true;
  }

  /// 拖拽排序回调（仅排序模式生效）
  void _onReorder(int oldIndex, int newIndex) {
    if (!_sorting || _localSongs == null) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _localSongs!.removeAt(oldIndex);
      _localSongs!.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistAsync = ref.watch(myPlaylistProvider(widget.playlistId));
    final songsAsync = ref.watch(myPlaylistSongsProvider(widget.playlistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌单详情'),
        actions: [
          if (_sorting)
            // 排序模式：完成按钮
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _finishSort,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('完成'),
              ),
            )
          else ...[
            IconButton(
              tooltip: '调整排序',
              icon: const Icon(Icons.swap_vert_rounded),
              onPressed: () {
                final songs = _localSongs ?? const <LocalPlaylistSongInfo>[];
                if (songs.isNotEmpty) _enterSort(songs);
              },
            ),
            IconButton(
              tooltip: '分享歌单',
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final playlist = playlistAsync.valueOrNull;
                if (playlist == null) return;
                if (!playlist.synced) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('歌单同步到账号后即可分享')),
                  );
                  return;
                }
                showPlaylistShareSheet(context, ref, playlist);
              },
            ),
            TextButton.icon(
              onPressed: () {
                final playlist = playlistAsync.valueOrNull;
                if (playlist == null) return;
                showPlaylistFormSheet(
                  context,
                  ref,
                  existing: playlist,
                  songs: songsAsync.valueOrNull ?? const [],
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('编辑'),
            ),
          ],
        ],
      ),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (playlist) {
          if (playlist == null) {
            return const Center(child: Text('歌单不存在或已删除'));
          }
          final songs = _sorting ? _localSongs ?? const <LocalPlaylistSongInfo>[] : (songsAsync.valueOrNull ?? const <LocalPlaylistSongInfo>[]);

          return Column(
            children: [
              // 排序模式提示条
              if (_sorting)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '拖动歌曲调整顺序，点击「完成」保存',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6366F1)),
                  ),
                ),
              // 渐变 Hero
              _buildHero(theme, playlist, songs.length),
              // 操作区
              _buildActions(context, playlist, songs),
              // 歌曲列表
              Expanded(child: _buildSongList(context, songs)),
            ],
          );
        },
      ),
    );
  }

  /// 渐变 Hero 头部
  Widget _buildHero(ThemeData theme, LocalPlaylistInfo playlist, int songCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA5B4FC), Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF4F46E5)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: PlaylistCover(
              coverUrl: playlist.coverUrl,
              coverPicId: playlist.coverPicId,
              coverSource: playlist.coverSource,
              size: 96,
              borderRadius: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '$songCount 首 · ${_formatDate(playlist.createdAt)}'
                  '${playlist.isPublic ? ' · 公开' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 操作区：播放全部 + 添加歌曲
  Widget _buildActions(BuildContext context, LocalPlaylistInfo playlist, List<LocalPlaylistSongInfo> songs) {
    final songModels = songs.map((s) => s.toSong()).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: songModels.isEmpty
                      ? null
                      : () {
                          final audio = ref.read(audioServiceProvider);
                          audio.stop();
                          audio.setQueue(songModels, startIndex: 0);
                          context.push('/player', extra: songModels[0]);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text('播放全部', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _sorting
                ? null
                : () => context.push('/search', extra: {'playlistId': widget.playlistId}),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              backgroundColor: const Color(0xFFEEF2FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('添加歌曲', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  /// 歌曲列表（ReorderableListView 支持拖拽排序 + Dismissible 左滑移除）
  Widget _buildSongList(BuildContext context, List<LocalPlaylistSongInfo> songs) {
    if (songs.isEmpty) {
      return const Center(child: Text('歌单暂无歌曲'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // 排序模式下启用默认拖拽手柄（右侧长按拖动），确保可拖
      buildDefaultDragHandles: _sorting,
      onReorder: _onReorder,
      itemCount: songs.length,
      itemBuilder: (_, i) {
        final info = songs[i];
        final song = info.toSong();
        return Dismissible(
          key: ValueKey('song-${info.rowId}'),
          // 排序模式下禁用左滑
          direction: _sorting ? DismissDirection.none : DismissDirection.endToStart,
          confirmDismiss: (_) => _removeSong(info),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          child: _SongRow(
            index: i,
            song: song,
            sorting: _sorting,
            onTap: _sorting ? null : () => playSong(context, ref, song),
            onRemove: () => _removeSong(info),
            onSortMode: () => _enterSort(songs),
          ),
        );
      },
    );
  }
}

/// 歌曲行：序号 + 封面 + 歌名/歌手 + 收藏 + ⋮（排序模式由默认拖拽手柄接管右侧）
class _SongRow extends ConsumerStatefulWidget {
  final int index;
  final Song song;
  final bool sorting;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final VoidCallback onSortMode;

  const _SongRow({
    required this.index,
    required this.song,
    required this.sorting,
    this.onTap,
    required this.onRemove,
    required this.onSortMode,
  });

  @override
  ConsumerState<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends ConsumerState<_SongRow> {
  bool _favorited = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final repo = ref.read(favoriteRepositoryProvider);
    final liked = await repo.isFavorited(widget.song.id);
    if (mounted) setState(() => _favorited = liked);
  }

  Future<void> _toggleFavorite() async {
    final repo = ref.read(favoriteRepositoryProvider);
    if (_favorited) {
      await repo.remove(widget.song.id);
    } else {
      await repo.add(widget.song);
    }
    if (mounted) setState(() => _favorited = !_favorited);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: widget.onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text('${widget.index + 1}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
          const SizedBox(width: 6),
          SongCover(song: widget.song, size: 42, borderRadius: 8),
        ],
      ),
      title: Text(widget.song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(widget.song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      // 排序模式下右侧交给默认拖拽手柄，隐藏收藏/⋮
      trailing: widget.sorting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _favorited ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: _toggleFavorite,
                ),
                PopupMenuButton<_SongAction>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                  onSelected: (action) => _onAction(action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: _SongAction.playNext, child: Text('下一首播放')),
                    const PopupMenuItem(
                      value: _SongAction.remove,
                      child: Text('从歌单移除', style: TextStyle(color: Colors.red)),
                    ),
                    const PopupMenuItem(value: _SongAction.sort, child: Text('调整排序')),
                  ],
                ),
              ],
            ),
    );
  }

  void _onAction(_SongAction action) {
    switch (action) {
      case _SongAction.playNext:
        final audio = ref.read(audioServiceProvider);
        audio.insertNext(widget.song);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入下一首播放'), duration: Duration(seconds: 1)),
        );
        break;
      case _SongAction.remove:
        widget.onRemove();
        break;
      case _SongAction.sort:
        widget.onSortMode();
        break;
    }
  }
}

enum _SongAction { playNext, remove, sort }
