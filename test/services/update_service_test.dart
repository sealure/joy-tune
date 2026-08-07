// 更新服务单元测试
// 用 fake GitHubReleaseClient（子类重写方法）+ AppInfo 注入固定版本号，
// 验证检查更新各分支、桌面端产物匹配与替换脚本生成逻辑

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/services/update/device_target.dart';
import 'package:joy_tune/services/update/github_release_client.dart';
import 'package:joy_tune/services/update/update_models.dart';
import 'package:joy_tune/services/update/update_service.dart';
import 'package:joy_tune/utils/app_info.dart';

/// fake GitHub Release 客户端：返回可配置的 release，并统计下载次数
class _FakeGitHubReleaseClient extends GitHubReleaseClient {
  ReleaseInfo? release;
  int downloadCalls = 0;
  bool downloadSuccess = true;

  @override
  Future<ReleaseInfo?> fetchLatestRelease() async => release;

  @override
  Future<String?> downloadAsset(String url, String savePath,
      {void Function(int received, int total)? onProgress,
      CancelToken? cancelToken}) async {
    downloadCalls++;
    if (!downloadSuccess) throw DioException(requestOptions: RequestOptions(path: url));
    // 写一个与 release.size 一致的占位文件
    File(savePath).writeAsBytesSync(List.filled(100, 0));
    return savePath;
  }
}

/// 构造 Android APK 产物
ReleaseAsset _apkAsset(String abi) => ReleaseAsset(
      name: 'joy-tune_0.0.2_$abi.apk',
      browserDownloadUrl: 'https://example.com/joy-tune_0.0.2_$abi.apk',
      size: 100,
      platform: assetPlatformAndroid,
      arch: abi,
    );

/// 构造 macOS dmg 产物
ReleaseAsset _macDmgAsset(String arch) => ReleaseAsset(
      name: 'joy-tune_0.0.2_macos_$arch.dmg',
      browserDownloadUrl: 'https://example.com/joy-tune_0.0.2_macos_$arch.dmg',
      size: 100,
      platform: assetPlatformMacos,
      arch: arch,
    );

ReleaseInfo _release(String tag, {List<ReleaseAsset> assets = const []}) =>
    ReleaseInfo(tagName: tag, htmlUrl: 'https://github.com/sealure/joy-tune/releases', body: '', assets: assets);

void main() {
  late _FakeGitHubReleaseClient client;
  late Directory tempDir;

  setUp(() {
    client = _FakeGitHubReleaseClient();
    tempDir = Directory.systemTemp.createTempSync('update_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// 默认模拟 Android arm64-v8a 设备；测试可注入任意 DeviceTarget
  UpdateService build({
    String version = '0.0.1',
    DeviceTarget? target = const DeviceTarget(platform: assetPlatformAndroid, arch: 'arm64-v8a'),
  }) {
    return UpdateService(
      client: client,
      appInfo: AppInfo(versionOverride: version),
      targetProvider: () async => target,
      downloadDirProvider: () async => tempDir,
    );
  }

  group('checkForUpdates', () {
    test('无 release → failure', () async {
      client.release = null;
      final result = await build().checkForUpdates();
      expect(result.hasUpdate, isFalse);
      expect(result.error, isNotNull);
    });

    test('远程版本等于当前 → upToDate', () async {
      client.release = _release('v0.0.1', assets: [_apkAsset('arm64-v8a')]);
      final result = await build(version: '0.0.1').checkForUpdates();
      expect(result.hasUpdate, isFalse);
      expect(result.release, isNull);
    });

    test('Android 新版本 + ABI 命中 → available', () async {
      client.release = _release('v0.0.2', assets: [_apkAsset('arm64-v8a')]);
      final result = await build(version: '0.0.1').checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.asset?.arch, 'arm64-v8a');
      expect(result.noAsset, isFalse);
    });

    test('Android 新版本 + ABI 无产物 → noAsset', () async {
      client.release = _release('v0.0.2', assets: [_apkAsset('x86_64')]);
      final result = await build(version: '0.0.1').checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.noAsset, isTrue);
      expect(result.asset, isNull);
    });

    test('桌面端 macOS arm64 命中 dmg 产物 → available', () async {
      client.release = _release('v0.0.2', assets: [_macDmgAsset('arm64')]);
      final result = await build(
        version: '0.0.1',
        target: const DeviceTarget(platform: assetPlatformMacos, arch: 'arm64'),
      ).checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.asset?.arch, 'arm64');
      expect(result.noAsset, isFalse);
    });

    test('桌面端架构无产物（macOS x64 机只有 arm64 包）→ noAsset', () async {
      client.release = _release('v0.0.2', assets: [_macDmgAsset('arm64')]);
      final result = await build(
        version: '0.0.1',
        target: const DeviceTarget(platform: assetPlatformMacos, arch: 'x64'),
      ).checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.noAsset, isTrue);
      expect(result.asset, isNull);
    });

    test('targetProvider 返回 null（不支持平台）→ noAsset', () async {
      client.release = _release('v0.0.2', assets: [_apkAsset('arm64-v8a')]);
      final result = await build(version: '0.0.1', target: null).checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.noAsset, isTrue);
    });
  });

  group('download', () {
    test('已存在完整文件则跳过下载（幂等）', () async {
      final saveDir = Directory('${tempDir.path}/updates');
      await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/joy-tune_0.0.2_arm64-v8a.apk';
      File(savePath).writeAsBytesSync(List.filled(100, 0)); // 与 size=100 一致

      final path = await build(version: '0.0.1').download(_apkAsset('arm64-v8a'));
      expect(client.downloadCalls, 0);
      expect(path, savePath);
    });

    test('残缺文件则重新下载覆盖', () async {
      final saveDir = Directory('${tempDir.path}/updates');
      await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/joy-tune_0.0.2_arm64-v8a.apk';
      File(savePath).writeAsBytesSync(List.filled(10, 0)); // size 不一致

      final result = await build(version: '0.0.1').download(_apkAsset('arm64-v8a'));
      expect(client.downloadCalls, 1);
      expect(result, savePath);
    });

    test('下载失败返回 null（静默）', () async {
      client.downloadSuccess = false;
      final result = await build(version: '0.0.1').download(_apkAsset('arm64-v8a'));
      expect(result, isNull);
    });
  });

  group('buildUpdaterScript', () {
    test('macOS 脚本含清旧包、拷贝、挂载卸载与重启关键命令', () {
      final script = buildUpdaterScript(
        platform: assetPlatformMacos,
        newArtifact: '/tmp/updates/joy_tune.app',
        currentDir: '/Applications',
        exeName: '',
      );
      expect(script, contains('find'));
      expect(script, contains('ditto'));
      expect(script, contains('open'));
      expect(script, contains('/Applications'));
      expect(script, contains('hdiutil detach'));
    });

    test('Windows 脚本含强杀进程、覆盖与重启关键命令', () {
      final script = buildUpdaterScript(
        platform: assetPlatformWindows,
        newArtifact: r'C:\updates\release',
        currentDir: r'C:\joy_tune',
        exeName: 'joy_tune.exe',
      );
      expect(script, contains('taskkill /f /im joy_tune.exe'));
      expect(script, contains('xcopy'));
      expect(script, contains(r'start "" "C:\joy_tune\joy_tune.exe"'));
    });
  });
}