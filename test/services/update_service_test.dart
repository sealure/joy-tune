// 更新服务单元测试
// 用 fake GitHubReleaseClient（子类重写方法）+ AppInfo 注入固定版本号，
// 验证检查更新各分支与下载幂等逻辑

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

ReleaseAsset _asset(String abi) => ReleaseAsset(
      name: 'joy-tune_0.0.2_$abi.apk',
      browserDownloadUrl: 'https://example.com/joy-tune_0.0.2_$abi.apk',
      size: 100,
      abi: abi,
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

  UpdateService build({String version = '0.0.1', String? abi = 'arm64-v8a'}) {
    return UpdateService(
      client: client,
      appInfo: AppInfo(versionOverride: version),
      abiProvider: () async => abi,
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
      client.release = _release('v0.0.1', assets: [_asset('arm64-v8a')]);
      final result = await build(version: '0.0.1').checkForUpdates();
      expect(result.hasUpdate, isFalse);
      expect(result.release, isNull);
    });

    test('新版本 + ABI 命中 → available', () async {
      client.release = _release('v0.0.2', assets: [_asset('arm64-v8a')]);
      final result = await build(version: '0.0.1').checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.asset?.abi, 'arm64-v8a');
      expect(result.noAsset, isFalse);
    });

    test('新版本 + ABI 无产物 → noAsset', () async {
      client.release = _release('v0.0.2', assets: [_asset('x86_64')]);
      final result = await build(version: '0.0.1', abi: 'arm64-v8a').checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.noAsset, isTrue);
      expect(result.asset, isNull);
    });

    test('abiProvider 返回 null（模拟桌面）→ noAsset', () async {
      client.release = _release('v0.0.2', assets: [_asset('arm64-v8a')]);
      final result = await build(version: '0.0.1', abi: null).checkForUpdates();
      expect(result.hasUpdate, isTrue);
      expect(result.noAsset, isTrue);
    });
  });

  group('download', () {
    test('已存在完整文件则跳过下载（幂等）', () async {
      client.release = _release('v0.0.2', assets: [_asset('arm64-v8a')]);
      final saveDir = Directory('${tempDir.path}/updates');
      await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/joy-tune_0.0.2_arm64-v8a.apk';
      File(savePath).writeAsBytesSync(List.filled(100, 0)); // 与 size=100 一致

      final path = await build(version: '0.0.1').download(_asset('arm64-v8a'));
      expect(client.downloadCalls, 0);
      expect(path, savePath);
    });

    test('残缺文件则重新下载覆盖', () async {
      client.release = _release('v0.0.2', assets: [_asset('arm64-v8a')]);
      final saveDir = Directory('${tempDir.path}/updates');
      await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/joy-tune_0.0.2_arm64-v8a.apk';
      File(savePath).writeAsBytesSync(List.filled(10, 0)); // size 不一致

      final path = await build(version: '0.0.1').download(_asset('arm64-v8a'));
      expect(client.downloadCalls, 1);
      expect(path, savePath);
    });

    test('下载失败返回 null（静默）', () async {
      client.downloadSuccess = false;
      final path = await build(version: '0.0.1').download(_asset('arm64-v8a'));
      expect(path, isNull);
    });
  });
}
