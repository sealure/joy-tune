import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/mini_player_bar.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text('歌单详情', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 头部区域
            _buildHeader(theme),

            // 歌曲列表
            Expanded(child: _buildSongList(context, theme)),

            // 迷你播放栏
            const MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('歌单 #$playlistId', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Via Music · 共 0 首', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
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
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF059669), size: 22),
                          SizedBox(width: 6),
                          Text('播放全部', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(BuildContext context, ThemeData theme) {
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
