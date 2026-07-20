import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _enter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // 保存昵称到本地（后续接入 UserService）
    // 暂时简单存入 SharedPreferences
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Icon(Icons.music_note_rounded, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('Via Music', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                '极简音乐播放器',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 48),

              // 昵称输入
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: '输入你的昵称'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),

              // 进入按钮
              FilledButton(
                onPressed: _enter,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: const Text('开始听歌', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
