import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0FDF4),
              Color(0xFFECFDF5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),
              Text('Via Music', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                '极简 · 多音源 · 跨平台',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              ),

              const Spacer(flex: 1),

              // 登录按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _SocialButton(
                      icon: Icons.code_rounded,
                      label: 'GitHub 账号登录',
                      backgroundColor: const Color(0xFF24292F),
                      textColor: Colors.white,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GitHub OAuth 接入中...')),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google 账号登录',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF1A1A1A),
                      borderColor: const Color(0xFFE5E5E5),
                      iconColor: const Color(0xFF4285F4),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google OAuth 接入中...')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                '登录即表示同意服务条款',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),

              const Spacer(flex: 1),

              // 跳过
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  '跳过，先听听看',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(26),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: iconColor ?? textColor),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
