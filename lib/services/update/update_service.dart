// 更新服务：编排「检查更新 → 匹配平台产物 → 下载 → 安装」
// 依赖通过构造器注入（参考 SyncService），便于 fake 子类单测

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/app_info.dart';
import 'device_target.dart';
import 'github_release_client.dart';
import 'update_models.dart';
import 'version_compare.dart';

/// 更新服务
class UpdateService {
  final GitHubReleaseClient _client;
  final AppInfo _appInfo;

  /// 设备运行目标提供者（默认 getDeviceTarget，测试可注入固定值）
  final Future<DeviceTarget?> Function() _targetProvider;

  /// 下载目录提供者（默认应用文档目录，测试可注入临时目录）
  final Future<Directory> Function() _downloadDirProvider;

  UpdateService({
    required GitHubReleaseClient client,
    AppInfo? appInfo,
    Future<DeviceTarget?> Function()? targetProvider,
    Future<Directory> Function()? downloadDirProvider,
  })  : _client = client,
        _appInfo = appInfo ?? AppInfo(),
        _targetProvider = targetProvider ?? getDeviceTarget,
        _downloadDirProvider =
            downloadDirProvider ?? getApplicationSupportDirectory;

  /// 检查更新：
  /// - 无 release / 网络失败 → failure
  /// - 远程版本不高于当前 → upToDate
  /// - 有新版且匹配到当前平台+架构 → available
  /// - 有新版但平台/架构无产物（如 Linux）→ noAsset
  Future<UpdateCheckResult> checkForUpdates() async {
    final current = await _appInfo.version;
    final release = await _client.fetchLatestRelease();
    if (release == null || release.tagName.isEmpty) {
      return UpdateCheckResult.failure('检查更新失败，请稍后重试', currentVersion: current);
    }
    if (!isNewer(release.version, current)) {
      return UpdateCheckResult.upToDate(current);
    }

    // 有新版本：按当前设备运行目标（平台+架构）匹配产物
    final target = await _targetProvider();
    ReleaseAsset? asset;
    if (target != null) {
      for (final a in release.assets) {
        if (a.platform == target.platform && a.arch == target.arch) {
          asset = a;
          break;
        }
      }
    }
    if (asset == null) {
      // 平台无对应产物（如 Linux）或架构缺失 → 跳转 Release 页手动下载
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

  /// 桌面端（macOS/Windows）自动替换安装：
  /// 打开安装包（Windows 解压 zip / macOS 挂载 dmg）→ detached 启动替换脚本
  /// （延迟 → 杀旧进程/替换 .app → 重启）。
  /// 返回 true 表示脚本已成功拉起，调用方随即退出当前应用交由脚本收尾。
  Future<bool> installDesktopUpdate(ReleaseAsset asset) async {
    try {
      final dir = await _downloadDirProvider();
      final saveDir = Directory('${dir.path}/updates');
      final packagePath = '${saveDir.path}/${asset.name}';
      final package = File(packagePath);
      // 未下载完整则失败（依赖弹窗内先完成下载）
      if (!package.existsSync() || package.lengthSync() != asset.size) {
        return false;
      }

      // 解包目录：updates/<产物名去扩展名>/（存在则先清理避免残留）
      final extractDir =
          Directory(packagePath.replaceFirst(RegExp(r'\.(zip|dmg)$'), ''));
      if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
      extractDir.createSync(recursive: true);

      // 定位安装物 + 当前运行位置（macOS 按 .app / Windows 按 exe）
      final String newArtifact; // macOS 为新 .app 路径；Windows 为新 exe 所在目录
      final String currentDir; // 目标安装目录（.app 所在 / exe 所在）
      final String exeName; // Windows 重启用的 exe 名；macOS 忽略
      if (Platform.isMacOS) {
        // dmg 为只读镜像：挂载到临时挂载点，再从挂载点取 .app
        final mountDir = Directory('${extractDir.path}/mnt');
        mountDir.createSync(recursive: true);
        final attach = await Process.run('hdiutil', [
          'attach',
          packagePath,
          '-nobrowse',
          '-mountpoint',
          mountDir.path,
        ]);
        if (attach.exitCode != 0) {
          debugPrint('[Update] 挂载 dmg 失败: ${attach.stderr}');
          return false;
        }
        final app = mountDir
            .listSync()
            .whereType<Directory>()
            .where((d) => d.path.endsWith('.app'))
            .firstOrNull;
        if (app == null) {
          // 挂载成功但没找到 .app：先卸载避免残留挂载
          await Process.run('hdiutil', ['detach', mountDir.path]);
          return false;
        }
        newArtifact = app.path;
        // 可执行文件路径 …/Contents/MacOS/<bin>，上溯三级得到 .app bundle 目录
        currentDir = File(Platform.resolvedExecutable).parent.parent.parent.path;
        exeName = '';
      } else if (Platform.isWindows) {
        if (!await _extractZip(packagePath, extractDir.path)) return false;
        final exe = extractDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.exe'))
            .firstOrNull;
        if (exe == null) return false;
        newArtifact = extractDir.path;
        currentDir = File(Platform.resolvedExecutable).parent.path;
        exeName = File(Platform.resolvedExecutable).uri.pathSegments.last;
      } else {
        return false;
      }

      // 写替换脚本并 detached 启动，随后由调用方退出应用
      final scriptPath =
          '${extractDir.path}/${Platform.isWindows ? 'updater.bat' : 'updater.sh'}';
      File(scriptPath).writeAsStringSync(buildUpdaterScript(
        platform: Platform.isWindows ? assetPlatformWindows : assetPlatformMacos,
        newArtifact: newArtifact,
        currentDir: currentDir,
        exeName: exeName,
      ));
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', scriptPath]);
      } else {
        await Process.start('sh', [scriptPath]);
      }
      return true;
    } catch (e) {
      debugPrint('[Update] 桌面端自动替换安装失败: $e');
      return false;
    }
  }

  /// 解压 zip 到目标目录（Windows 用 PowerShell Expand-Archive；macOS 走 dmg 挂载）
  Future<bool> _extractZip(String zipPath, String destDir) async {
    try {
      if (!Platform.isWindows) return false;
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Expand-Archive -LiteralPath "$zipPath" -DestinationPath "$destDir" -Force',
      ]);
      if (result.exitCode != 0) {
        debugPrint('[Update] 解压失败: ${result.stderr}');
      }
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('[Update] 解压安装包异常: $e');
      return false;
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
      // 原生侧安装失败（未授权/文件不存在/FileProvider 路径不匹配/无安装器），打印明细便于定位
      debugPrint('[Update] 拉起安装器失败: code=${e.code}, message=${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Update] 拉起安装器异常: $e');
      return false;
    }
  }

  /// 是否已授权"安装未知应用"（Android 8+ 安装 APK 的前提；非 Android 视为已授权）
  Future<bool> hasUnknownSourcePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await const MethodChannel('joy_tune/install')
              .invokeMethod<bool>('hasUnknownSourcePermission') ??
          true;
    } catch (e) {
      debugPrint('[Update] 查询安装授权失败: $e');
      return true; // 查询失败不阻断，交给安装步骤实际判断
    }
  }

  /// 跳转系统"允许安装未知应用"设置页让用户授权
  Future<void> openUnknownSourceSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await const MethodChannel('joy_tune/install')
          .invokeMethod('openUnknownSourceSettings');
    } catch (e) {
      debugPrint('[Update] 打开安装授权设置失败: $e');
    }
  }
}

/// 生成桌面端替换脚本内容（纯函数，便于单测断言关键命令）
///
/// macOS（updater.sh）：延迟等旧进程退出 → 清旧 .app → ditto 拷新 .app → open 重启
/// Windows（updater.bat）：延迟 → taskkill 强杀旧进程 → xcopy 整目录覆盖 → start 重启
String buildUpdaterScript({
  required String platform,
  required String newArtifact,
  required String currentDir,
  required String exeName,
}) {
  // Windows：exe 名与目标目录固定，覆盖同目录文件即可
  if (platform == assetPlatformWindows) {
    return '''
@echo off
timeout /t 2 /nobreak >nul
taskkill /f /im $exeName >nul 2>&1
xcopy /y /e /i "$newArtifact" "$currentDir" >nul
start "" "$currentDir\\$exeName"
del "%~f0"
''';
  }
  // macOS：仅清目标目录下的 .app（避免误删同目录其它文件），保留新 .app 名；
  // newArtifact 在 dmg 挂载点内，替换后 detach 挂载并清理临时目录。
  // 注意：shell 命令替换 $() 与变量需转义为 \$( / \$，避免被 Dart 当字符串插值
  return '''
#!/bin/sh
sleep 2
MOUNT="\$(dirname "$newArtifact")"
TMPROOT="\$(dirname "\$MOUNT")"
find "$currentDir" -maxdepth 1 -name "*.app" -exec rm -rf {} +
ditto "$newArtifact" "$currentDir/\$(basename "$newArtifact")"
open "$currentDir/\$(basename "$newArtifact")"
hdiutil detach "\$MOUNT" >/dev/null 2>&1
rm -rf "\$TMPROOT"
''';
}
