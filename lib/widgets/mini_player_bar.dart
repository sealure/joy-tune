import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import 'song_cover.dart';

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
                // 封面：显示当前歌曲封面，无歌曲时用占位图
                if (song != null)
                  SongCover(song: song, size: 40, borderRadius: 8)
                else
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
                    // ── 诊断日志：打印点击时的完整播放状态，定位重启后点击播放无效的问题 ──
                    final pos = audio.position;
                    final dur = audio.duration;
                    print('[MiniPlayer] 点击播放按钮: '
                        'state=$playState, '
                        'song=${song?.name}, songId=${audio.currentSongId}, '
                        'queueLen=${audio.queue.length}, queueIndex=${audio.currentQueueIndex}, '
                        'playerPlaying=${audio.isPlaying}, '
                        'position=${pos?.inMilliseconds ?? -1}ms, '
                        'duration=${dur?.inMilliseconds ?? -1}ms');
                    if (playState == PlayState.playing) {
                      print('[MiniPlayer] 分支 playing → audio.pause()');
                      audio.pause();
                    } else if (playState == PlayState.paused &&
                        (dur?.inMilliseconds ?? 0) > 0) {
                      // 已加载媒体且暂停 → 恢复播放
                      print('[MiniPlayer] 分支 paused(有媒体) → audio.resume()');
                      audio.resume();
                    } else if (song != null) {
                      // stopped / loading / 假 paused（重启恢复会话未加载媒体，duration=0）：
                      // resume() 裸调 _player.play() 无媒体可播。此处原地走 playSong() 真正
                      // 解析+播放（mini 播放器即播放页的软链接，行为等同播放页点播放，但不跳页）
                      print('[MiniPlayer] 分支 $playState 无媒体可恢复 → '
                          '原地 audio.playSong(${song.name})');
                      audio.playSong(song, restorePosition: true);
                    } else {
                      // 无歌曲兜底，保持原逻辑避免状态异常
                      print('[MiniPlayer] 分支 $playState 且无歌曲 → 兜底 audio.resume()');
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
