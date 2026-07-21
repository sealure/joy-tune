import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 接入认证后替换为真实登录状态
    final isLoggedIn = _checkLoginStatus();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 头部背景
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    // 头像
                    GestureDetector(
                      onTap: isLoggedIn ? () => context.push('/profile/edit') : () => context.push('/login'),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLoggedIn ? '音乐爱好者' : '点击登录',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    if (isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.code_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'GitHub',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 统计行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  _StatItem(label: '收藏歌曲', value: isLoggedIn ? '--' : '---'),
                  _StatItem(label: '创建歌单', value: isLoggedIn ? '--' : '---'),
                  _StatItem(label: '听歌总数', value: isLoggedIn ? '--' : '---'),
                ],
              ),
            ),

            const Divider(height: 1),

            // 菜单列表
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuTile(icon: Icons.favorite_outline_rounded, label: '我的收藏', onTap: () => context.push('/favorites')),
                  _MenuTile(icon: Icons.history_rounded, label: '播放历史', enabled: isLoggedIn),
                  _MenuTile(icon: Icons.settings_outlined, label: '设置', onTap: () => context.push('/settings')),
                  _MenuTile(icon: Icons.info_outline_rounded, label: '关于'),
                ],
              ),
            ),

            // 退出登录
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  static bool _checkLoginStatus() => false; // TODO: 接入认证后替换
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
  final VoidCallback? onTap;
  final bool enabled;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(label, style: TextStyle(color: enabled ? null : Colors.grey.shade400)),
      trailing: enabled
          ? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.secondary)
          : Text('登录可见', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      enabled: enabled,
      onTap: onTap,
    );
  }
}
