import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 封面子组件
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
