import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
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

  // 初始化系统托盘（菜单栏图标）
  await _initSystemTray();

  // 监听窗口事件（保存状态）
  windowManager.addListener(_AppWindowListener(prefs));

  runApp(ProviderScope(child: ViaMusicApp()));
}

/// 窗口事件监听：保存窗口状态
class _AppWindowListener extends WindowListener {
  final SharedPreferences _prefs;
  Timer? _saveTimer;

  _AppWindowListener(this._prefs);

  // ── 窗口移动/缩放 → 保存状态（防抖500ms）──

  @override
  void onWindowResize() {
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

/// 初始化系统托盘：菜单栏常驻图标 + 下拉菜单
Future<void> _initSystemTray() async {
  final systemTray = SystemTray();

  // 设置菜单栏图标
  await systemTray.initSystemTray(
    title: 'Via Music',
    iconPath: 'assets/tray_icon.png',
    toolTip: 'Via Music',
  );

  // 构建右键菜单
  await systemTray.setContextMenu([
    // 显示/隐藏窗口
    MenuItem(
      label: '显示 Via Music',
      onClicked: () async {
        final isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.focus();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      },
    ),
    MenuSeparator(),
    // 退出应用
    MenuItem(
      label: '退出',
      onClicked: () {
        windowManager.close();
      },
    ),
  ]);

  // 点击菜单栏图标：左键显示/隐藏，右键弹出菜单
  systemTray.registerSystemTrayEventHandler((eventName) async {
    if (eventName == 'click') {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    } else if (eventName == 'right-click') {
      await systemTray.popUpContextMenu();
    }
  });
}
