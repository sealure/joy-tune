import 'package:flutter/material.dart';

/// 播放器进度条组件
class PlayerSeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (_, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final p = details.localPosition.dx / constraints.maxWidth;
                  final seekPos = Duration(
                    milliseconds: (duration.inMilliseconds * p).round(),
                  );
                  onSeek(seekPos);
                },
                child: Container(
                  height: 20,
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: (progress.clamp(0.0, 1.0) * constraints.maxWidth) - 6,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
