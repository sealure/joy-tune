// 版本比较工具单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/services/update/version_compare.dart';

void main() {
  group('stripV', () {
    test('剥离 v 前缀', () {
      expect(stripV('v0.0.2'), '0.0.2');
      expect(stripV('V0.0.2'), '0.0.2');
    });

    test('无 v 前缀原样保留', () {
      expect(stripV('0.0.2'), '0.0.2');
    });

    test('剥离 +build 元数据', () {
      expect(stripV('v0.0.1+1'), '0.0.1');
    });

    test('剥离 -prerelease 元数据', () {
      expect(stripV('v0.0.2-beta.1'), '0.0.2');
    });
  });

  group('compareVersion', () {
    test('分段数值比较（非字典序）', () {
      expect(compareVersion('0.0.10', '0.0.2'), 1);
      expect(compareVersion('0.0.2', '0.0.10'), -1);
    });

    test('相同版本相等', () {
      expect(compareVersion('0.0.1', '0.0.1'), 0);
    });

    test('缺位补 0', () {
      expect(compareVersion('0.1', '0.1.0'), 0);
    });

    test('主版本比较', () {
      expect(compareVersion('1.0.0', '0.9.9'), 1);
    });

    test('混合 v 前缀比较', () {
      expect(compareVersion('v0.0.2', '0.0.1'), 1);
    });

    test('非法段不抛异常', () {
      // 非数字段按 0 处理，不抛异常
      expect(() => compareVersion('0.a.b', '0.0.1'), returnsNormally);
    });
  });

  group('isNewer', () {
    test('远程更高为新版本', () {
      expect(isNewer('0.0.2', '0.0.1'), true);
    });

    test('远程不高于当前则非新版本', () {
      expect(isNewer('0.0.1', '0.0.2'), false);
    });

    test('版本相等非新版本', () {
      expect(isNewer('0.0.1', '0.0.1'), false);
    });
  });
}
