// 更新服务：编排「检查更新 → 匹配 ABI → 下载 → 安装」
// 依赖通过构造器注入（参考 SyncService），便于 fake 子类单测

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/app_info.dart';
import 'device_abi.dart';
import 'github_release_client.dart';
import 'update_models.dart';
import 'version_compare.dart';

/// 更新服务
class UpdateService {
  final GitHubReleaseClient _client;
  final AppInfo _appInfo;

  /// 设备 ABI 提供者（默认 getDeviceAbi，测试可注入固定值）
  final Future<String?> Function() _abiProvider;

  /// 下载目录提供者（默认应用文档目录，测试可注入临时目录）
  final Future<Directory> Function() _downloadDirProvider;

  UpdateService({
    required GitHubReleaseClient client,
    AppInfo? appInfo,
    Future<String?> Function()? abiProvider,
    Future<Directory> Function()? downloadDirProvider,
  })  : _client = client,
        _appInfo = appInfo ?? AppInfo(),
        _abiProvider = abiProvider ?? getDeviceAbi,
        _downloadDirProvider =
            downloadDirProvider ?? getApplicationSupportDirectory;

  /// 检查更新：
  /// - 无 release / 网络失败 → failure
  /// - 远程版本不高于当前 → upToDate
  /// - 有新版且匹配到当前 ABI → available
  /// - 有新版但 ABI 无产物（桌面端/模拟器）→ noAsset
  Future<UpdateCheckResult> checkForUpdates() async {
    final current = await _appInfo.version;
    final release = await _client.fetchLatestRelease();
    if (release == null || release.tagName.isEmpty) {
      return UpdateCheckResult.failure('检查更新失败，请稍后重试', currentVersion: current);
    }
    if (!isNewer(release.version, current)) {
      return UpdateCheckResult.upToDate(current);
    }

    // 有新版本：按当前设备 ABI 匹配产物
    final abi = await _abiProvider();
    ReleaseAsset? asset;
    if (abi != null) {
      for (final a in release.assets) {
        if (a.abi == abi) {
          asset = a;
          break;
        }
      }
    }
    if (asset == null) {
      // 桌面端（abi 为 null）或该 ABI 无产物 → 跳转 Release 页手动下载
      return UpdateCheckResult.noAsset(release, current);
    }
    return UpdateCheckResult.available(release, asset, current);
  }

  /// 下载 APK 到 `应用支持目录/updates/<name>`；已存在完整文件（长度==size）则跳过
  ///
  /// 说明：用 getApplicationSupportDirectory()（Android 返回 files 目录），
  /// 与 file_paths.xml 的 `<files-path path="updates/">` 精确匹配，供 FileProvider 授权系统安装器读取。
  Future<String?> download(
    ReleaseAsset asset, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dir = await _downloadDirProvider();
      final saveDir = Directory('${dir.path}/updates');
      await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/${asset.name}';
      final file = File(savePath);
      // 幂等：已存在且大小一致则跳过下载（避免重复下载；断点续传降级为重新下载）
      if (file.existsSync() && file.lengthSync() == asset.size) {
        return savePath;
      }
      return await _client.downloadAsset(
        asset.browserDownloadUrl,
        savePath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      debugPrint('[Update] 准备下载目录失败: $e');
      return null;
    }
  }

  /// 拉起系统安装器（Android 经 MethodChannel joy_tune/install → FileProvider + ACTION_VIEW）
  Future<bool> installApk(String path) async {
    if (!Platform.isAndroid) return false;
    try {
      await const MethodChannel('joy_tune/install')
          .invokeMethod('installApk', {'path': path});
      return true;
    } on PlatformException catch (e) {
      // 原生侧安装失败（文件不存在/FileProvider 路径不匹配/无安装器），打印明细便于定位
      debugPrint('[Update] 拉起安装器失败: code=${e.code}, message=${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Update] 拉起安装器异常: $e');
      return false;
    }
  }
}
