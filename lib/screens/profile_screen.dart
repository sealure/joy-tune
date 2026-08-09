import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/providers.dart';

/// 个人中心页 — 显示真实用户信息，支持退出登录
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// 退出登录
  Future<void> _handleLogout() async {
    final authService = ref.read(authServiceProvider);
    final syncService = ref.read(syncServiceProvider);
    // 退出前尽力同步本地未同步数据到该账号（游客切换到别的账号前先冲刷）
    await syncService.syncNow();
    await authService.logout();
    // 清空本地账号数据（收藏/歌单/收藏歌单/播放历史），重新登录后 forcePull 拉回
    await syncService.clearLocalUserData();
    if (!mounted) return;
    // 登录态置 false，currentUserProvider 会自动刷新为 null
    ref.read(isLoggedInProvider.notifier).state = false;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // 登录态与用户信息来自全局缓存（currentUserProvider 首次进入拉一次，切页不再重复请求）
    final isLoggedInFlag = ref.watch(isLoggedInProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final loading = isLoggedInFlag && userAsync.isLoading;
    // 有效登录判定：有 token 且已取到用户（或正在加载），避免 token 过期时展示半登录态
    final isLoggedIn = isLoggedInFlag && (user != null || loading);
    // 统计行真实数据：收藏数 / 创建歌单数
    final favCount = ref.watch(favoritesProvider).maybeWhen(
      data: (songs) => '${songs.length}',
      orElse: () => '---',
    );
    final playlistCount = ref.watch(myPlaylistsProvider).maybeWhen(
      data: (playlists) => '${playlists.length}',
      orElse: () => '---',
    );
    // 听歌总数（累计播放次数，实时从后端统计）
    final playCount = ref.watch(playCountProvider).maybeWhen(
      data: (count) => '$count',
      orElse: () => '---',
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部渐变背景
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFF6366F1)],
                ),
              ),
              child: Stack(
                children: [
                  // 暗色遮罩
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x4C000000)],
                        ),
                      ),
                    ),
                  ),
                  // 头像 & 信息
                  Positioned(
                    left: 24,
                    bottom: 20,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isLoggedIn ? () => context.push('/profile/edit') : () => context.push('/login'),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: user != null && user.avatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      user.avatarUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        size: 30,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                                    size: 30,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: isLoggedIn ? null : () => context.push('/login'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loading
                                    ? '加载中...'
                                    : (user?.nickname ?? '点击登录'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              if (isLoggedIn && user != null && user.authProvider.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '已绑定 ${_formatProvider(user.authProvider)}',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 统计行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  _StatItem(label: '收藏歌曲', value: isLoggedIn ? favCount : '---'),
                  _StatItem(label: '创建歌单', value: isLoggedIn ? playlistCount : '---'),
                  _StatItem(label: '听歌总数', value: isLoggedIn ? playCount : '---'),
                ],
              ),
            ),

            const Divider(height: 1),

            // 菜单
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuTile(
                    icon: Icons.favorite_outline_rounded,
                    label: '我的收藏',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => context.push('/favorites'),
                  ),
                  _MenuTile(
                    icon: Icons.queue_music_rounded,
                    label: '我的歌单',
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    enabled: isLoggedIn,
                    onTap: () => context.push('/my-playlists'),
                  ),
                  _MenuTile(
                    icon: Icons.history_rounded,
                    label: '播放历史',
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF6366F1),
                    enabled: isLoggedIn,
                    onTap: () => context.push('/play-history'),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: '设置',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),

            // 退出登录
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('退出登录', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 格式化 Provider 名称
String _formatProvider(String provider) {
  const names = {
    'google': 'Google',
    'github': 'GitHub',
    'qq': 'QQ',
    'wechat': '微信',
  };
  return provider.split(',').map((p) => names[p.trim()] ?? p.trim()).join('、');
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool enabled;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: enabled ? null : Colors.grey.shade400)),
      trailing: enabled
          ? Icon(Icons.chevron_right_rounded, color: const Color(0xFFCCCCCC), size: 20)
          : Text('登录可见', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      enabled: enabled,
      onTap: onTap,
    );
  }
}
