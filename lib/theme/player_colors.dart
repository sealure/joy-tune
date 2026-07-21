import 'package:flutter/material.dart';

/// 播放器页面深色沉浸式主题颜色
///
/// 与 AppTheme 的靛蓝色调有意区分，专用于全屏播放器。
class PlayerColors {
  PlayerColors._();

  // ── 背景渐变 ──
  static const backgroundTop = Color(0xFF064E3B);
  static const backgroundMid = Color(0xFF065F46);
  static const backgroundBottom = Color(0xFF022C22);

  // ── 封面占位渐变 ──
  static const placeholderTop = Color(0xFF065F46);
  static const placeholderMid = Color(0xFF059669);
  static const placeholderBottom = Color(0xFF10B981);
}
