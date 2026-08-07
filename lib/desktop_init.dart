import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';

/// 桌面端初始化（窗口管理器 + 系统托盘）
Future<void> initDesktop() async {
  await windowManager.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedWidth = prefs.getDouble('window_width') ?? 400;
  final savedHeight = prefs.getDouble('window_height') ?? 700;
  final savedPosX = prefs.getDouble('window_x');
  final savedPosY = prefs.getDouble('window_y');

  const windowOptions = WindowOptions(
    size: Size(400, 700),
    minimumSize: Size(400, 500),
    center: true,
    title: '悦听',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setSize(Size(savedWidth, savedHeight));
    if (savedPosX != null && savedPosY != null) {
      await windowManager.setPosition(Offset(savedPosX, savedPosY));
    } else {
      await windowManager.center();
    }
    // 不设 setPreventClose,点标题栏 X 直接退出(系统托盘保留显示/退出菜单)
    await windowManager.show();
    await windowManager.focus();
  });

  // 系统托盘
  final systemTray = SystemTray();
  await systemTray.initSystemTray(
    title: '',
    iconPath: 'assets/tray_icon.png',
    toolTip: '悦听',
  );

  await systemTray.setContextMenu([
    MenuItem(
      label: '显示 悦听',
      onClicked: () async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
    MenuSeparator(),
    MenuItem(
      label: '退出',
      onClicked: () async {
        await windowManager.close();
      },
    ),
  ]);

  systemTray.registerSystemTrayEventHandler((eventName) async {
    if (eventName == 'leftMouseUp') {
      await windowManager.show();
      await windowManager.focus();
    } else if (eventName == 'rightMouseUp') {
      await systemTray.popUpContextMenu();
    }
  });

  // 窗口事件监听
  windowManager.addListener(_AppWindowListener());
}

/// 窗口事件监听（保存窗口尺寸/位置；关闭由系统默认处理，直接退出）
class _AppWindowListener extends WindowListener {
  Timer? _saveTimer;

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
    final prefs = await SharedPreferences.getInstance();
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    await prefs.setDouble('window_width', size.width);
    await prefs.setDouble('window_height', size.height);
    await prefs.setDouble('window_x', pos.dx);
    await prefs.setDouble('window_y', pos.dy);
  }
}
