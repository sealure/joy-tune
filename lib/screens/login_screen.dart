import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';
import '../firebase_options.dart';
import '../services/google_oauth_windows.dart';
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
      // 1. 获取 Google 账号凭据：
      //    - Windows: google_sign_in 无实现,改走浏览器 OAuth(google_oauth_windows.dart)
      //    - Android/iOS/macOS: 用 google_sign_in 插件
      final String? idToken;
      final String? accessToken;
      if (Platform.isWindows) {
        debugPrint('>>> [STEP 1] Windows 浏览器 OAuth 登录');
        final result = await GoogleOAuthWindows().signIn();
        if (result == null) {
          debugPrint('>>> [STEP 1] 用户取消或 OAuth 失败');
          setState(() => _isLoading = false);
          return;
        }
        idToken = result.idToken;
        accessToken = result.accessToken;
        debugPrint('>>> [STEP 1] OAuth 成功, idToken=${idToken.length}字符');
      } else {
        debugPrint('>>> [STEP 1] 调用 GoogleSignIn().signIn()');
        // Android: firebase_auth 会自动用 google-services.json 的 Android client，无需手动配 serverClientId
        // iOS/macOS: 使用 iOS 客户端 ID（firebase_options 的 iOS appId 对应）
        final googleUser = await GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: Platform.isAndroid
              ? null // Android 自动用 Firebase 项目配置
              : DefaultFirebaseOptions.ios.appId,
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
        idToken = googleAuth.idToken;
        accessToken = googleAuth.accessToken;
        debugPrint('>>> [STEP 2] idToken=${idToken != null ? "有(${idToken.length}字符)" : "null"}, accessToken=${accessToken != null ? "有(${accessToken.length}字符)" : "null"}');
      }

      if (idToken == null) {
        debugPrint('>>> [STEP 2] 错误: idToken 为 null');
        throw Exception('获取 Google Token 失败');
      }

      // 3. 用 Google 凭证换 Firebase 会话（firebase_auth 统一管理登录态）
      debugPrint('>>> [STEP 3] Firebase signInWithCredential');
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase 登录失败：未获取到用户');
      }
      debugPrint('>>> [STEP 3] Firebase 登录成功, uid=${firebaseUser.uid}');

      // 4. 拿 Firebase 签发的 ID Token 发给后端（后端用 Admin SDK 验证）
      final firebaseIdToken = await firebaseUser.getIdToken();
      debugPrint('>>> [STEP 4] 发送 firebase id_token 到后端 $apiBaseUrl/auth/google');
      final authService = ref.read(authServiceProvider);
      final result = await authService.googleLogin(firebaseIdToken!);
      debugPrint('>>> [STEP 4] 后端返回成功, isNewUser=${result.isNewUser}, token长度=${result.token.length}');

      if (!mounted) return;

      // 5. 登录成功，跳转首页
      if (result.isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('欢迎注册 悦听！')),
        );
      }
      debugPrint('>>> [STEP 5] 跳转到首页');
      ref.read(isLoggedInProvider.notifier).state = true;
      // 登录成功后触发同步：拉取服务端收藏/歌单合并到本地，并推送本地游客数据
      ref.read(syncServiceProvider).syncNow(forcePull: true);
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
                    '悦听',
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
