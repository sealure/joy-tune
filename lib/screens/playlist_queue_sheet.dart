import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 播放队列底部 sheet
class PlaylistQueueSheet extends ConsumerWidget {
  const PlaylistQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlaylistQueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioServiceProvider);
    final currentSong = audio.currentSong;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Text('播放队列', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      '(1首)',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '清空',
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 当前播放（高亮）
              if (currentSong != null)
                _QueueTile(
                  song: currentSong,
                  isCurrent: true,
                  onRemove: () {},
                ),

              // 空状态
              if (currentSong == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.queue_music_rounded, size: 48, color: theme.colorScheme.secondary),
                        const SizedBox(height: 12),
                        Text('播放队列为空', style: TextStyle(color: theme.colorScheme.secondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final VoidCallback onRemove;

  const _QueueTile({
    required this.song,
    required this.isCurrent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF059669).withValues(alpha: 0.06) : null,
        border: isCurrent
            ? const Border(left: BorderSide(color: Color(0xFF059669), width: 3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.music_note_rounded, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.secondary),
          onPressed: onRemove,
        ),
        onTap: () {},
      ),
    );
  }
}
