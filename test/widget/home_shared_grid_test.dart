// 首页「分享歌单」宫格 + 分享歌单列表页 widget 测试
// 验证：
//  1. 分享歌单 >6 个时宫格截断到 6 张卡片且显示「查看全部」入口
//  2. 分享歌单 ≤6 个时全部展示且不显示「查看全部」
//  3. 列表页全量展示 type=user 歌单（不截断）、系统歌单不出现

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joy_tune/api/backend_client.dart';
import 'package:joy_tune/screens/home_screen.dart';
import 'package:joy_tune/screens/shared_playlists_screen.dart';
import 'package:joy_tune/services/providers.dart';

/// 构造推荐歌单（type=user 为分享歌单）
RecommendPlaylist _playlist(int id, {String type = 'user'}) {
  return RecommendPlaylist(
    id: id,
    name: '歌单$id',
    type: type,
    songCount: 3,
    userName: '创建者$id',
  );
}

/// 构造测试壳：ProviderScope 覆盖 recommendPlaylistsProvider + GoRouter 注册相关路由
Widget _wrap(List<RecommendPlaylist> playlists, Widget child) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (_, __) => child),
      GoRoute(path: '/shared-playlists', builder: (_, __) => const SharedPlaylistsScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      recommendPlaylistsProvider.overrideWith((ref) => Stream.value(playlists)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('分享歌单 >6 个：宫格截断到 6 张卡片，显示「查看全部」入口', (tester) async {
    // 1 个系统歌单 + 8 个分享歌单
    final playlists = [_playlist(1, type: 'system')];
    for (var i = 2; i <= 9; i++) {
      playlists.add(_playlist(i));
    }
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    // 分区标题存在
    expect(find.text('推荐歌单'), findsOneWidget);
    expect(find.text('分享歌单'), findsOneWidget);
    // 「查看全部」入口显示
    expect(find.text('查看全部'), findsOneWidget);
    // 宫格卡片：截断到 6 个分享歌单（歌单2~7），系统歌单1 在轮播区
    for (var i = 2; i <= 7; i++) {
      expect(find.text('歌单$i'), findsOneWidget);
    }
    // 第 7、8 个被截断，不显示
    expect(find.text('歌单8'), findsNothing);
    expect(find.text('歌单9'), findsNothing);
  });

  testWidgets('分享歌单 ≤6 个：全部展示，不显示「查看全部」入口', (tester) async {
    final playlists = [_playlist(1, type: 'system')];
    for (var i = 2; i <= 6; i++) {
      playlists.add(_playlist(i));
    }
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('分享歌单'), findsOneWidget);
    // 不足 6 个：全部展示、无「查看全部」
    for (var i = 2; i <= 6; i++) {
      expect(find.text('歌单$i'), findsOneWidget);
    }
    expect(find.text('查看全部'), findsNothing);
  });

  testWidgets('分享歌单列表页：全量展示 type=user，不含系统歌单', (tester) async {
    final playlists = [
      _playlist(1, type: 'system'),
      for (var i = 2; i <= 9; i++) _playlist(i),
    ];
    await tester.pumpWidget(_wrap(playlists, const SharedPlaylistsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('分享歌单'), findsOneWidget);
    // 懒加载列表：首屏可见前面几项
    expect(find.text('歌单2'), findsOneWidget);
    expect(find.text('歌单1'), findsNothing);
    // 滚到底：最后一个（第 8 个分享歌单）可见，验证未截断到 6 个
    await tester.scrollUntilVisible(
      find.text('歌单9'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('歌单9'), findsOneWidget);
    // 系统歌单滚到哪都不出现
    expect(find.text('歌单1'), findsNothing);
  });
}
