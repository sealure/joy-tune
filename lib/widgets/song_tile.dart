import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';

/// 歌曲列表项
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SongTile({super.key, required this.song, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 封面占位
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note_rounded, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),

              // 歌名 & 歌手
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${song.artist} · ${song.source}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 右侧操作
              if (trailing != null) trailing!,
              if (trailing == null)
                Icon(Icons.play_circle_outline_rounded, size: 22, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
