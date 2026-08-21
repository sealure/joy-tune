import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 判断封面 URL 是否为本地文件（`file://` 前缀或机器可读路径）
bool isLocalCoverUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  if (url.startsWith('file://')) return true;
  // 已下载本地封面直接传绝对路径（Windows `C:\...` / Android `/storage/...`）
  return !url.startsWith('http://') &&
      !url.startsWith('https://') &&
      (url.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(url));
}

/// 封面子组件：支持网络 URL 与本地文件（`file://`/绝对路径，已下载歌曲封面）
class CoverImage extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;

  const CoverImage({
    super.key,
    this.url,
    this.size = 44,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.music_note_rounded, size: size * 0.5, color: theme.colorScheme.primary),
    );

    if (url == null) return placeholder;

    // 本地文件（已下载歌曲图片.jpg）：用 Image.file 直接加载，离线可见
    if (isLocalCoverUrl(url)) {
      final path = url!.startsWith('file://')
          ? Uri.parse(url!).toFilePath()
          : url!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
