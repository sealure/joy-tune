// 下载路径工具单元测试（纯函数，无平台通道）

import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/utils/download_path.dart';

void main() {
  group('sanitizeFolderName', () {
    test('拼接 歌名-歌手，过滤 Windows 非法字符', () {
      expect(sanitizeFolderName('晴天', '周杰伦'), '晴天-周杰伦');
      expect(sanitizeFolderName('A/B:C', 'x'), 'A_B_C-x');
      expect(sanitizeFolderName('夜<曲>?', '周杰伦'), '夜_曲_-周杰伦');
    });

    test('去除尾随点/空格，避免 Windows 目录问题', () {
      expect(sanitizeFolderName('晴天.', '周杰伦'), '晴天-周杰伦');
      expect(sanitizeFolderName('晴天', '周杰伦  '), '晴天-周杰伦');
    });

    test('空名回退"未命名歌曲"', () {
      expect(sanitizeFolderName('', ''), '未命名歌曲');
      expect(sanitizeFolderName('***', ''), '未命名歌曲');
    });
  });
}