import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'db/app_database.dart';
import 'services/providers.dart';
// 延迟导入桌面端模块（仅桌面平台使用）
import 'desktop_init.dart' as desktop;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 media_kit（加载 libmpv）
  MediaKit.ensureInitialized();

  // 初始化本地数据库
  await AppDatabase.initialize();

  // 桌面端初始化（try-catch 保护，移动端不会报错）
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    try {
      await desktop.initDesktop();
    } catch (e) {
      debugPrint('桌面端初始化跳过: $e');
    }
  }

  // 恢复上次播放会话
  final container = ProviderContainer();
  final audio = container.read(audioServiceProvider);
  await audio.restoreSession();

  runApp(UncontrolledProviderScope(
    container: container,
    child: ViaMusicApp(),
  ));
}
