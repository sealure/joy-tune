// 自动更新模型单元测试：ABI 解析 + changelog 解析
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/services/update/update_models.dart';

void main() {
  group('parseAbiFromName', () {
    test('解析新命名产物的 ABI', () {
      expect(
        parseAbiFromName('joy-tune_0.0.2_arm64-v8a.apk'),
        'arm64-v8a',
      );
      expect(
        parseAbiFromName('joy-tune_0.0.2_armeabi-v7a.apk'),
        'armeabi-v7a',
      );
      expect(
        parseAbiFromName('joy-tune_0.0.2_x86_64.apk'),
        'x86_64',
      );
    });

    test('旧命名无法解析（安全过滤）', () {
      expect(parseAbiFromName('via_music_0.0.1.apk'), isNull);
    });
  });

  group('parseAssetInfo', () {
    test('解析 Android APK 产物', () {
      final info = parseAssetInfo('joy-tune_0.0.11_arm64-v8a.apk');
      expect(info, isNotNull);
      expect(info!.$1, assetPlatformAndroid);
      expect(info.$2, 'arm64-v8a');
    });

    test('解析 macOS dmg 产物（arm64 / x64）', () {
      final arm = parseAssetInfo('joy-tune_0.0.11_macos_arm64.dmg');
      expect(arm, isNotNull);
      expect(arm!.$1, assetPlatformMacos);
      expect(arm.$2, 'arm64');

      final x64 = parseAssetInfo('joy-tune_0.0.11_macos_x64.dmg');
      expect(x64, isNotNull);
      expect(x64!.$1, assetPlatformMacos);
      expect(x64.$2, 'x64');
    });

    test('解析 Windows zip 产物（x64）', () {
      final info = parseAssetInfo('joy-tune_0.0.11_windows_x64.zip');
      expect(info, isNotNull);
      expect(info!.$1, assetPlatformWindows);
      expect(info.$2, 'x64');
    });

    test('非法命名无法解析（安全过滤）', () {
      // 旧命名 / 缺架构段 / 不支持的平台 / 无关文件
      expect(parseAssetInfo('via_music_0.0.1.apk'), isNull);
      expect(parseAssetInfo('joy-tune_0.0.11_macos.dmg'), isNull);
      expect(parseAssetInfo('joy-tune_0.0.11_linux_x64.dmg'), isNull);
      expect(parseAssetInfo('readme.md'), isNull);
    });

    test('parseAbiFromName 对桌面端产物返回 null', () {
      expect(parseAbiFromName('joy-tune_0.0.11_macos_arm64.dmg'), isNull);
      expect(parseAbiFromName('joy-tune_0.0.11_windows_x64.zip'), isNull);
    });
  });

  group('ChangelogItem.parse', () {
    test('解析 [新增] 前缀为新增类型', () {
      final items = ChangelogItem.parse('[新增] 支持按 ABI 拆分');
      expect(items.length, 1);
      expect(items.first.type, ChangelogType.feat);
      expect(items.first.text, '支持按 ABI 拆分');
    });

    test('剥离列表前缀后解析 [修复]', () {
      final items = ChangelogItem.parse('- [修复] 修复离线卡顿');
      expect(items.length, 1);
      expect(items.first.type, ChangelogType.fix);
      expect(items.first.text, '修复离线卡顿');
    });

    test('解析 [优化] 前缀', () {
      final items = ChangelogItem.parse('[优化] 启动提速');
      expect(items.length, 1);
      expect(items.first.type, ChangelogType.opt);
      expect(items.first.text, '启动提速');
    });

    test('无前缀普通行降级为普通文本', () {
      final items = ChangelogItem.parse('## 更新日志');
      expect(items.length, 1);
      expect(items.first.type, ChangelogType.plain);
      expect(items.first.text, '## 更新日志');
    });

    test('空行跳过', () {
      final items = ChangelogItem.parse('[新增] 功能\n\n[修复] 问题\n');
      expect(items.length, 2);
      expect(items.first.type, ChangelogType.feat);
      expect(items.last.type, ChangelogType.fix);
    });

    test('混合多行逐条解析', () {
      final items = ChangelogItem.parse(
        '[新增] 支持按 CPU 架构拆分安装包\n[修复] 修复离线回放卡顿\n[优化] 启动速度优化',
      );
      expect(items.length, 3);
      expect(items.map((i) => i.type).toList(), [
        ChangelogType.feat,
        ChangelogType.fix,
        ChangelogType.opt,
      ]);
    });
  });

  group('pickLatestRelease', () {
    // 构造一个 release JSON（字段与 GitHub API 一致）
    Map<String, dynamic> makeRelease(String tag,
        {bool draft = false, bool prerelease = false}) {
      return {
        'tag_name': tag,
        'html_url': 'https://github.com/sealure/joy-tune/releases/tag/$tag',
        'body': '',
        'draft': draft,
        'prerelease': prerelease,
        'assets': <dynamic>[],
      };
    }

    test('并行发版时按版本号取最高（不依赖发布时间）', () {
      final list = <dynamic>[makeRelease('v0.0.8'), makeRelease('v0.0.9')];
      final latest = pickLatestRelease(list);
      expect(latest?.version, '0.0.9');
    });

    test('过滤 draft 与 prerelease', () {
      final list = <dynamic>[
        makeRelease('v0.0.10', draft: true),
        makeRelease('v0.0.11', prerelease: true),
        makeRelease('v0.0.9'),
      ];
      final latest = pickLatestRelease(list);
      expect(latest?.version, '0.0.9');
    });

    test('空列表或全部草稿返回 null', () {
      expect(pickLatestRelease(<dynamic>[]), isNull);
      expect(
        pickLatestRelease(<dynamic>[makeRelease('v0.0.1', draft: true)]),
        isNull,
      );
    });
  });
}
