import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/player_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/my_playlists_screen.dart';
import 'screens/my_playlist_detail_screen.dart';
import 'screens/comments_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/play_history_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/mini_player_bar.dart';

class ViaMusicApp extends StatelessWidget {
  ViaMusicApp({super.key});

  final _router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── 首页 Tab 容器 ──
      ShellRoute(
        builder: (_, __, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          // 歌单详情页放在 ShellRoute 内部，避免 context.push 产生重复页面 Key
          GoRoute(
            path: '/playlist/:id',
            builder: (_, state) => PlaylistDetailScreen(playlistId: state.pathParameters['id']!),
          ),
          // 我的歌单列表页（个人中心入口）
          GoRoute(path: '/my-playlists', builder: (_, __) => const MyPlaylistsScreen()),
          // 播放历史页（个人中心入口）
          GoRoute(path: '/play-history', builder: (_, __) => const PlayHistoryScreen()),
          // 我的歌单详情页（管理能力），id 为本地歌单 UUID
          GoRoute(
            path: '/my-playlist/:id',
            builder: (_, state) => MyPlaylistDetailScreen(
              playlistId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ── 独立页面 ──
      GoRoute(path: '/player', builder: (_, __) => const PlayerScreen()),
      GoRoute(
        path: '/comments',
        builder: (_, state) => CommentsScreen(song: state.extra as dynamic),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '悦听',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 底部 Tab 导航壳
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex;
    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/favorites')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    } else {
      currentIndex = 0;
    }

    // 底部 Tab 壳：统一承载迷你播放栏，首页/搜索/收藏/我的/歌单详情自动生效
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayerBar(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/favorites');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: '首页'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: '搜索'),
          NavigationDestination(icon: Icon(Icons.favorite_outline_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: '收藏'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: '我的'),
        ],
      ),
    );
  }
}
