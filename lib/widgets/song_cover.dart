import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../utils/cover_resolver.dart';
import 'cover_image.dart';

/// 歌曲封面组件：根据歌曲自动解析并展示封面图
///
/// 解析优先级：
/// 1. 外部显式传入的 [coverUrl]（调用方可覆盖）
/// 2. [song.coverUrl]（后端已返回完整 URL 时直接使用）
/// 3. [song.picId] 懒加载调用外部 API 解析（走共享解析器：内存+sqlite local_pic_covers 缓存）
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

  /// 解析封面 URL：已有 URL 或命中共享缓存直接使用，否则走共享解析器懒加载
  Future<void> _resolveCoverUrl() async {
    // 已有完整 URL 时无需解析
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;

    final picId = widget.song.picId;
    // 无 picId：历史 songs 数据可能缺封面信息，按歌名+歌手搜索补封面
    if (picId == null || picId.isEmpty) {
      await _resolveCoverBySearch();
      return;
    }

    // 走共享解析器（内部含内存缓存命中 + 并发去重 + sqlite/API 解析 + 回填磁盘）
    final url = await resolveCoverByPic(
      client: ref.read(gdMusicClientProvider),
      picDao: ref.read(picCoverDaoProvider),
      picId: picId,
      source: widget.song.source,
    );
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _coverUrl = url);
    }
  }

  /// 兜底：按歌名+歌手搜索匹配解析封面（历史数据回填，带（本地 sqlite/共享内存）缓存与去重）
  Future<void> _resolveCoverBySearch() async {
    if (coverUrlCache.containsKey(_cacheKey)) {
      final url = coverUrlCache[_cacheKey];
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
      return;
    }
    if (coverUrlInFlight.contains(_cacheKey)) return;
    coverUrlInFlight.add(_cacheKey);

    try {
      String? url;
      // 优先读本地 sqlite 缓存
      try {
        url = await ref
            .read(songMetaDaoProvider)
            .getCoverUrl(widget.song.id, widget.song.source);
      } catch (_) {
        url = null;
      }
      if (url == null || url.isEmpty) {
        final resolver = ref.read(songResolverProvider);
        url = await resolver.searchCoverUrl(widget.song);
        if (url != null && url.isNotEmpty) {
          try {
            await ref.read(songMetaDaoProvider).upsert(
                  songId: widget.song.id,
                  source: widget.song.source,
                  coverUrl: url,
                );
          } catch (_) {}
        }
      }
      coverUrlCache[_cacheKey] = url;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
    } catch (_) {
      // 解析失败：保持占位图，不写入缓存以便下次重试
    } finally {
      coverUrlInFlight.remove(_cacheKey);
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