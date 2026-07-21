import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 底部迷你播放栏（当无播放内容时隐藏）
class MiniPlayerBar extends ConsumerStatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  ConsumerState<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends ConsumerState<MiniPlayerBar> {
  StreamSubscription<PlayState>? _stateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stateSub = ref.read(audioServiceProvider).stateStream.listen((_) {
        // 触发 rebuild，build 中直接从 audioService 读最新状态
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
    final song = audio.currentSong;
    final playState = audio.state;
    final theme = Theme.of(context);

    // 无播放内容时隐藏
    if (song == null && playState == PlayState.stopped) {
      return const SizedBox.shrink();
    }

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
          onTap: () => context.push('/player', extra: song),
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
                      Text(song?.name ?? '未在播放', style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(song?.artist ?? '点击搜索歌曲', style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),

                // 控制按钮
                IconButton(
                  icon: Icon(
                    playState == PlayState.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    if (playState == PlayState.playing) {
                      audio.pause();
                    } else {
                      audio.resume();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
