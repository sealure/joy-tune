import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../utils/player_utils.dart';
import '../widgets/song_cover.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 从路由 extra 获取歌单元数据（Map 格式）
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final playlistName = extra?['name'] as String? ?? '歌单详情';
    final playlistSubtitle = extra?['subtitle'] as String?;
    // 后端歌单（推荐/分享）：用 recommend 接口显示真实歌曲与封面
    final isBackend = extra?['isBackendPlaylist'] == true;
    final backendId = (extra?['backendId'] as num?)?.toInt() ?? 0;
    final coverUrl = (extra?['coverUrl'] as String?) ?? '';

    // 根据 playlistId 找到对应的 MockPlaylist
    final playlist = recommendedPlaylists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => MockPlaylist(
        id: playlistId,
        name: playlistName,
        subtitle: playlistSubtitle ?? '',
      ),
    );

    // 后端歌单：recommend 详情接口返回真实歌曲；否则按歌单名动态搜索
    final AsyncValue<List<Song>> songsAsync;
    if (isBackend && backendId > 0) {
      songsAsync = ref.watch(recommendPlaylistSongsProvider(backendId));
    } else {
      songsAsync = ref.watch(playlistSongsProvider(playlistId));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶栏
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    playlistName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 头部区域
            _buildHeader(theme, playlist, songsAsync, context, ref, coverUrl),

            // 歌曲列表（支持加载中/错误状态）
            Expanded(
              child: songsAsync.when(
                data: (songs) => songs.isEmpty
                    ? _buildEmptyState(context)
                    : _buildSongList(context, ref, songs),
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在加载歌曲...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white38),
                      const SizedBox(height: 12),
                      Text('加载失败: $error', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.invalidate(playlistSongsProvider(playlistId)),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 迷你播放栏由 _MainShell 统一提供
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    MockPlaylist playlist,
    AsyncValue<List<Song>> songsAsync,
    BuildContext context,
    WidgetRef ref,
    String coverUrl,
  ) {
    // 歌曲数量：加载中显示占位，加载完成显示实际数量
    final songCountText = songsAsync.when(
      data: (songs) => '${songs.length} 首',
      loading: () => '加载中...',
      error: (_, __) => '加载失败',
    );

    // 有封面时作为头部背景图，否则用渐变背景
    final hasCover = coverUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: hasCover
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF6D28D9), Color(0xFF312E81)],
              ),
        image: hasCover
            ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover)
            : null,
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
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '悦听 · 共 $songCountText',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                ),
                // 仅在加载完成后显示"播放全部"按钮
                songsAsync.when(
                  data: (songs) {
                    if (songs.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                final audio = ref.read(audioServiceProvider);
                                audio.stop();
                                audio.setQueue(songs, startIndex: 0);
                                context.push('/player', extra: songs[0]);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Color(0xFF6366F1), size: 22),
                                    SizedBox(width: 6),
                                    Text('播放全部', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildSongList(BuildContext context, WidgetRef ref, List<Song> songs) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
      itemBuilder: (_, i) {
        final song = songs[i];
        return ListTile(
          leading: SongCover(song: song, size: 44, borderRadius: 8),
          title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: Icon(Icons.play_circle_outline_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () => playSong(context, ref, song),
          ),
          onTap: () => playSong(context, ref, song),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music_outlined, size: 48, color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text('歌单暂无歌曲', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('请稍后再试', style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary)),
        ],
      ),
    );
  }
}
