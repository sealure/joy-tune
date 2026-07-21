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
                            child: Icon(
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
                                isLoggedIn ? 'SimpleCreator' : '点击登录',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              if (isLoggedIn)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '已绑定 GitHub',
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
                  _StatItem(label: '收藏歌曲', value: isLoggedIn ? '28' : '---'),
                  _StatItem(label: '创建歌单', value: isLoggedIn ? '3' : '---'),
                  _StatItem(label: '听歌总数', value: isLoggedIn ? '156' : '---'),
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
                    icon: Icons.history_rounded,
                    label: '播放历史',
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF6366F1),
                    enabled: isLoggedIn,
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: '设置',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/settings'),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    label: '关于',
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF3B82F6),
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
                    onPressed: () {},
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

  static bool _checkLoginStatus() => false;
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
