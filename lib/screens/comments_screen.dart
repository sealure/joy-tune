import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';

/// 评论页
class CommentsScreen extends StatelessWidget {
  final Song? song;

  const CommentsScreen({super.key, this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = false; // TODO: 接入认证后替换

    return Scaffold(
      appBar: AppBar(
        title: const Text('评论'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '0 条评论',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 歌曲信息小横条
          if (song != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song!.name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(song!.artist, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 评论区
          Expanded(child: _buildCommentList(context, theme, isLoggedIn)),

          // 输入区
          _buildInputBar(context, theme, isLoggedIn),
        ],
      ),
    );
  }

  Widget _buildCommentList(BuildContext context, ThemeData theme, bool isLoggedIn) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text('暂无评论，快来抢沙发吧', style: theme.textTheme.bodySmall),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.push('/login'),
              child: const Text('登录后参与评论'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ThemeData theme, bool isLoggedIn) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: isLoggedIn
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '发表评论...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                  onPressed: () {},
                ),
              ],
            )
          : GestureDetector(
              onTap: () => context.push('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    '登录后参与评论',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.secondary),
                  ),
                ),
              ),
            ),
    );
  }
}
