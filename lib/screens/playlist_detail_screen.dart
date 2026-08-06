import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../repositories/playlist_follow_repository.dart';
import '../services/providers.dart';
import '../utils/cover_resolver.dart';
import '../utils/player_utils.dart';
import '../widgets/song_cover.dart';

/// 公开歌单详情页（推荐/分享/收藏歌单共用，走 recommend 接口实时读取）
///
/// 收藏歌单（MP-10）：Hero 操作区"播放全部"旁新增"收藏/已收藏"按钮，订阅引用，跟随创建者更新；
/// 复制到我的歌单（MP-11）：顶栏 ⋮ 菜单，克隆为当前用户的独立副本。
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  /// 无 coverUrl 时按封面来源懒加载解析出的封面 URL
  String? _resolvedCover;
  bool _coverResolved = false;

  /// 封面懒加载（幂等）：已有 coverUrl 或无可解析来源时直接跳过
  Future<void> _ensureCover(String coverUrl, String? coverPicId, String? coverSource) async {
    if (_coverResolved) return;
    _coverResolved = true;
    if (coverUrl.isNotEmpty) return;
    if (coverPicId == null || coverPicId.isEmpty || coverSource == null || coverSource.isEmpty) {
      return;
    }
    final url = await resolveCoverByPic(
      client: ref.read(gdMusicClientProvider),
      picDao: ref.read(picCoverDaoProvider),
      picId: coverPicId,
      source: coverSource,
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _resolvedCover = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从路由 extra 获取歌单元数据（Map 格式）
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final playlistName = extra?['name'] as String? ?? '歌单详情';
    // 后端歌单（推荐/分享）：用 recommend 接口显示真实歌曲与封面
    final isBackend = extra?['isBackendPlaylist'] == true;
    final backendId = (extra?['backendId'] as num?)?.toInt() ?? 0;
    final coverUrl = (extra?['coverUrl'] as String?) ?? '';
    final coverPicId = extra?['coverPicId'] as String?;
    final coverSource = extra?['coverSource'] as String?;
    // 无 coverUrl 时按封面来源懒加载解析（走共享解析器，幂等触发）
    final effectiveCoverUrl = coverUrl.isNotEmpty ? coverUrl : (_resolvedCover ?? '');
    unawaited(_ensureCover(coverUrl, coverPicId, coverSource));

    // 推荐/分享公开歌单：歌曲从本地推荐缓存流式读取（SyncService 后台异步拉取后端刷新）
    final songsAsync = ref.watch(recommendPlaylistSongsProvider(backendId));

    // 已收藏状态：本地收藏歌单集合（订阅引用，登录后 SyncService 同步服务端）
    final followedList = ref.watch(myFollowedPlaylistsProvider).value ??
        const <LocalPlaylistFollowInfo>[];
    final isFollowed = isBackend && followedList.any((f) => f.playlistId == backendId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶栏（左侧返回，中间标题，右侧 ⋮ 更多）
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
                  // 更多菜单：复制到我的歌单（MP-11）
                  SizedBox(
                    width: 46,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert_rounded,
                            color: Color(0xFF8B5CF6), size: 20),
                      ),
                      onSelected: (value) {
                        if (value == 'copy') _onCopyPlaylist(context, ref);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'copy', child: Text('复制到我的歌单')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 头部区域（含收藏按钮）
            _buildHeader(theme, playlistName, songsAsync, context, ref, effectiveCoverUrl,
                isBackend, backendId, isFollowed),

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
                        onPressed: () => ref.invalidate(recommendPlaylistSongsProvider(backendId)),
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
    String playlistName,
    AsyncValue<List<Song>> songsAsync,
    BuildContext context,
    WidgetRef ref,
    String coverUrl,
    bool isBackend,
    int backendId,
    bool isFollowed,
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
                  playlistName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '悦听 · 共 $songCountText',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                ),
                // 仅在加载完成后显示"播放全部 + 收藏"按钮
                songsAsync.when(
                  data: (songs) {
                    if (songs.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          // 播放全部（渐变主按钮）
                          Expanded(
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
                          // 收藏歌单按钮（仅后端公开歌单显示）
                          if (isBackend && backendId > 0) ...[
                            const SizedBox(width: 10),
                            _buildFollowButton(context, ref, backendId, isFollowed),
                          ],
                        ],
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

  /// 收藏歌单按钮（收藏 = 订阅引用，跟随创建者更新）
  Widget _buildFollowButton(
      BuildContext context, WidgetRef ref, int backendId, bool isFollowed) {
    return GestureDetector(
      onTap: () => _onToggleFollow(context, ref, backendId, isFollowed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isFollowed ? const Color(0xFFF43F5E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowed ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isFollowed ? Colors.white : const Color(0xFFF43F5E),
            ),
            const SizedBox(width: 5),
            Text(
              isFollowed ? '已收藏' : '收藏',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isFollowed ? Colors.white : const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 收藏 / 取消收藏（写本地，SyncService 后台同步服务端）
  Future<void> _onToggleFollow(
      BuildContext context, WidgetRef ref, int backendId, bool isFollowed) async {
    if (!ref.read(isLoggedInProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    final repo = ref.read(playlistFollowRepositoryProvider);
    if (isFollowed) {
      await repo.remove(backendId);
      // 取消收藏后立即触发同步（后台 DELETE 清算，不必等 30s 定时）
      ref.read(syncServiceProvider).syncNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消收藏')),
      );
    } else {
      // 收藏时写入歌单名/封面（含封面来源，供收藏列表按 picId 懒加载），创建者信息由同步拉取补全
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final name = extra?['name'] as String? ?? '歌单';
      final coverUrl = (extra?['coverUrl'] as String?) ?? '';
      final coverPicId = extra?['coverPicId'] as String?;
      final coverSource = extra?['coverSource'] as String?;
      await repo.follow(
        playlistId: backendId,
        name: name,
        coverUrl: coverUrl,
        coverPicId: coverPicId,
        coverSource: coverSource,
      );
      // 收藏成功后立即触发同步（后台 POST /playlists/{id}/follow）
      ref.read(syncServiceProvider).syncNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已收藏到 我的歌单 → 收藏的歌单')),
      );
    }
  }

  /// 复制到我的歌单（MP-11）：弹底部表单输入副本名 → 后端克隆 → 本地建行 + 拉歌曲 → 进入副本详情
  Future<void> _onCopyPlaylist(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isLoggedInProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final backendId = ((extra?['backendId'] as num?)?.toInt() ?? 0);
    if (backendId <= 0) return;
    final name = extra?['name'] as String? ?? '歌单';

    // 底部弹窗：输入副本歌单名
    final controller = TextEditingController(text: '$name 的副本');
    final copyName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CopySheet(controller: controller),
      ),
    );
    if (copyName == null || copyName.isEmpty || !context.mounted) return;

    // 调用后端克隆副本
    final client = ref.read(backendClientProvider);
    final copied = await client.copyPlaylist(backendId, name: copyName);
    if (copied == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制失败，请稍后重试')),
      );
      return;
    }

    // 本地建立已同步歌单行并拉取副本歌曲（走本地 SQLite 流式，与自建歌单一致）
    final repo = ref.read(playlistRepositoryProvider);
    final localId = await repo.createSynced(
      remoteId: copied.id,
      name: copied.name,
      description: copied.description,
      coverUrl: copied.coverUrl,
      isPublic: copied.isPublic,
    );
    await repo.pullRemoteSongs(localId, copied.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到我的歌单')),
    );
    // 进入副本详情页（可自由编辑）
    context.push('/my-playlist/$localId');
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

/// 复制到我的歌单底部弹窗（输入副本名 + 取消/复制）
class _CopySheet extends StatelessWidget {
  final TextEditingController controller;
  const _CopySheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部把手
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('复制到我的歌单',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('将复制为你的独立歌单，与源歌单互不影响，可自由编辑',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '歌单名称',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    child: const Text('复制歌单'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
