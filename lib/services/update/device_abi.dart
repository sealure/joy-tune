// 设备 ABI 检测：Android 返回 Build.SUPPORTED_ABIS 首项，其余平台返回 null
// 用于自动更新按 CPU 架构匹配对应的 APK 产物

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 获取设备 ABI（arm64-v8a / armeabi-v7a / x86_64）
///
/// 非 Android 或通道失败返回 null（桌面端走"跳转 Release 页手动下载"降级）。
/// 复用现有 joy_tune/device_id MethodChannel 的 getSupportedAbi 方法。
Future<String?> getDeviceAbi() async {
  if (!Platform.isAndroid) return null;
  try {
    return await const MethodChannel('joy_tune/device_id')
        .invokeMethod<String>('getSupportedAbi');
  } catch (e) {
    debugPrint('[Update] 获取设备 ABI 失败: $e');
    return null;
  }
}
