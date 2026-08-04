// 更新弹窗：发现新版本后居中卡片式弹窗
// 对应设计稿 ui/update/index.html 帧 2（渐变头部 + 更新内容 + 下载进度 + 两按钮）

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/providers.dart';
import '../services/update/update_models.dart';

/// 弹窗内部状态机：初始 → 下载中 → 下载完成 / 失败
enum _UpdatePhase { idle, downloading, downloaded, error }

/// 字节数格式化（MB/GB，如 84 MB）
String formatSize(int bytes) {
  if (bytes >= (1 << 30)) {
    return '${(bytes / (1 << 30)).toStringAsFixed(1)} GB';
  }
  if (bytes >= (1 << 20)) {
    return '${(bytes / (1 << 20)).toStringAsFixed(0)} MB';
  }
  if (bytes >= (1 << 10)) {
    return '${(bytes / (1 << 10)).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

/// 更新选择框：发现新版本后让用户决定是否立即更新
///
/// - Android 有匹配产物：`[稍后再说] [立即更新]`，立即更新进入完整下载安装弹窗
/// - 桌面端/ABI 无产物（noAsset）：`[取消] [前往下载]`，前往下载打开 Release 页
Future<void> showUpdatePrompt(
  BuildContext context,
  WidgetRef ref, {
  required UpdateCheckResult result,
}) async {
  final release = result.release;
  if (release == null) return;

  // 桌面端/ABI 无产物：跳转 Release 页手动下载
  if (result.noAsset) {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Text('当前 v${result.currentVersion ?? ''} → 最新 v${release.version}\n'
            '当前平台暂不支持自动安装，前往 GitHub Release 页手动下载？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('前往下载'),
          ),
        ],
      ),
    );
    if (go == true) {
      await launchUrl(Uri.parse(release.htmlUrl),
          mode: LaunchMode.externalApplication);
    }
    return;
  }

  final asset = result.asset;
  if (asset == null) return;

  // Android：确认是否立即更新
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('发现新版本'),
      content: Text(
          '当前 v${result.currentVersion ?? ''} → 最新 v${release.version}\n'
          '约 ${formatSize(asset.size)}，是否立即更新？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('稍后再说'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('立即更新'),
        ),
      ],
    ),
  );
  if (go == true) {
    // 确认框关闭后仍挂载才继续弹完整更新窗（防 context 失效）
    if (!context.mounted) return;
    await showUpdateDialog(context, ref, result: result);
  }
}

/// 展示更新弹窗（只能通过「稍后再说」关闭）
Future<void> showUpdateDialog(
  BuildContext context,
  WidgetRef ref, {
  required UpdateCheckResult result,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'update',
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (_, anim, __, child) {
      // 缩放上浮 + 淡入（设计稿 pop 动画）
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (_, __, ___) => UpdateDialog(result: result),
  );
}

/// 更新弹窗
class UpdateDialog extends ConsumerStatefulWidget {
  final UpdateCheckResult result;

  const UpdateDialog({super.key, required this.result});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  _UpdatePhase _phase = _UpdatePhase.idle;
  double _progress = 0;
  int _downloadedBytes = 0;
  String? _localPath;
  CancelToken? _cancelToken;

  ReleaseInfo? get _release => widget.result.release;
  ReleaseAsset? get _asset => widget.result.asset;

  /// 开始下载 APK（带进度回调）
  void _startDownload() async {
    final asset = _asset;
    if (asset == null) return;
    setState(() => _phase = _UpdatePhase.downloading);
    _cancelToken = CancelToken();
    final service = ref.read(updateServiceProvider);
    final path = await service.download(
      asset,
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _downloadedBytes = received;
          _progress = total > 0 ? received / total : 0;
        });
      },
      cancelToken: _cancelToken,
    );
    if (!mounted) return;
    if (path != null) {
      setState(() {
        _localPath = path;
        _phase = _UpdatePhase.downloaded;
        _progress = 1;
      });
    } else {
      setState(() => _phase = _UpdatePhase.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载失败，请重试')),
      );
    }
  }

  /// 拉起系统安装器安装 APK
  Future<void> _install() async {
    final path = _localPath;
    if (path == null) return;
    await ref.read(updateServiceProvider).installApk(path);
  }

  /// 关闭弹窗（「稍后再说」：取消进行中的下载）
  void _dismiss() {
    _cancelToken?.cancel();
    Navigator.of(context).pop();
  }

  /// 主按钮文案（状态机）
  String get _actionText {
    switch (_phase) {
      case _UpdatePhase.downloading:
        return '下载中…';
      case _UpdatePhase.downloaded:
        return '立即安装';
      case _UpdatePhase.error:
        return '重试下载';
      case _UpdatePhase.idle:
        return '立即安装';
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final release = _release;
    final asset = _asset;
    final current = widget.result.currentVersion ?? '';
    if (release == null || asset == null) {
      return const SizedBox.shrink();
    }

    final changelog = ChangelogItem.parse(release.body);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 头部渐变 + 下载图标
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                                Color(0xFFA855F7),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x596366F1),
                                blurRadius: 30,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '发现新版本 v${release.version}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            text: '当前 v$current → 最新 ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                            children: [
                              TextSpan(
                                text: 'v${release.version}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              TextSpan(text: ' · 约 ${formatSize(asset.size)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 更新内容 + 下载进度
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (changelog.isNotEmpty) ...[
                          const Text(
                            '更新内容',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...changelog.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.type != ChangelogType.plain) ...[
                                    _TypeTag(type: item.type),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF555555),
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // 下载进度
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 6,
                            color: const Color(0xFFEEF0F3),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _phase == _UpdatePhase.error
                                  ? 0
                                  : (_progress.clamp(0.0, 1.0)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _phase == _UpdatePhase.error ? '下载失败' : '正在下载…',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                '${(_progress * 100).round()}% · ${formatSize(_downloadedBytes)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 底部按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        // 稍后再说
                        Expanded(
                          child: _ActionButton(
                            label: '稍后再说',
                            background: const Color(0xFFF3F4F6),
                            foreground: const Color(0xFF888888),
                            onTap: _dismiss,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 立即安装 / 下载 / 重试
                        Expanded(
                          child: _ActionButton(
                            label: _actionText,
                            background: const Color(0xFF6366F1),
                            foreground: Colors.white,
                            enabled: _phase != _UpdatePhase.downloading,
                            onTap: _phase == _UpdatePhase.downloading
                                ? null
                                : () {
                                    if (_phase == _UpdatePhase.downloaded) {
                                      _install();
                                    } else {
                                      _startDownload();
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// changelog 类型标签（设计稿配色）
class _TypeTag extends StatelessWidget {
  final ChangelogType type;

  const _TypeTag({required this.type});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (type) {
      ChangelogType.feat => (const Color(0xFFEEF2FF), const Color(0xFF6366F1), '新增'),
      ChangelogType.fix => (const Color(0xFFFEF2F2), const Color(0xFFEF4444), '修复'),
      ChangelogType.opt => (const Color(0xFFECFDF5), const Color(0xFF10B981), '优化'),
      ChangelogType.plain => (Colors.transparent, Colors.transparent, ''),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// 弹窗底部按钮
class _ActionButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
