// GitHub 访问镜像 URL 重写单元测试
// 验证 download_mirrors.dart 的候选生成与安全约定：
// 仅可代理的 GitHub 域名（github.com / api.github.com）才拼镜像，
// 其它域名不经过代理

import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/services/update/download_mirrors.dart';

// 用到的示例直链：模拟真实 release 资产地址与 Release API 地址
const _apkUrl =
    'https://github.com/sealure/joy-tune/releases/download/v0.0.2/'
    'joy-tune_0.0.2_arm64-v8a.apk';
const _apiUrl =
    'https://api.github.com/repos/sealure/joy-tune/releases?per_page=30';

void main() {
  group('rewriteToMirror', () {
    test('github.com 直链 → 拼接镜像前缀', () {
      final rewritten =
          rewriteToMirror(_apkUrl, 'https://gh-proxy.com');
      expect(rewritten, 'https://gh-proxy.com/$_apkUrl');
    });

    test('api.github.com 直链（含 query）→ 拼接镜像前缀', () {
      final rewritten =
          rewriteToMirror(_apiUrl, 'https://gh-proxy.com');
      expect(rewritten, 'https://gh-proxy.com/$_apiUrl');
    });
    test('镜像带尾斜杠时去重，避免双斜杠', () {
      final rewritten =
          rewriteToMirror('https://github.com/a/b', 'https://gh-proxy.com/');
      expect(rewritten, 'https://gh-proxy.com/https://github.com/a/b');
    });

    test('非 GitHub 直链返回 null（不经过镜像）', () {
      expect(rewriteToMirror('https://example.com/a.apk', 'https://gh-proxy.com'),
          isNull);
      expect(rewriteToMirror('http://github.com/a/b', 'https://gh-proxy.com'),
          isNull);
    });
  });

  group('candidatesFor', () {
    test('github 直链：直连在前，镜像按优先级依次在后', () {
      final candidates = candidatesFor(_apkUrl);
      // 候选数 = 原直连 + 镜像数
      expect(candidates.length, downloadMirrors.length + 1);
      expect(candidates.first, _apkUrl);
      expect(candidates[1], startsWith('https://gh-proxy.com/'));
      expect(candidates.last, startsWith('https://ghproxy.net/'));
    });

    test('api.github.com 候选：取 apiMirrors，规避拒绝 API 的 ghproxy.net', () {
      final candidates = candidatesFor(_apiUrl, mirrors: apiMirrors);
      // 候选数 = 原直连 + apiMirrors 数（ghproxy.net 仅代理文件，不在其中）
      expect(candidates.length, apiMirrors.length + 1);
      expect(candidates.first, _apiUrl);
      expect(candidates[1], startsWith('https://gh-proxy.com/'));
      expect(candidates.any((c) => c.startsWith('https://ghproxy.net/')), isFalse);
    });

    test('非 GitHub 直链：仅原 URL（不经过任何镜像）', () {
      expect(candidatesFor('https://example.com/a.apk'),
          ['https://example.com/a.apk']);
    });
  });
}
