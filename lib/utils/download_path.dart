// 下载目录解析工具（平台相关）
// Android：走 MethodChannel 获取公共 Download 目录（可被文件管理器等 App 访问）；
// 桌面端（Windows/macOS/Linux）：path_provider 的 getDownloadsDirectory()。
// 统一返回「下载根目录」，下载目录 = 根目录/JoyTune/<歌名>-<歌手>/。

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Android 原生通道（与 MainActivity.kt 一致）
const _channelName = 'joy_tune/download_dir';

/// 获取系统下载根目录（不创建）。失败回退应用文档目录，保证功能可用。
Future<Directory> getDownloadsRoot() async {
  // Android：原生层取公共 Download 目录（getExternalStoragePublicDirectory）
  if (Platform.isAndroid) {
    try {
      final path = await const MethodChannel(_channelName)
          .invokeMethod<String>('getDownloadDir');
      if (path != null && path.isNotEmpty) {
        return Directory(path);
      }
    } catch (e) {
      print('[DownloadDir] Android 获取下载目录失败: $e');
    }
  } else {
    // 桌面端（Windows/macOS/Linux）
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
    } catch (e) {
      print('[DownloadDir] 桌面端获取下载目录失败: $e');
    }
  }
  // 兜底：应用文档目录
  final doc = await getApplicationDocumentsDirectory();
  return doc;
}

/// 将歌曲名+歌手整理为安全文件夹名（去除平台非法字符与首尾分隔符，收敛为
/// 单层 `歌名-歌手`），空路径片段回退"未命名歌曲"。
///
/// 处理顺序：1) 点号直接删（部分文件系统/系统对点有特殊语义，避免"./路径"等）；
/// 2) Windows 非法字符 `<>:"/\|?*` 及控制字符替换为下划线；3) 合并连续下划线；
/// 4) 去除首尾的 `-/_/空白`（避免 `-.`、尾随空格等导致目录不可见/不可访问）。
String sanitizeFolderName(String name, String artist) {
  // 点号直接删除
  var raw = '$name-$artist'.replaceAll('.', '');
  // 非法字符与控制字符 → 下划线
  raw = raw.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  // 合并连续下划线
  raw = raw.replaceAll(RegExp(r'_+'), '_');
  // 去除首尾分隔符/下划线/空白
  raw = raw.replaceAll(RegExp(r'^[-_ ]+|[-_ ]+$'), '').trim();
  return raw.isEmpty ? '未命名歌曲' : raw;
}

/// 判断 Android 是否已有写公共下载目录所需的存储权限（桌面端恒 true）
Future<bool> hasDownloadWritePermission() async {
  if (!Platform.isAndroid) return true;
  try {
    return await const MethodChannel(_channelName)
            .invokeMethod<bool>('hasStoragePermission') ??
        true;
  } catch (e) {
    print('[DownloadDir] 查询存储权限失败: $e');
    return true;
  }
}

/// 请求 Android 存储写入权限（系统弹窗 / 跳转系统设置，具体见原生实现）
Future<void> requestDownloadWritePermission() async {
  if (!Platform.isAndroid) return;
  try {
    await const MethodChannel(_channelName)
        .invokeMethod('requestStoragePermission');
  } catch (e) {
    print('[DownloadDir] 请求存储权限失败: $e');
  }
}