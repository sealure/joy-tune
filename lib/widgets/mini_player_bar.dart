import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 底部迷你播放栏（当无播放内容时隐藏）
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 无播放内容时隐藏
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/player'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 封面占位
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note_rounded, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),

                // 歌名
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('未在播放', style: theme.textTheme.bodyMedium),
                      Text('点击搜索歌曲', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),

                // 控制按钮
                Icon(Icons.play_circle_filled_rounded, size: 36, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
