// 我的歌单详情页
// 展示用户自建歌单的歌曲列表，支持播放全部/添加歌曲/移除歌曲/编辑信息/分享/拖拽排序
// 对应设计稿 ui/my-playlist-detail/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/backend_client.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../utils/player_utils.dart';
import '../utils/playlist_share.dart';
import '../widgets/playlist_form_sheet.dart';
import '../widgets/song_cover.dart';

/// 我的歌单详情页
class MyPlaylistDetailScreen extends ConsumerStatefulWidget {
  final int playlistId;
  const MyPlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<MyPlaylistDetailScreen> createState() => _MyPlaylistDetailScreenState();
}

class _MyPlaylistDetailScreenState extends ConsumerState<MyPlaylistDetailScreen> {
  /// 是否处于排序模式
  bool _sorting = false;

  /// 排序模式下的本地歌曲顺序（未排序时为 null，直接用后端数据）
  List<PlaylistSongInfo>? _localSongs;

  /// 后端歌曲信息 → 前端 Song 模型
  Song _toSong(PlaylistSongInfo s) => Song(
        id: s.songId,
        name: s.songName,
        artist: s.artist,
        album: s.album,
        source: s.source,
        coverUrl: s.coverUrl.isNotEmpty ? s.coverUrl : null,
      );

  /// 格式化创建日期
  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d 创建';
  }

  /// 进入排序模式
  void _enterSort(List<PlaylistSongInfo> songs) {
    setState(() {
      _sorting = true;
      _localSongs = List.of(songs);
    });
  }

  /// 排序完成：提交新顺序到后端
  Future<void> _finishSort() async {
    final songs = _localSongs;
    if (songs == null) return;
    final ok = await ref
        .read(backendClientProvider)
        .reorderPlaylistSongs(widget.playlistId, songs.map((s) => s.id).toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已保存排序' : '保存排序失败，请重试')),
    );
    if (ok) ref.invalidate(myPlaylistDetailProvider(widget.playlistId));
    setState(() {
      _sorting = false;
      _localSongs = null;
    });
  }

  /// 从歌单移除歌曲，返回是否成功
  Future<bool> _removeSong(PlaylistSongInfo s) async {
    final ok = await ref
        .read(backendClientProvider)
        .removeSongFromPlaylist(widget.playlistId, s.songId);
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已从歌单移除' : '移除失败，请重试')),
    );
    if (ok) {
      ref.invalidate(myPlaylistDetailProvider(widget.playlistId));
      ref.invalidate(myPlaylistsProvider);
    }
    return ok;
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
    final detailAsync = ref.watch(myPlaylistDetailProvider(widget.playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text('歌单详情'),
        actions: detailAsync.maybeWhen(
          data: (detail) => detail == null
              ? null
              : _sorting
                  ? [
                      // 排序模式：完成按钮
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          onPressed: _finishSort,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('完成'),
                        ),
                      ),
                    ]
                  : [
                      IconButton(
                        tooltip: '分享歌单',
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => showPlaylistShareSheet(context, ref, detail.playlist),
                      ),
                      TextButton.icon(
                        onPressed: () => showPlaylistFormSheet(context, ref, existing: detail.playlist),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('编辑'),
                      ),
                    ],
          orElse: () => null,
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $e'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(myPlaylistDetailProvider(widget.playlistId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('歌单不存在或无权访问'));
          }
          final playlist = detail.playlist;
          // 排序模式下使用本地顺序，否则用后端数据
          final songs = _sorting ? _localSongs ?? [] : detail.songs;

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
              _buildActions(context, detail, songs),
              // 歌曲列表
              Expanded(child: _buildSongList(context, songs)),
            ],
          );
        },
      ),
    );
  }

  /// 渐变 Hero 头部
  Widget _buildHero(ThemeData theme, UserPlaylist playlist, int songCount) {
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
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
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
  Widget _buildActions(BuildContext context, UserPlaylistDetail detail, List<PlaylistSongInfo> songs) {
    final songModels = songs.map(_toSong).toList();
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
  Widget _buildSongList(BuildContext context, List<PlaylistSongInfo> songs) {
    if (songs.isEmpty) {
      return const Center(child: Text('歌单暂无歌曲'));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemCount: songs.length,
      itemBuilder: (_, i) {
        final info = songs[i];
        final song = _toSong(info);
        return Dismissible(
          key: ValueKey('song-${info.id}'),
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
            onFinishSort: _finishSort,
            dragHandle: _sorting
                ? ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 20),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// 歌曲行：序号/拖拽手柄 + 封面 + 歌名/歌手 + 收藏 + ⋮
class _SongRow extends ConsumerStatefulWidget {
  final int index;
  final Song song;
  final bool sorting;
  final VoidCallback? onTap;
  final VoidCallback onRemove;
  final VoidCallback onSortMode;
  final VoidCallback? onFinishSort;
  final Widget? dragHandle;

  const _SongRow({
    required this.index,
    required this.song,
    required this.sorting,
    this.onTap,
    required this.onRemove,
    required this.onSortMode,
    this.onFinishSort,
    this.dragHandle,
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
    ref.invalidate(favoritesProvider);
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
          if (widget.dragHandle != null)
            widget.dragHandle!
          else
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _favorited ? Colors.red : Colors.grey,
              size: 20,
            ),
            onPressed: widget.sorting ? null : _toggleFavorite,
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
              if (widget.sorting)
                const PopupMenuItem(value: _SongAction.done, child: Text('完成排序'))
              else
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
      case _SongAction.done:
        widget.onFinishSort?.call();
        break;
    }
  }
}

enum _SongAction { playNext, remove, sort, done }
