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
}
