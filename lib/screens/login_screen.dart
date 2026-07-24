import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/providers.dart';

/// 登录页 — 深色背景 + 靛蓝/紫色光晕动画，GitHub / Google OAuth
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  /// Google OAuth 登录
  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('>>> [STEP 1] 调用 GoogleSignIn().signIn()');
      // 1. 调用 Google Sign-In SDK（使用 google-services.json 中的配置）
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();

      if (googleUser == null) {
        debugPrint('>>> [STEP 1] 用户取消了登录');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('>>> [STEP 1] 登录成功, email=${googleUser.email}, displayName=${googleUser.displayName}');

      // 2. 获取 Google 认证信息
      debugPrint('>>> [STEP 2] 获取 authentication');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('>>> [STEP 2] idToken=${idToken != null ? "有(${idToken.length}字符)" : "null"}, accessToken=${accessToken != null ? "有(${accessToken.length}字符)" : "null"}');

      if (idToken == null) {
        debugPrint('>>> [STEP 2] 错误: idToken 为 null');
        throw Exception('获取 Google Token 失败');
      }

      // 3. 发送到后端验证
      debugPrint('>>> [STEP 3] 发送 id_token 到后端 http://192.168.123.106:8080/api/v1/auth/google');
      final authService = ref.read(authServiceProvider);
      final result = await authService.googleLogin(idToken);
      debugPrint('>>> [STEP 3] 后端返回成功, isNewUser=${result.isNewUser}, token长度=${result.token.length}');

      if (!mounted) return;

      // 4. 登录成功，跳转首页
      if (result.isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('欢迎注册 Via Music！')),
        );
      }
      debugPrint('>>> [STEP 4] 跳转到首页');
      context.go('/home');
    } catch (e, stackTrace) {
      debugPrint('>>> [ERROR] 登录失败: $e');
      debugPrint('>>> [ERROR] 堆栈: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
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
              top: -60,
              right: -40,
              child: _Orb(size: 300, color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            Positioned(
              bottom: 120,
              left: -60,
              child: _Orb(size: 220, color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: -30,
              right: 30,
              child: _Orb(size: 160, color: const Color(0xFFEC4899).withValues(alpha: 0.1)),
            ),
            // 波形装饰
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: _Waveform(),
            ),
            // 内容
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  Container(
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
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Via Music',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '欢迎回来',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(flex: 1),
                  // 按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _SocialButton(
                          icon: Icons.code_rounded,
                          label: 'GitHub 账号登录',
                          backgroundColor: const Color(0xFF1A1A2E),
                          textColor: Colors.white,
                          borderColor: Colors.white.withValues(alpha: 0.08),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('GitHub OAuth 接入中...')),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _SocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: _isLoading ? '登录中...' : 'Google 账号登录',
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF1A1A1A),
                          iconColor: const Color(0xFF4285F4),
                          onTap: _isLoading ? () {} : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '登录即表示同意服务条款',
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.25)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      '跳过，先听听看',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Waveform extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = <Widget>[];
    final heights = [20, 30, 45, 55, 60, 50, 40, 28, 18];
    for (int i = 0; i < heights.length; i++) {
      bars.add(
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: Duration(milliseconds: 1500 + i * 100),
          builder: (_, value, __) => Transform.scale(
            scaleY: value,
            child: Container(
              width: 3,
              height: heights[i].toDouble(),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: bars,
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
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: iconColor ?? textColor),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
