import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'db/app_database.dart';
import 'services/providers.dart';

/// 是否正在退出（Cmd+Q 时设为 true，阻止 onWindowClose 最小化）
bool _isQuitting = false;

/// 窗口是否正在显示
bool _windowVisible = true;

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

    // 关闭窗口时最小化到 Dock，而不是退出应用
    await windowManager.setPreventClose(true);

    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化系统托盘（菜单栏图标）
  await _initSystemTray();

  // 监听 Cmd+Q 退出
  HardwareKeyboard.instance.addHandler(_handleKeyQuit);

  // 监听窗口事件（保存状态 + 关闭时最小化到 Dock）
  windowManager.addListener(_AppWindowListener(prefs));

  // 恢复上次播放会话（队列、当前歌曲、播放模式）
  final container = ProviderContainer();
  final audio = container.read(audioServiceProvider);
  await audio.restoreSession();

  runApp(UncontrolledProviderScope(
    container: container,
    child: ViaMusicApp(),
  ));
}

/// Cmd+Q 键盘监听：设置退出标志，允许窗口关闭
bool _handleKeyQuit(KeyEvent event) {
  if (event is KeyDownEvent || event is KeyRepeatEvent) {
    final isCmd = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (isCmd && event.logicalKey == LogicalKeyboardKey.keyQ) {
      _isQuitting = true;
    }
  }
  return false; // 不阻止其他处理器
}

/// 初始化系统托盘：菜单栏常驻图标
Future<void> _initSystemTray() async {
  final systemTray = SystemTray();

  // 设置菜单栏图标（仅图标，无文字）
  await systemTray.initSystemTray(
    title: '',
    iconPath: 'assets/tray_icon.png',
    toolTip: 'Via Music',
  );

  // 构建右键菜单
  await systemTray.setContextMenu([
    MenuItem(
      label: '显示 Via Music',
      onClicked: () async {
        await windowManager.show();
        await windowManager.focus();
        _windowVisible = true;
      },
    ),
    MenuSeparator(),
    MenuItem(
      label: '退出',
      onClicked: () async {
        _isQuitting = true;
        await windowManager.setPreventClose(false);
        await windowManager.close();
      },
    ),
  ]);

  // 点击菜单栏图标：左键显示/隐藏，右键弹出菜单
  systemTray.registerSystemTrayEventHandler((eventName) async {
    if (eventName == 'leftMouseUp') {
      if (_windowVisible) {
        // 隐藏窗口（触发 onWindowClose → 最小化到 Dock）
        await windowManager.close();
        _windowVisible = false;
      } else {
        await windowManager.show();
        await windowManager.focus();
        _windowVisible = true;
      }
    } else if (eventName == 'rightMouseUp') {
      await systemTray.popUpContextMenu();
    }
  });
}

/// 窗口事件监听：保存窗口状态 + 关闭时最小化到 Dock
class _AppWindowListener extends WindowListener {
  final SharedPreferences _prefs;
  Timer? _saveTimer;

  _AppWindowListener(this._prefs);

  // ── 关闭窗口 → 最小化到 Dock（而非退出）──

  @override
  void onWindowClose() {
    if (_isQuitting) {
      // Cmd+Q 或菜单退出，允许退出
      windowManager.setPreventClose(false);
      windowManager.close();
    } else {
      // 关闭按钮或状态栏隐藏，最小化到 Dock
      windowManager.minimize();
      _windowVisible = false;
    }
  }

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
