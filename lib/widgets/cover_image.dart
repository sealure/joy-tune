import 'package:flutter/material.dart';

/// 封面子组件（带 CachedNetworkImage 占位）
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            size: size * 0.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
