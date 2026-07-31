// 歌单封面组件
// 有 coverUrl 时显示网络图，否则显示渐变占位 + 音符图标
// 我的歌单列表页 / 详情页 Hero / 选择歌单弹层复用

import 'package:flutter/material.dart';

/// 歌单封面
class PlaylistCover extends StatelessWidget {
  final String coverUrl;
  final double size;
  final double borderRadius;
  final List<Color>? gradient;

  const PlaylistCover({
    super.key,
    required this.coverUrl,
    this.size = 56,
    this.borderRadius = 12,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? const [Color(0xFFA5B4FC), Color(0xFF818CF8)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: coverUrl.isNotEmpty
          ? Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: size * 0.45,
              ),
            )
          : Icon(Icons.music_note_rounded, color: Colors.white, size: size * 0.45),
    );
  }
}
