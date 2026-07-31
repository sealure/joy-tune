// 我的歌单详情页
// 展示用户自建歌单的歌曲列表，支持播放全部/添加歌曲/移除歌曲/编辑信息/分享
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
class MyPlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  const MyPlaylistDetailScreen({super.key, required this.playlistId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(myPlaylistDetailProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text('歌单详情'),
        actions: detailAsync.maybeWhen(
          data: (detail) => detail == null
              ? null
              : [
                  // 分享
                  IconButton(
                    tooltip: '分享歌单',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => showPlaylistShareSheet(context, ref, detail.playlist),
                  ),
                  // 编辑
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
                onPressed: () => ref.invalidate(myPlaylistDetailProvider(playlistId)),
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
          final songs = detail.songs.map(_toSong).toList();

          return Column(
            children: [
              // 渐变 Hero
              _buildHero(theme, playlist),
              // 操作区
              _buildActions(context, ref, playlist, songs),
              // 歌曲列表
              Expanded(child: _buildSongList(context, ref, songs)),
            ],
          );
        },
      ),
    );
  }

  /// 渐变 Hero 头部
  Widget _buildHero(ThemeData theme, UserPlaylist playlist) {
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
          // 封面占位
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
          // 信息
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
                  '${playlist.songCount} 首 · ${_formatDate(playlist.createdAt)}'
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
  Widget _buildActions(BuildContext context, WidgetRef ref, UserPlaylist playlist, List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          // 播放全部
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
                  onTap: songs.isEmpty
                      ? null
                      : () {
                          final audio = ref.read(audioServiceProvider);
                          audio.stop();
                          audio.setQueue(songs, startIndex: 0);
                          context.push('/player', extra: songs[0]);
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
          // 添加歌曲
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('可在播放页点击 ⋮ 将当前歌曲加入本歌单')),
              );
            },
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

  /// 歌曲列表
  Widget _buildSongList(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) {
      return const Center(child: Text('歌单暂无歌曲'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) => _SongRow(
        index: i + 1,
        song: songs[i],
        onTap: () => playSong(context, ref, songs[i]),
        onRemove: () async {
          final ok = await ref
              .read(backendClientProvider)
              .removeSongFromPlaylist(playlistId, songs[i].id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? '已从歌单移除' : '移除失败')),
          );
          if (ok) {
            ref.invalidate(myPlaylistDetailProvider(playlistId));
            ref.invalidate(myPlaylistsProvider);
          }
        },
      ),
    );
  }
}

/// 歌曲行：序号 + 封面 + 歌名/歌手 + 收藏 + ⋮
class _SongRow extends ConsumerStatefulWidget {
  final int index;
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SongRow({
    required this.index,
    required this.song,
    required this.onTap,
    required this.onRemove,
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

  /// 查询当前歌曲是否已收藏
  Future<void> _checkFavorite() async {
    final repo = ref.read(favoriteRepositoryProvider);
    final liked = await repo.isFavorited(widget.song.id);
    if (mounted) setState(() => _favorited = liked);
  }

  /// 切换收藏
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
          SizedBox(
            width: 24,
            child: Text('${widget.index}',
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
          // 收藏按钮
          IconButton(
            icon: Icon(
              _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _favorited ? Colors.red : Colors.grey,
              size: 20,
            ),
            onPressed: _toggleFavorite,
          ),
          // ⋮ 菜单：下一首播放 / 从歌单移除 / 调整排序
          PopupMenuButton<_SongAction>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
            onSelected: (action) => _onAction(action),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _SongAction.playNext, child: Text('下一首播放')),
              PopupMenuItem(
                value: _SongAction.remove,
                child: Text('从歌单移除', style: TextStyle(color: Colors.red)),
              ),
              PopupMenuItem(value: _SongAction.sort, child: Text('调整排序')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('排序功能暂未支持，敬请期待')),
        );
        break;
    }
  }
}

enum _SongAction { playNext, remove, sort }
