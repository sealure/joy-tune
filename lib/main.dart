// 应用入口
// 初始化所有服务，检查配置和停服开关

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'config/api_config.dart';
import 'db/app_database.dart';
import 'services/providers.dart';
// 延迟导入桌面端模块（仅桌面平台使用）
import 'desktop_init.dart' as desktop;

/// 获取当前平台标识
String _platformName() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

/// 生成或获取设备 ID（用于停服检查）
/// 仅保存稳定的系统 ID（ANDROID_ID / iOS IDFV），不含平台前缀（平台由上报字段单独携带）；
/// 优先复用本地已存 ID，取不到系统 ID 时回退到随机 UUID。
Future<String> _getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString('device_id');
  if (deviceId != null && deviceId.isNotEmpty) {
    // 已有则复用，避免升级后设备被当成新设备
    return deviceId;
  }

  // 首次生成：优先使用系统稳定 ID
  const uuid = Uuid();
  final systemId = await _getSystemDeviceId();
  deviceId = systemId ?? uuid.v4();
  await prefs.setString('device_id', deviceId);
  return deviceId;
}

/// 获取系统级稳定设备 ID
/// Android 返回 ANDROID_ID（8+ 卸载重装可能变化，系统备份恢复则不变）；
/// iOS 返回 identifierForVendor。取不到返回 null，由调用方回退到随机 UUID。
Future<String?> _getSystemDeviceId() async {
  try {
    const channel = MethodChannel('via_music/device_id');
    final id = await channel.invokeMethod<String>('getSystemDeviceId');
    // ANDROID_ID 过滤空值与已知的无效占位值 9774d56d682e549c
    if (id != null && id.isNotEmpty && id != '9774d56d682e549c') {
      return id;
    }
  } catch (e) {
    debugPrint('>>> [DEVICE] 获取系统设备 ID 失败: $e');
  }
  return null;
}

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

  // 创建 Provider 容器
  final container = ProviderContainer();

  // ── 启动时拉取后端配置 ──
  try {
    final backendClient = container.read(backendClientProvider);

    // 获取设备 ID
    final deviceId = await _getDeviceId();

    // 上报设备（幂等，失败静默忽略不影响启动）
    await backendClient.reportDevice(
      deviceId: deviceId,
      platform: _platformName(),
      appVersion: appVersion,
    );

    // 检查停服开关（优先级最高）
    final shutdownResult = await backendClient.checkShutdown(deviceId: deviceId);
    if (shutdownResult.enabled) {
      // 停服：弹窗提示后退出
      runApp(_ShutdownApp(message: shutdownResult.message));
      return;
    }

    // 拉取系统配置
    final configs = await backendClient.getConfigs();

    // 更新音乐 API 地址
    final musicApiUrl = configs['music_api_url'] as String?;
    if (musicApiUrl != null && musicApiUrl.isNotEmpty) {
      container.read(gdMusicClientProvider).updateBaseUrl(musicApiUrl);
      debugPrint('>>> [STARTUP] 音乐 API 地址已更新: $musicApiUrl');
    }
  } catch (e) {
    debugPrint('>>> [STARTUP] 配置加载失败，使用默认配置: $e');
  }

  // 恢复上次播放会话
  final audio = container.read(audioServiceProvider);
  await audio.restoreSession();

  runApp(UncontrolledProviderScope(
    container: container,
    child: ViaMusicApp(),
  ));
}

/// 停服提示页面
class _ShutdownApp extends StatelessWidget {
  final String message;
  const _ShutdownApp({required this.message});

  @override
  Widget build(BuildContext context) {
    // 延迟 2 秒后退出
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        // 关闭应用
        if (Platform.isAndroid || Platform.isIOS) {
          SystemNavigator.pop();
        } else {
          exit(0);
        }
      });
    });

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '应用将在 2 秒后退出...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
