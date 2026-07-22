import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'db/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 media_kit（加载 libmpv）
  MediaKit.ensureInitialized();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  // 初始化本地数据库
  await AppDatabase.initialize();

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 恢复上次窗口状态，没有则使用默认值
  final savedWidth = prefs.getDouble('window_width') ?? 400;
  final savedHeight = prefs.getDouble('window_height') ?? 700;
  final savedPosX = prefs.getDouble('window_x');
  final savedPosY = prefs.getDouble('window_y');

  const windowOptions = WindowOptions(
    size: Size(400, 700), // 默认窗口大小
    minimumSize: Size(400, 500), // 最小窗口尺寸，防止过度缩小
    center: true, // 居中显示
    title: 'Via Music',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 设置窗口大小（优先使用上次保存的尺寸）
    await windowManager.setSize(Size(savedWidth, savedHeight));

    // 恢复窗口位置（如有保存）
    if (savedPosX != null && savedPosY != null) {
      await windowManager.setPosition(Offset(savedPosX, savedPosY));
    } else {
      await windowManager.center();
    }

    await windowManager.show();
    await windowManager.focus();
  });

  // 监听窗口移动/缩放，保存状态
  windowManager.addListener(_WindowSaveListener(prefs));

  runApp(ProviderScope(child: ViaMusicApp()));
}

/// 监听窗口事件，自动保存窗口位置和大小
class _WindowSaveListener extends WindowListener {
  final SharedPreferences _prefs;
  Timer? _saveTimer;

  _WindowSaveListener(this._prefs);

  @override
  void onWindowResize() {
    // 防抖：缩放过程中延迟保存
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveState);
  }

  @override
  void onWindowMove() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveState);
  }

  void _saveState() async {
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    await _prefs.setDouble('window_width', size.width);
    await _prefs.setDouble('window_height', size.height);
    await _prefs.setDouble('window_x', pos.dx);
    await _prefs.setDouble('window_y', pos.dy);
  }

  void dispose() {
    _saveTimer?.cancel();
  }
}
