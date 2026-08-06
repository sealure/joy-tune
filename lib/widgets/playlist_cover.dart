// 歌单封面组件
// 有 coverUrl 时直接显示网络图；否则按 coverPicId/coverSource 懒加载解析（走共享封面解析器，
// 与歌曲封面共用内存 + sqlite local_pic_covers 持久化缓存）；都没有时显示渐变占位 + 音符图标。
// 我的歌单列表页 / 详情页 Hero / 选择歌单弹层 / 收藏歌单列表复用

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';
import '../utils/cover_resolver.dart';

/// 歌单封面
class PlaylistCover extends ConsumerStatefulWidget {
  final String coverUrl;
  /// 封面来源歌曲 pic_id（coverUrl 为空时按此懒加载解析封面）
  final String? coverPicId;
  /// 封面来源歌曲音源标识
  final String? coverSource;
  final double size;
  final double borderRadius;
  final List<Color>? gradient;

  const PlaylistCover({
    super.key,
    required this.coverUrl,
    this.coverPicId,
    this.coverSource,
    this.size = 56,
    this.borderRadius = 12,
    this.gradient,
  });

  @override
  ConsumerState<PlaylistCover> createState() => _PlaylistCoverState();
}

class _PlaylistCoverState extends ConsumerState<PlaylistCover> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.coverUrl.isNotEmpty ? widget.coverUrl : null;
    _resolveCover();
  }

  @override
  void didUpdateWidget(covariant PlaylistCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 封面来源或 URL 变化时重新解析
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.coverPicId != widget.coverPicId ||
        oldWidget.coverSource != widget.coverSource) {
      _coverUrl = widget.coverUrl.isNotEmpty ? widget.coverUrl : null;
      _resolveCover();
    }
  }

  /// 无 coverUrl 时按 coverPicId/coverSource 懒加载解析（走共享解析器 + 持久化缓存）
  Future<void> _resolveCover() async {
    if (_coverUrl != null && _coverUrl!.isNotEmpty) return;
    final picId = widget.coverPicId;
    final source = widget.coverSource;
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
    final coverUrl = _coverUrl;
    return Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradient ?? const [Color(0xFFA5B4FC), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: (coverUrl != null && coverUrl.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: widget.size * 0.45,
              ),
            )
          : Icon(Icons.music_note_rounded, color: Colors.white, size: widget.size * 0.45),
    );
  }
}