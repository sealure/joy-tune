import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/services/google_oauth_windows.dart';

void main() {
  test('无 dart-define 时从 .oauth_local.json 兜底读取', () {
    if (!File('.oauth_local.json').existsSync()) {
      markTestSkipped('本地无 .oauth_local.json');
      return;
    }
    expect(googleDesktopClientId, isNotEmpty,
        reason: '应从 .oauth_local.json 读到 clientId');
    expect(googleDesktopClientSecret, isNotEmpty,
        reason: '应从 .oauth_local.json 读到 clientSecret');
  });
}