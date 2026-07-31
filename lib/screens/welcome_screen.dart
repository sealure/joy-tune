import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/providers.dart';

/// 启动/欢迎页 — 深色靛蓝主题，Logo 呼吸动画，自动检测登录状态
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _breathAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _breathCtrl.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  /// 检测登录状态，决定跳转目标
  void _navigate() async {
    if (!mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      final hasToken = await authService.isLoggedIn;
      if (!mounted) return;

      if (hasToken) {
        // 已登录，更新登录状态并跳转首页
        ref.read(isLoggedInProvider.notifier).state = true;
        context.go('/home');
      } else {
        // 未登录，跳转登录页
        context.go('/login');
      }
    } catch (_) {
      // 检测失败，跳转登录页
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0A0A14),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 光晕
            Positioned(
              top: -40,
              left: -40,
              child: _Glow(size: 280, color: const Color(0xFF6366F1).withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: 60,
              right: -60,
              child: _Glow(size: 200, color: const Color(0xFF8B5CF6).withValues(alpha: 0.12)),
            ),
            // 主内容
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _breathAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _breathAnim.value,
                      child: child,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '悦听',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '多音源聚合 · 沉浸聆听',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // 版本号
            Positioned(
              left: 24,
              bottom: 40,
              child: Text(
                'v0.1.0',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
