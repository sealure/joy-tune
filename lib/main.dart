// 应用入口
// 初始化所有服务，检查配置和停服开关

import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'db/daos/settings_dao.dart';
import 'db/legacy_prefs.dart';
import 'firebase_options.dart';
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
/// 存储于本地 SQLite（local_settings），优先复用已存 ID，
/// 旧 SharedPreferences 中已有值则回退迁移，取不到系统 ID 时回退到随机 UUID。
Future<String> _getDeviceId(SettingsDao settingsDao) async {
  var deviceId = await settingsDao.get('device_id');
  if (deviceId != null && deviceId.isNotEmpty) {
    // 已有则复用，避免升级后设备被当成新设备
    return deviceId;
  }

  // 旧 SharedPreferences 回退迁移（SQLite 化前的老用户连续性）
  final prefs = await SharedPreferences.getInstance();
  final legacy = prefs.getString('device_id');
  if (legacy != null && legacy.isNotEmpty) {
    await settingsDao.set('device_id', legacy);
    return legacy;
  }

  // 首次生成：优先使用系统稳定 ID
  const uuid = Uuid();
  final systemId = await _getSystemDeviceId();
  deviceId = systemId ?? uuid.v4();
  await settingsDao.set('device_id', deviceId);
  return deviceId;
}

/// 获取系统级稳定设备 ID
/// Android 返回 ANDROID_ID（8+ 卸载重装可能变化，系统备份恢复则不变）；
/// iOS 返回 identifierForVendor。取不到返回 null，由调用方回退到随机 UUID。
Future<String?> _getSystemDeviceId() async {
  try {
    const channel = MethodChannel('joy_tune/device_id');
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

  // 初始化 Firebase（flutterfire 生成的各平台统一配置；Google 登录依赖）
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // 初始化失败不阻塞启动（登录功能不可用，其余功能正常）
    debugPrint('>>> [STARTUP] Firebase 初始化失败: $e');
  }

  // 初始化 media_kit（加载 libmpv）
  MediaKit.ensureInitialized();

  // 初始化旧 SharedPreferences 存储（SQLite 迁移的数据源）
  await LegacyPrefs.initialize();

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

  // ── 本地数据库预热 + 旧数据迁移 ──
  try {
    // 打开 SQLite（drift），首次访问触发建表
    await container.read(databaseProvider).customSelect('SELECT 1').get();
    // 旧 SharedPreferences 数据迁入 SQLite（收藏/搜索历史/播放会话）
    await container.read(legacyPrefsMigratorProvider).run();
  } catch (e) {
    debugPrint('>>> [STARTUP] 本地数据库初始化失败: $e');
  }

  // ── 启动后台同步任务（立即首扫 + 周期；游客态自动跳过推送）──
  container.read(syncServiceProvider).start();

  // ── 启动后台网络初始化（设备上报 + 停服检查 + 启动配置），不阻塞 UI ──
  // 原实现把这些请求在 runApp 前串行 await，后端慢/不可用时首屏被卡住（各接口超时最长 10s+15s）；
  // 现在全部移入后台执行，UI 立即进入欢迎页，结果到位后再拦截停服 / 应用音源配置。
  final settingsDao = container.read(settingsDaoProvider);
  // 设备 ID 为本地生成（SQLite + 系统标识），快速，保留 await
  final deviceId = await _getDeviceId(settingsDao);
  unawaited(_runBackgroundStartup(container, deviceId));

  // 恢复上次播放会话（本地操作，毫秒级）
  final audio = container.read(audioServiceProvider);
  await audio.restoreSession();

  runApp(UncontrolledProviderScope(
    container: container,
    child: ViaMusicApp(),
  ));
}

/// 后台启动网络初始化：设备上报 → 停服检查 → 启动配置（音源/默认音质）
/// 全部不 await 于 runApp 之前，任一失败静默忽略，用本地默认配置兜底。
/// 每次冷启动仅执行一轮，运行期不再重复。
Future<void> _runBackgroundStartup(ProviderContainer container, String deviceId) async {
  try {
    final backendClient = container.read(backendClientProvider);

    // 1. 上报设备（写入后端 devices 表，作为停服定位依据；幂等，失败静默忽略）
    await backendClient.reportDevice(
      deviceId: deviceId,
      platform: _platformName(),
      // 版本号统一从 package_info_plus 读取（与设置页/自动更新一致）
      appVersion: await container.read(appInfoProvider).version,
    );

    // 2. 检查停服开关（依赖上一步设备已在 devices 表）；结果写入 provider，
    //    由 app 层全局监控，停服时自动弹全屏遮罩并定时退出，无需阻塞启动
    final shutdownResult = await backendClient.checkShutdown(deviceId: deviceId);
    container.read(shutdownResultProvider.notifier).state = shutdownResult;
    if (shutdownResult.enabled) {
      debugPrint('>>> [STARTUP] 检测到停服: ${shutdownResult.message}');
      return; // 已停服，无需再拉取启动配置
    }

    // 3. 一次性拉取启动配置（音源列表 + system_configs），FutureProvider 缓存供运行期复用
    final bootstrap = await container.read(startupConfigProvider.future);
    final client = container.read(gdMusicClientProvider);
    final musicSources = bootstrap.musicSources;
    // 应用音源：music_sources 表配置优先；接口失败/为空则回落客户端内置列表
    if (musicSources != null && musicSources.sources.isNotEmpty) {
      client.configureMusicSources(musicSources.sources);
      debugPrint('>>> [STARTUP] 音源配置已应用: ${client.enabledSources}');
    }

    // 默认音质：把持久化值同步到播放客户端（设置页「默认音质」修改后也会重新写入）
    final bitrateRaw = await container.read(settingsDaoProvider).get('default_bitrate');
    final bitrate = bitrateRaw != null ? int.tryParse(bitrateRaw) : null;
    if (bitrate != null) {
      client.defaultBitrate = bitrate;
      debugPrint('>>> [STARTUP] 默认音质已加载: ${bitrate}kbps');
    }
  } catch (e) {
    debugPrint('>>> [STARTUP] 初始化失败，使用默认配置: $e');
  }
}
