// 设备运行目标检测：当前平台 + 架构，用于自动更新按平台匹配产物
// Android 复用 device_abi.dart 的 getDeviceAbi；macOS/Windows 分别读 uname / 环境变量。

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'device_abi.dart';
import 'update_models.dart';

/// 当前设备可运行的产物目标（平台 + 架构）
class DeviceTarget {
  /// 平台标识（与产物命名平台段一致，见 assetPlatform* 常量）
  final String platform;

  /// 架构（Android 为 ABI 串如 arm64-v8a；桌面端为 arm64 / x64）
  final String arch;

  const DeviceTarget({required this.platform, required this.arch});
}

/// 获取当前设备运行目标（平台 + 架构），供 checkForUpdates 匹配产物
///
/// - Android：Build.SUPPORTED_ABIS 首项（arm64-v8a 等）
/// - macOS：uname -m → arm64 / x86_64（归一为 x64）
/// - Windows：PROCESSOR_ARCHITECTURE → AMD64（归一 x64）/ ARM64
/// - 其余平台（Linux 等）或探测失败 → null（走跳转 Release 页降级）
Future<DeviceTarget?> getDeviceTarget() async {
  if (Platform.isAndroid) {
    final abi = await getDeviceAbi();
    if (abi == null) return null;
    return DeviceTarget(platform: assetPlatformAndroid, arch: abi);
  }
  if (Platform.isMacOS) {
    final arch = await _macArch();
    if (arch == null) return null;
    return DeviceTarget(platform: assetPlatformMacos, arch: arch);
  }
  if (Platform.isWindows) {
    final arch = _windowsArch();
    if (arch == null) return null;
    return DeviceTarget(platform: assetPlatformWindows, arch: arch);
  }
  return null;
}

/// macOS 架构：uname -m → arm64 / x86_64（归一为 x64）；探测失败返回 null
Future<String?> _macArch() async {
  try {
    final result = await Process.run('uname', ['-m']);
    if (result.exitCode != 0) return null;
    final arch = (result.stdout as String).trim();
    return arch == 'x86_64' ? 'x64' : arch;
  } catch (e) {
    debugPrint('[Update] 获取 macOS 架构失败: $e');
    return null;
  }
}

/// Windows 架构：PROCESSOR_ARCHITECTURE → AMD64（归一 x64）/ ARM64
String? _windowsArch() {
  final arch = Platform.environment['PROCESSOR_ARCHITECTURE'];
  if (arch == null) return null;
  if (arch == 'AMD64') return 'x64';
  if (arch == 'ARM64') return 'arm64';
  return null;
}
