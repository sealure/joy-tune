// 首页「今日推荐」大卡片 +「推荐歌单」轮播 +「分享歌单」宫格 + 公开歌单列表页 widget 测试
// 验证：
//  1. 有系统歌单时显示「今日推荐」大卡片
//  2. featured 歌单进「推荐歌单」轮播（>4 截断），且不在分享歌单宫格重复出现
//  3. featured 轮播 ≤4 全展示
//  4. 分享歌单 >6 个时宫格截断到 6 张卡片
//  5. 无系统歌单/无 featured 时正常降级（不显示对应区）
//  6. 列表页 all 模式：全量展示非 system 歌单（featured + user，不截断）
//  7. 列表页 featured 模式：仅展示推荐位歌单

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
  testWidgets('有系统歌单：显示「今日推荐」大卡片', (tester) async {
    final playlists = [_playlist(1, type: 'system'), _playlist(2)];
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    // 今日推荐大卡片：标签 + 标题 + 副文案（歌曲数来自系统歌单）
    expect(find.text('DAILY PICK'), findsOneWidget);
    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.text('猜你喜欢 · 3 首'), findsOneWidget);
    // 分享歌单区仍正常
    expect(find.text('分享歌单'), findsOneWidget);
  });

  testWidgets('featured 轮播 >4 截断，不在分享宫格重复出现', (tester) async {
    final playlists = [
      _playlist(1, type: 'system'),
      for (var i = 2; i <= 6; i++) _playlist(i, type: 'featured'), // 5 个推荐位
      _playlist(7),
    ];
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    // 推荐歌单区标题 + 「查看全部」常显
    expect(find.text('推荐歌单'), findsOneWidget);
    expect(find.text('查看全部'), findsWidgets);
    // 轮播截断到 4 个（歌单2~5），第 5 个（歌单6）被截断
    for (var i = 2; i <= 5; i++) {
      expect(find.text('歌单$i'), findsOneWidget);
    }
    expect(find.text('歌单6'), findsNothing);
    // 分享歌单宫格只含 user 歌单（featured 不重复出现）
    expect(find.text('分享歌单'), findsOneWidget);
    expect(find.text('歌单7'), findsOneWidget);
  });

  testWidgets('featured 轮播 ≤4 全展示', (tester) async {
    final playlists = [
      _playlist(1, type: 'system'),
      _playlist(2, type: 'featured'),
      _playlist(3, type: 'featured'),
    ];
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('推荐歌单'), findsOneWidget);
    expect(find.text('歌单2'), findsOneWidget);
    expect(find.text('歌单3'), findsOneWidget);
    // 分享区无 user 歌单时不显示
    expect(find.text('分享歌单'), findsNothing);
  });

  testWidgets('无系统歌单/无 featured：对应区不显示，分享歌单正常展示', (tester) async {
    final playlists = [_playlist(2), _playlist(3)];
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('今日推荐'), findsNothing);
    expect(find.text('DAILY PICK'), findsNothing);
    expect(find.text('推荐歌单'), findsNothing);
    expect(find.text('查看全部'), findsOneWidget); // 仅分享歌单区
    expect(find.text('分享歌单'), findsOneWidget);
    expect(find.text('歌单2'), findsOneWidget);
  });

  testWidgets('分享歌单 >6 个：宫格截断到 6 张卡片，显示「查看全部」入口', (tester) async {
    // 1 个系统歌单 + 8 个分享歌单
    final playlists = [_playlist(1, type: 'system')];
    for (var i = 2; i <= 9; i++) {
      playlists.add(_playlist(i));
    }
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    // 今日推荐大卡片 + 分享歌单区标题
    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.text('分享歌单'), findsOneWidget);
    // 「查看全部」入口显示
    expect(find.text('查看全部'), findsOneWidget);
    // 宫格卡片：截断到 6 个分享歌单（歌单2~7）
    for (var i = 2; i <= 7; i++) {
      expect(find.text('歌单$i'), findsOneWidget);
    }
    // 第 7、8 个被截断，不显示
    expect(find.text('歌单8'), findsNothing);
    expect(find.text('歌单9'), findsNothing);
  });

  testWidgets('分享歌单 ≤6 个：全部展示，「查看全部」常显', (tester) async {
    final playlists = [_playlist(1, type: 'system')];
    for (var i = 2; i <= 6; i++) {
      playlists.add(_playlist(i));
    }
    await tester.pumpWidget(_wrap(playlists, const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('分享歌单'), findsOneWidget);
    // 不足 6 个：全部展示，「查看全部」常显进列表页
    for (var i = 2; i <= 6; i++) {
      expect(find.text('歌单$i'), findsOneWidget);
    }
    expect(find.text('查看全部'), findsWidgets); // 推荐区 + 分享区
  });

  testWidgets('分享歌单列表页：全量展示非 system 歌单（featured + user），不含系统歌单', (tester) async {
    final playlists = [
      _playlist(1, type: 'system'),
      _playlist(2, type: 'featured'),
      for (var i = 3; i <= 9; i++) _playlist(i),
    ];
    await tester.pumpWidget(_wrap(playlists, const SharedPlaylistsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('分享歌单'), findsOneWidget);
    // featured 与 user 歌单都在列表（首屏可见）
    expect(find.text('歌单2'), findsOneWidget);
    expect(find.text('歌单3'), findsOneWidget);
    expect(find.text('歌单1'), findsNothing);
    // 滚到底：最后一项可见，验证未截断到 6 个
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

  testWidgets('列表页 featured 模式：仅展示推荐位歌单', (tester) async {
    final playlists = [
      _playlist(1, type: 'system'),
      _playlist(2, type: 'featured'),
      _playlist(3, type: 'featured'),
      for (var i = 4; i <= 7; i++) _playlist(i),
    ];
    await tester.pumpWidget(
      _wrap(playlists, const SharedPlaylistsScreen(filter: SharedPlaylistFilter.featured)),
    );
    await tester.pumpAndSettle();

    // 标题为推荐歌单
    expect(find.text('推荐歌单'), findsOneWidget);
    // 仅 2 个 featured，user 歌单与系统歌单都不出现
    expect(find.text('歌单2'), findsOneWidget);
    expect(find.text('歌单3'), findsOneWidget);
    for (var i = 4; i <= 7; i++) {
      expect(find.text('歌单$i'), findsNothing);
    }
    expect(find.text('歌单1'), findsNothing);
  });
}
