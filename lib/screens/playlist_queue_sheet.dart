import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 播放队列底部 sheet
class PlaylistQueueSheet extends ConsumerStatefulWidget {
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
  ConsumerState<PlaylistQueueSheet> createState() => _PlaylistQueueSheetState();
}

class _PlaylistQueueSheetState extends ConsumerState<PlaylistQueueSheet> {
  StreamSubscription<PlayState>? _stateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stateSub = ref.read(audioServiceProvider).stateStream.listen((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.read(audioServiceProvider);
    final queue = audio.queue;
    final currentIndex = audio.currentQueueIndex;
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
                  width: 36, height: 4,
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
                      '(${queue.length}首)',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.secondary),
                    ),
                    const Spacer(),
                    if (queue.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          audio.stop();
                          Navigator.pop(context);
                        },
                        child: Text(
                          '清空',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.secondary),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 队列列表
              if (queue.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: queue.length,
                    itemBuilder: (_, i) {
                      final song = queue[i];
                      final isCurrent = i == currentIndex;
                      return _QueueTile(
                        song: song,
                        index: i,
                        isCurrent: isCurrent,
                        onTap: () {
                          if (!isCurrent) {
                            audio.jumpTo(i);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),

              // 空状态
              if (queue.isEmpty)
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
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;

  const _QueueTile({
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF6366F1).withValues(alpha: 0.06) : null,
        border: isCurrent
            ? const Border(left: BorderSide(color: Color(0xFF6366F1), width: 3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF6366F1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isCurrent
                ? Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white)
                : Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
        ),
        title: Text(
          song.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isCurrent ? TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary) : null,
        ),
        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}
