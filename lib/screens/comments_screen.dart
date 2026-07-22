import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 评论页
class CommentsScreen extends ConsumerWidget {
  final Song? song;

  const CommentsScreen({super.key, this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 从 AuthService 获取真实登录状态
    final authService = ref.read(authServiceProvider);

    return _CommentsBody(
      song: song,
      theme: theme,
      authService: authService,
    );
  }
}

class _CommentsBody extends StatefulWidget {
  final Song? song;
  final ThemeData theme;
  final dynamic authService;

  const _CommentsBody({
    required this.song,
    required this.theme,
    required this.authService,
  });

  @override
  State<_CommentsBody> createState() => _CommentsBodyState();
}

class _CommentsBodyState extends State<_CommentsBody> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final hasToken = await widget.authService.isLoggedIn;
    if (mounted) setState(() => _isLoggedIn = hasToken);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

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
          if (widget.song != null)
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
                        Text(widget.song!.name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(widget.song!.artist, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 评论区
          Expanded(child: _buildCommentList(context, theme)),

          // 输入区
          _buildInputBar(context, theme),
        ],
      ),
    );
  }

  Widget _buildCommentList(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text('暂无评论，快来抢沙发吧', style: theme.textTheme.bodySmall),
          if (!_isLoggedIn) ...[
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

  Widget _buildInputBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: _isLoggedIn
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
