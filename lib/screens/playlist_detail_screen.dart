import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/mock_data.dart';
import '../services/providers.dart';
import '../widgets/mini_player_bar.dart';
import '../utils/player_utils.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 从 extra 获取歌单数据
    final playlist = GoRouterState.of(context).extra as MockPlaylist?;

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
                    playlist?.name ?? '歌单详情',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 头部区域
            if (playlist != null)
              _buildHeader(theme, playlist, context, ref),

            // 歌曲列表
            Expanded(
              child: playlist != null
                  ? _buildSongList(context, ref, playlist)
                  : _buildEmptyState(context),
            ),

            // 迷你播放栏
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, MockPlaylist playlist, BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C1D95), Color(0xFF5B21B6), Color(0xFF6D28D9), Color(0xFF312E81)],
        ),
      ),
      child: Padding(
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
              'Via Music · 共 ${playlist.songs.length} 首',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
            ),
            if (playlist.songs.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
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
                        audio.setQueue(playlist.songs, startIndex: 0);
                        context.push('/player', extra: playlist.songs[0]);
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(BuildContext context, WidgetRef ref, MockPlaylist playlist) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: playlist.songs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
      itemBuilder: (_, i) {
        final song = playlist.songs[i];
        return ListTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
            ),
          ),
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
          Text('去搜索页面发现音乐吧', style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary)),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () => context.push('/search'),
            child: const Text('去搜索'),
          ),
        ],
      ),
    );
  }

}
