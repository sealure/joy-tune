import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/audio_cache.dart';
import '../services/providers.dart';
import 'cover_image.dart';

/// 封面 URL 内存缓存：缓存键 `${source}_${picId}` → 封面 URL
/// 同一首歌在列表滚动、列表切换、迷你播放栏等场景共用，避免重复请求
final Map<String, String?> _coverUrlCache = {};

/// 封面 URL 请求中集合：防止同一首歌并发发起多次解析请求
final Set<String> _coverUrlInFlight = {};

/// 歌曲封面组件：根据歌曲自动解析并展示封面图
///
/// 解析优先级：
/// 1. 外部显式传入的 [coverUrl]（调用方可覆盖）
/// 2. [song.coverUrl]（后端已返回完整 URL 时直接使用）
/// 3. [song.picId] 懒加载调用外部 API 解析，结果写入内存缓存
///
/// 解析失败或缺少封面信息时降级为占位图。
class SongCover extends ConsumerStatefulWidget {
  final Song song;
  final String? coverUrl;
  final double size;
  final double borderRadius;

  const SongCover({
    super.key,
    required this.song,
    this.coverUrl,
    this.size = 44,
    this.borderRadius = 8,
  });

  @override
  ConsumerState<SongCover> createState() => _SongCoverState();
}

class _SongCoverState extends ConsumerState<SongCover> {
  String? _coverUrl;

  /// 内存缓存键：有 picId 用 `${source}_${picId}`，否则用 `${source}_${songId}`
  String get _cacheKey {
    final picId = widget.song.picId;
    return (picId != null && picId.isNotEmpty)
        ? '${widget.song.source}_$picId'
        : '${widget.song.source}_${widget.song.id}';
  }

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.coverUrl ?? widget.song.coverUrl;
    _resolveCoverUrl();
  }

  @override
  void didUpdateWidget(covariant SongCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 歌曲切换（如列表复用、迷你播放栏换歌）时重新解析封面
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.song.source != widget.song.source) {
      _coverUrl = widget.coverUrl ?? widget.song.coverUrl;
      _resolveCoverUrl();
    }
  }

  /// 解析封面 URL：已有 URL 或命中（内存/磁盘）缓存直接使用，否则懒加载调外部 API
  /// 首次解析并行持久化到磁盘缓存，之后复用，减少重复网络请求（手动清理缓存才清除）
  Future<void> _resolveCoverUrl() async {
    // 已有完整 URL 时无需解析
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;

    final picId = widget.song.picId;
    // 无 picId：历史 songs 数据可能缺封面信息，按歌名+歌手搜索补封面
    if (picId == null || picId.isEmpty) {
      await _resolveCoverBySearch();
      return;
    }

    // 命中内存缓存直接使用
    if (_coverUrlCache.containsKey(_cacheKey)) {
      final url = _coverUrlCache[_cacheKey];
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
      return;
    }

    // 请求进行中则跳过，避免同一首歌并发重复请求
    if (_coverUrlInFlight.contains(_cacheKey)) return;
    _coverUrlInFlight.add(_cacheKey);

    try {
      String? url;
      // 优先读磁盘缓存的封面 URL（拉过一次即持久化）
      try {
        url = await AudioCache.instance.getCachedCoverUrl(_cacheKey);
      } catch (_) {
        // 缓存不可达时忽略，走实时解析
      }
      if (url == null || url.isEmpty) {
        final client = ref.read(gdMusicClientProvider);
        final resolved = await client.getCoverUrl(picId: picId, source: widget.song.source);
        if (resolved.isNotEmpty) {
          url = resolved;
          try {
            await AudioCache.instance.cacheCoverUrl(_cacheKey, resolved);
          } catch (_) {
            // 持久化失败不影响本次显示
          }
        }
      }
      _coverUrlCache[_cacheKey] = url;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
    } catch (_) {
      // 解析失败：保持占位图，不写入缓存以便下次重试
    } finally {
      _coverUrlInFlight.remove(_cacheKey);
    }
  }

  /// 兜底：按歌名+歌手搜索匹配解析封面（历史数据回填，带（内存/磁盘）缓存与去重）
  Future<void> _resolveCoverBySearch() async {
    if (_coverUrlCache.containsKey(_cacheKey)) {
      final url = _coverUrlCache[_cacheKey];
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
      return;
    }
    if (_coverUrlInFlight.contains(_cacheKey)) return;
    _coverUrlInFlight.add(_cacheKey);

    try {
      String? url;
      // 优先读磁盘缓存
      try {
        url = await AudioCache.instance.getCachedCoverUrl(_cacheKey);
      } catch (_) {
        url = null;
      }
      if (url == null || url.isEmpty) {
        final resolver = ref.read(songResolverProvider);
        url = await resolver.searchCoverUrl(widget.song);
        if (url != null && url.isNotEmpty) {
          try {
            await AudioCache.instance.cacheCoverUrl(_cacheKey, url);
          } catch (_) {}
        }
      }
      _coverUrlCache[_cacheKey] = url;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
    } catch (_) {
      // 解析失败：保持占位图，不写入缓存以便下次重试
    } finally {
      _coverUrlInFlight.remove(_cacheKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoverImage(
      url: _coverUrl,
      size: widget.size,
      borderRadius: widget.borderRadius,
    );
  }
}
