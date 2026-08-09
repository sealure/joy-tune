// 评论页
// 展示歌曲评论列表，支持发表、回复、点赞

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../api/backend_client.dart';
import '../services/providers.dart';

/// 评论相对时间展示（对齐设计稿：3 分钟前 / 1 小时前）
String _formatCommentTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inSeconds < 60) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 30) return '${diff.inDays} 天前';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

/// 评论页
class CommentsScreen extends ConsumerWidget {
  final Song? song;

  const CommentsScreen({super.key, this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authService = ref.read(authServiceProvider);

    return _CommentsBody(
      song: song,
      theme: theme,
      authService: authService,
    );
  }
}

class _CommentsBody extends ConsumerStatefulWidget {
  final Song? song;
  final ThemeData theme;
  final dynamic authService;

  const _CommentsBody({
    required this.song,
    required this.theme,
    required this.authService,
  });

  @override
  ConsumerState<_CommentsBody> createState() => _CommentsBodyState();
}

class _CommentsBodyState extends ConsumerState<_CommentsBody> {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  List<CommentInfo> _comments = [];
  int _totalComments = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  int? _replyToCommentId; // 回复的评论 ID
  String? _replyToUserName; // 回复的用户名

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _loadComments();
    // 滚动到底部时加载更多
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final hasToken = await widget.authService.isLoggedIn;
    if (mounted) setState(() => _isLoggedIn = hasToken);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadComments(loadMore: true);
      }
    }
  }

  Future<void> _loadComments({bool loadMore = false}) async {
    if (widget.song == null) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final backend = ref.read(backendClientProvider);
    final page = loadMore ? _currentPage + 1 : 1;

    final result = await backend.getComments(
      widget.song!.id,
      page: page,
      size: 20,
    );

    if (mounted) {
      setState(() {
        if (loadMore) {
          _comments.addAll(result.comments);
          _currentPage = page;
        } else {
          _comments = result.comments;
          _currentPage = 1;
        }
        _totalComments = result.total;
        _hasMore = _comments.length < _totalComments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _inputCtrl.text.trim();
    if (content.isEmpty || widget.song == null) return;

    final backend = ref.read(backendClientProvider);
    final comment = await backend.createComment(
      widget.song!.id,
      content,
      parentId: _replyToCommentId,
    );

    if (comment != null && mounted) {
      _inputCtrl.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToUserName = null;
      });
      // 重新加载评论
      _loadComments();
    }
  }

  void _startReply(int commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    _inputCtrl.text = '@$userName ';
    _inputCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputCtrl.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
    _inputCtrl.clear();
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
                '$_totalComments 条评论',
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
    // 加载中且无数据
    if (_isLoading && _comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 空评论
    if (_comments.isEmpty) {
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

    // 评论列表
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index == _comments.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final comment = _comments[index];
        return _CommentTile(
          theme: theme,
          commentInfo: comment,
          currentUserId: _isLoggedIn ? ref.watch(currentUserProvider).value?.id : null,
          onReply: _isLoggedIn ? () => _startReply(comment.id, comment.userName ?? '匿名') : null,
          onLike: _isLoggedIn ? () => _handleLikeComment(comment) : null,
          onDelete: _isLoggedIn && comment.userId == ref.watch(currentUserProvider).value?.id
              ? () => _handleDeleteComment(comment)
              : null,
          onDeleteReply: _isLoggedIn ? _handleDeleteComment : null,
        );
      },
    );
  }

  Future<void> _handleLikeComment(CommentInfo comment) async {
    final backend = ref.read(backendClientProvider);
    if (comment.isLiked) {
      await backend.unlikeComment(comment.id);
    } else {
      await backend.likeComment(comment.id);
    }
    // 刷新评论列表
    _loadComments();
  }

  /// 删除自己的评论（后端级联删除其子回复），确认后刷新列表
  Future<void> _handleDeleteComment(CommentInfo comment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final backend = ref.read(backendClientProvider);
    final success = await backend.deleteComment(comment.id);
    if (!mounted) return;
    if (success) {
      // 刷新评论列表（退回第 1 页，避免分页状态错乱）
      _loadComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请稍后重试')),
      );
    }
  }

  Widget _buildInputBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 回复提示
          if (_replyToUserName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('回复 @_replyToUserName', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),

          // 输入框
          _isLoggedIn
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: InputDecoration(
                          hintText: _replyToUserName != null ? '回复 $_replyToUserName...' : '发表评论...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                      onPressed: _submitComment,
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
        ],
      ),
    );
  }
}

// ── 单条评论组件 ──

class _CommentTile extends StatelessWidget {
  final ThemeData theme;
  final CommentInfo commentInfo;
  /// 当前登录用户 ID（用于判断是否自己的评论，可删除）
  final int? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  /// 删除当前评论（顶级评论）
  final VoidCallback? onDelete;
  /// 删除子回复（传入被删除的回复）
  final void Function(CommentInfo reply)? onDeleteReply;

  const _CommentTile({
    required this.theme,
    required this.commentInfo,
    this.currentUserId,
    this.onReply,
    this.onLike,
    this.onDelete,
    this.onDeleteReply,
  });

  /// 判断回复是否是当前用户本人发表的（仅本人可删自己的回复）
  bool _isOwnMe(CommentInfo reply) {
    final me = currentUserId;
    return reply.userId != 0 && me != null && reply.userId == me;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行（头像 + 用户名 + 时间）
          Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: commentInfo.userAvatar != null
                    ? NetworkImage(commentInfo.userAvatar!)
                    : null,
                child: commentInfo.userAvatar == null
                    ? Icon(Icons.person, size: 18, color: theme.colorScheme.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              // 用户名
              Expanded(
                child: Text(
                  commentInfo.userName ?? '匿名用户',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              // 时间
              if (commentInfo.createdAt != null)
                Text(
                  _formatCommentTime(commentInfo.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 评论内容
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(commentInfo.content, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 8),
          // 操作行
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Row(
              children: [
                // 点赞
                if (onLike != null)
                  GestureDetector(
                    onTap: onLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          commentInfo.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 16,
                          color: commentInfo.isLiked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                        if (commentInfo.likeCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${commentInfo.likeCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
                // 回复
                if (onReply != null)
                  GestureDetector(
                    onTap: onReply,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply_rounded, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text('回复', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                // 删除（仅自己的评论）
                if (onDelete != null) ...[
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onDelete,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text('删除', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 子回复
          if (commentInfo.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                children: commentInfo.replies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        backgroundImage: reply.userAvatar != null
                            ? NetworkImage(reply.userAvatar!)
                            : null,
                        child: reply.userAvatar == null
                            ? Icon(Icons.person, size: 14, color: theme.colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text: '${reply.userName ?? '匿名'}: ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: reply.content),
                            ],
                          ),
                        ),
                      ),
                      // 删除自己的回复
                      if (onDeleteReply != null && _isOwnMe(reply))
                        GestureDetector(
                          onTap: () => onDeleteReply!(reply),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.close, size: 14, color: theme.colorScheme.secondary),
                          ),
                        ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
