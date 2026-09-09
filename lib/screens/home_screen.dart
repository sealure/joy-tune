// 首页
// 「今日推荐」大卡片（cron 生成的系统热门歌单）+「推荐歌单」轮播（被收藏最多的公开歌单）
// +「分享歌单」宫格（其余用户公开歌单），本地 SQLite 缓存流式读取，
// SyncService 后台异步拉取后端刷新，支持下拉刷新

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../api/backend_client.dart';
import '../services/providers.dart';
import '../utils/cover_resolver.dart';

/// 渐变色列表
const _gradients = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  [Color(0xFF10B981), Color(0xFF34D399)],
  [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  [Color(0xFFEF4444), Color(0xFFF87171)],
  [Color(0xFF06B6D4), Color(0xFF22D3EE)],
];

/// 首页「分享歌单」区默认展示的最大卡片数（3×2 宫格）
const _sharedGridMax = 6;

/// 首页「推荐歌单」区默认展示的最大卡片数（横向轮播，超出进列表页）
const _featuredCarouselMax = 4;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(recommendPlaylistsProvider);

    return Scaffold(
      body: SafeArea(
        // 迷你播放栏由 _MainShell 统一提供
        child: playlistsAsync.when(
          // 本地缓存推荐歌单加载成功
          data: (playlists) {
            if (playlists.isEmpty) {
              // 无缓存（新用户首开或同步失败）：空态 + 重试引导
              return _buildEmptyState(context, ref);
            }
            return _buildWithBackendData(context, ref, playlists);
          },
          // 加载中
          loading: () => const Center(child: CircularProgressIndicator()),
          // 读取失败（本地异常）：空态 + 重试
          error: (_, __) => _buildEmptyState(context, ref),
        ),
      ),
    );
  }

  /// 强制刷新推荐歌单：后台拉取后端并覆盖本地缓存，再失效 provider 重新读取
  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(syncServiceProvider).syncRecommend(force: true);
    ref.invalidate(recommendPlaylistsProvider);
  }

  /// 使用后端（本地缓存）数据构建
  Widget _buildWithBackendData(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> playlists,
  ) {
    // 三区展示：系统歌单（type=system，今日推荐大卡片）、被收藏最多的公开歌单
    //（type=featured，推荐歌单轮播）、其余用户公开歌单（type=user，分享歌单宫格）
    final systemList = playlists.where((p) => p.type == 'system').toList();
    final featuredList = playlists.where((p) => p.type == 'featured').toList();
    final sharedList = playlists.where((p) => p.type == 'user').toList();
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (systemList.isNotEmpty) ...[
            const SizedBox(height: 8),
            // 今日推荐大卡片：取系统歌单第一个（后端 sort_order=1 的「推荐」歌单，
            // cron 每日按全站喜欢数重建，见后端 recommend_service.GenerateSystemRecommendPlaylist）
            _DailyHeroCard(
              playlist: systemList.first,
              gradient: _gradients[0],
              onTap: () => _pushPlaylistDetail(context, systemList.first),
            ),
          ],
          if (featuredList.isNotEmpty) ...[
            // 推荐歌单区标题 + 「查看全部」入口（进列表页仅看推荐位歌单）
            _sectionTitleWithMore(
              '推荐歌单',
              onMore: () => context.push('/shared-playlists?type=featured'),
            ),
            // 轮播截断到上限，剩余推荐位歌单在「查看全部」列表页
            _buildFeaturedCarousel(context, ref, featuredList.take(_featuredCarouselMax).toList()),
          ],
          if (sharedList.isNotEmpty) ...[
            // 分享歌单区标题 + 「查看全部」入口（进列表页看全部公开歌单）
            _sectionTitleWithMore(
              '分享歌单',
              onMore: () => context.push('/shared-playlists'),
            ),
            _buildSharedGrid(context, ref, sharedList),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 分区标题（带右侧「查看全部」入口）
  Widget _sectionTitleWithMore(String title, {required VoidCallback onMore}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('查看全部', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 推荐歌单横向轮播（被收藏最多的公开歌单，后端按收藏数降序，有多少展示多少）
  Widget _buildFeaturedCarousel(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> list,
  ) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final playlist = list[i];
          final gradient = _gradients[i % _gradients.length];
          return _FeaturedPlaylistCard(
            playlist: playlist,
            gradient: gradient,
            onTap: () => _pushPlaylistDetail(context, playlist),
          );
        },
      ),
    );
  }

  /// 分享歌单宫格（3 列，默认最多展示 6 个，「查看全部」入口进列表页）
  Widget _buildSharedGrid(
    BuildContext context,
    WidgetRef ref,
    List<RecommendPlaylist> list,
  ) {
    // 截断到宫格上限，剩余在「更多」列表页展示
    final visible = list.take(_sharedGridMax).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final playlist = visible[i];
          final gradient = _gradients[i % _gradients.length];
          return _SharedPlaylistCard(
            playlist: playlist,
            gradient: gradient,
            onTap: () => _pushPlaylistDetail(context, playlist),
          );
        },
      ),
    );
  }

  /// 跳转歌单详情页（今日推荐/分享歌单共用）
  void _pushPlaylistDetail(BuildContext context, RecommendPlaylist playlist) {
    context.push(
      '/playlist/${playlist.id}',
      extra: {
        'id': playlist.id,
        'name': playlist.name,
        'subtitle': playlist.description.isNotEmpty
            ? playlist.description
            : '${playlist.songCount} 首',
        'backendId': playlist.id,
        'isBackendPlaylist': true,
        'coverUrl': playlist.coverUrl,
        'coverPicId': playlist.coverPicId,
        'coverSource': playlist.coverSource,
      },
    );
  }

  /// 空态：本地无推荐歌单缓存（新用户首开 / 后端不可用），显示重试引导
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          const Icon(Icons.library_music_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            '暂无推荐歌单',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            '下拉刷新或点击重试，从服务器拉取',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 推荐歌单卡片（150×190 竖长卡，封面 + 底部名称 + 创建者，用于「推荐歌单」轮播）──

class _FeaturedPlaylistCard extends ConsumerStatefulWidget {
  final RecommendPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeaturedPlaylistCard({
    required this.playlist,
    required this.gradient,
    required this.onTap,
  });

  @override
  ConsumerState<_FeaturedPlaylistCard> createState() => _FeaturedPlaylistCardState();
}

class _FeaturedPlaylistCardState extends ConsumerState<_FeaturedPlaylistCard> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.playlist.coverUrl.isNotEmpty ? widget.playlist.coverUrl : null;
    _resolveCover();
  }

  /// 无 coverUrl 时按 coverPicId/coverSource 懒加载解析（走共享解析器）
  Future<void> _resolveCover() async {
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;
    final picId = widget.playlist.coverPicId;
    final source = widget.playlist.coverSource;
    if (picId == null || picId.isEmpty || source == null || source.isEmpty) return;
    final url = await resolveCoverByPic(
      client: ref.read(gdMusicClientProvider),
      picDao: ref.read(picCoverDaoProvider),
      picId: picId,
      source: source,
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _coverUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 有封面时在渐变底上叠加封面图（CachedNetworkImage 磁盘缓存，二次进入秒开），否则仅渐变背景
    final hasCover = _coverUrl != null && _coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 渐变始终保留，作为封面加载中/加载失败的占位底色
          gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: widget.gradient.first.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // 封面图：与 CoverImage/PlaylistCover 一致走磁盘缓存，加载中/失败回落到渐变底
            if (hasCover)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // 底部暗色遮罩，保证文字可读
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    widget.playlist.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 创建者头像 + 昵称（推荐位均为用户公开歌单，必有创建者，缺失时退化显示歌曲数）
                  if (widget.playlist.userName != null && widget.playlist.userName!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: (widget.playlist.userAvatar != null && widget.playlist.userAvatar!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: widget.playlist.userAvatar!,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _creatorDefaultAvatar(),
                                  errorWidget: (_, __, ___) => _creatorDefaultAvatar(),
                                )
                              : _creatorDefaultAvatar(),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            widget.playlist.userName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${widget.playlist.songCount} 首',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 创建者默认头像占位
  Widget _creatorDefaultAvatar() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: const Icon(Icons.person_rounded, size: 10, color: Colors.white70),
    );
  }
}

// ── 今日推荐大卡片（渐变大卡 + DAILY PICK 标签 + 右侧音符装饰，对应设计稿 daily-hero）──

class _DailyHeroCard extends ConsumerStatefulWidget {
  final RecommendPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DailyHeroCard({
    required this.playlist,
    required this.gradient,
    required this.onTap,
  });

  @override
  ConsumerState<_DailyHeroCard> createState() => _DailyHeroCardState();
}

class _DailyHeroCardState extends ConsumerState<_DailyHeroCard> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.playlist.coverUrl.isNotEmpty ? widget.playlist.coverUrl : null;
    _resolveCover();
  }

  /// 无 coverUrl 时按 coverPicId/coverSource 懒加载解析（走共享解析器）
  Future<void> _resolveCover() async {
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;
    final picId = widget.playlist.coverPicId;
    final source = widget.playlist.coverSource;
    if (picId == null || picId.isEmpty || source == null || source.isEmpty) return;
    final url = await resolveCoverByPic(
      client: ref.read(gdMusicClientProvider),
      picDao: ref.read(picCoverDaoProvider),
      picId: picId,
      source: source,
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _coverUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 有封面时在渐变底上叠加封面图（CachedNetworkImage 磁盘缓存，二次进入秒开），否则仅渐变背景
    final hasCover = _coverUrl != null && _coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 160,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 渐变始终保留，作为封面加载中/加载失败的占位底色
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: widget.gradient.first.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            // 封面图：与 CoverImage/PlaylistCover 一致走磁盘缓存，加载中/失败回落到渐变底
            if (hasCover)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // 半透明暗色遮罩，保证文字可读（封面之上、文字之下）
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            // 左侧文案 + 右侧音符装饰
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // DAILY PICK 小标签
                        Text(
                          'DAILY PICK',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '今日推荐',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 副文案：基于过往喜好推荐 · N 首
                        Text(
                          '猜你喜欢 · ${widget.playlist.songCount} 首',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右侧半透明圆 + 音符装饰
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.music_note_rounded, size: 40, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 分享歌单宫格小卡片（正方形，封面 + 名称 + 创建者头像昵称）──

class _SharedPlaylistCard extends ConsumerStatefulWidget {
  final RecommendPlaylist playlist;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _SharedPlaylistCard({
    required this.playlist,
    required this.gradient,
    required this.onTap,
  });

  @override
  ConsumerState<_SharedPlaylistCard> createState() => _SharedPlaylistCardState();
}

class _SharedPlaylistCardState extends ConsumerState<_SharedPlaylistCard> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.playlist.coverUrl.isNotEmpty ? widget.playlist.coverUrl : null;
    _resolveCover();
  }

  /// 无 coverUrl 时按 coverPicId/coverSource 懒加载解析（走共享解析器）
  Future<void> _resolveCover() async {
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;
    final picId = widget.playlist.coverPicId;
    final source = widget.playlist.coverSource;
    if (picId == null || picId.isEmpty || source == null || source.isEmpty) return;
    final url = await resolveCoverByPic(
      client: ref.read(gdMusicClientProvider),
      picDao: ref.read(picCoverDaoProvider),
      picId: picId,
      source: source,
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _coverUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 有封面时在渐变底上叠加封面图（CachedNetworkImage 磁盘缓存，二次进入秒开），否则仅渐变背景
    final hasCover = _coverUrl != null && _coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // 渐变始终保留，作为封面加载中/加载失败的占位底色
          gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: widget.gradient.first.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            // 封面图：与 CoverImage/PlaylistCover 一致走磁盘缓存，加载中/失败回落到渐变底
            if (hasCover)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            // 底部暗色遮罩，保证文字可读
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // 歌单名 + 创建者头像昵称
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    widget.playlist.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 创建者头像 + 昵称（分享歌单必有创建者，缺失时仅显示歌曲数）
                  if (widget.playlist.userName != null && widget.playlist.userName!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: (widget.playlist.userAvatar != null && widget.playlist.userAvatar!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: widget.playlist.userAvatar!,
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _creatorDefaultAvatar(),
                                  errorWidget: (_, __, ___) => _creatorDefaultAvatar(),
                                )
                              : _creatorDefaultAvatar(),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.playlist.userName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${widget.playlist.songCount} 首',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 创建者默认头像占位
  Widget _creatorDefaultAvatar() {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
      child: const Icon(Icons.person_rounded, size: 9, color: Colors.white70),
    );
  }
}
