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
              // 点击/拖拽 → 按横向位置换算目标进度
              void seekAt(BuildContext context, Offset localPos) {
                final width = constraints.maxWidth;
                final p = (localPos.dx / width).clamp(0.0, 1.0);
                final seekPos = Duration(
                  milliseconds: (duration.inMilliseconds * p).round(),
                );
                onSeek(seekPos);
              }

              return GestureDetector(
                // 透明背景也能命中（覆盖 44 高热区，便于触摸/鼠标点按）
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => seekAt(context, details.localPosition),
                onHorizontalDragStart: (details) => seekAt(context, details.localPosition),
                onHorizontalDragUpdate: (details) => seekAt(context, details.localPosition),
                child: Container(
                  height: 44,
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 轨道（视觉 3px，垂直居中）
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Center(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // 拖拽圆点（视觉 12px，命中区更大；垂直居中于 44 高热区）
                      Positioned(
                        left: (progress.clamp(0.0, 1.0) * constraints.maxWidth) - 6,
                        top: 16,
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
