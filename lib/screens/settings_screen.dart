import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/audio_cache.dart';
import '../services/providers.dart';
import '../services/update/update_models.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _defaultBitrate = 320;

  @override
  void initState() {
    super.initState();
    // 进页后静默检查一次更新（本会话仅一次，供红点角标与按钮初始态）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 已检查过则跳过（红点已有缓存状态）
      if (ref.read(updateCheckStateProvider) != null) return;
      final service = ref.read(updateServiceProvider);
      final result = await service.checkForUpdates();
      if (!mounted) return;
      ref.read(updateCheckStateProvider.notifier).state = result;
    });
  }

  /// 触发检查更新（手动点击）
  Future<void> _onCheckUpdate() async {
    final service = ref.read(updateServiceProvider);
    // 进入检查中状态
    ref.read(updateCheckStateProvider.notifier).state =
        UpdateCheckResult.checking();
    final result = await service.checkForUpdates();
    if (!mounted) return;
    ref.read(updateCheckStateProvider.notifier).state = result;

    // 分支处理结果
    if (result.hasUpdate && result.asset != null) {
      // Android 有匹配 ABI 产物 → 弹下载弹窗
      await showUpdateDialog(context, ref, result: result);
    } else if (result.hasUpdate && result.noAsset) {
      // 桌面端/ABI 无产物 → 跳转 Release 页手动下载
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('发现新版本'),
          content: const Text('当前平台暂不支持自动安装，前往 GitHub Release 页手动下载？'),
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
      if (ok == true && result.release != null) {
        await launchUrl(Uri.parse(result.release!.htmlUrl),
            mode: LaunchMode.externalApplication);
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查更新失败，请稍后重试')),
      );
    } else {
      // 已是最新
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已是最新版本')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updateState = ref.watch(updateCheckStateProvider);
    final version = ref.watch(currentVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 用户信息
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              ),
              title: const Text('音乐爱好者'),
              subtitle: const Text('本地用户'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          const SizedBox(height: 24),
          Text('播放设置', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // 默认音质
          Card(
            child: ListTile(
              title: const Text('默认音质'),
              subtitle: Text('${_defaultBitrate}kbps'),
              trailing: DropdownButton<int>(
                value: _defaultBitrate,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 128, child: Text('128k')),
                  DropdownMenuItem(value: 192, child: Text('192k')),
                  DropdownMenuItem(value: 320, child: Text('320k')),
                  DropdownMenuItem(value: 740, child: Text('740k (无损)')),
                  DropdownMenuItem(value: 999, child: Text('999k (高解析)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _defaultBitrate = v);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text('存储', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // 缓存管理
          Card(
            child: FutureBuilder<int>(
              future: AudioCache.instance.cacheSize(),
              builder: (_, snapshot) {
                final size = snapshot.data ?? 0;
                final sizeStr = size >= 1073741824
                    ? '${(size / 1073741824).toStringAsFixed(2)} GB'
                    : size >= 1048576
                        ? '${(size / 1048576).toStringAsFixed(2)} MB'
                        : '${(size / 1024).toStringAsFixed(1)} KB';
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storage_rounded, color: Color(0xFF22C55E), size: 20),
                  ),
                  title: const Text('缓存管理'),
                  subtitle: Text('当前缓存：$sizeStr'),
                  trailing: TextButton(
                    onPressed: () async {
                      // 清音频缓存 + 歌曲元数据缓存（封面URL/歌词/lyric_id）+ 封面解析结果缓存 + 封面图片字节缓存
                      await AudioCache.instance.clear();
                      try {
                        await ref.read(songMetaDaoProvider).clearAll();
                      } catch (_) {}
                      try {
                        await ref.read(picCoverDaoProvider).clearAll();
                      } catch (_) {}
                      try {
                        await DefaultCacheManager().emptyCache();
                      } catch (_) {
                        // 图片缓存清理失败不影响其它缓存清除
                      }
                      if (mounted) {
                        setState(() {});
                        // use_build_context_synchronously：检查 State.context 是否仍挂载
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('缓存已清除')),
                          );
                        }
                      }
                    },
                    child: const Text('清除', style: TextStyle(color: Colors.red)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Text('关于', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                // 应用版本：有更新时显示红点角标
                ListTile(
                  title: const Text('应用版本'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (updateState?.hasUpdate == true) ...[
                        const _UpdateBadge(),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        version.when(
                          data: (v) => 'v$v',
                          loading: () => '…',
                          error: (_, __) => '未知',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                  onTap: _onCheckUpdate,
                ),
                const Divider(height: 1),
                // 检查更新：按钮状态机
                ListTile(
                  title: const Text('检查更新'),
                  trailing: _buildCheckButton(context, updateState),
                  onTap: _onCheckUpdate,
                ),
                const Divider(height: 1),
                _aboutTile('技术栈', 'Flutter + SharedPreferences'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 检查更新按钮状态机
  Widget _buildCheckButton(BuildContext context, UpdateCheckResult? state) {
    // 检查中
    if (state?.isChecking == true) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('检查中…', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      );
    }
    // 发现新版本
    if (state?.hasUpdate == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Text(
          '发现新版本',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }
    // 已是最新（检查成功且无更新）
    if (state?.error == null && state != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Text(
          '已是最新',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF10B981),
          ),
        ),
      );
    }
    // 检查失败 / 尚未检查
    final failed = state?.error != null;
    return Text(
      failed ? '检查失败，点此重试' : '点击检查',
      style: TextStyle(
        fontSize: 13,
        color: failed ? const Color(0xFFEF4444) : Colors.grey,
      ),
    );
  }

  Widget _aboutTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// 新版本红点角标（设计稿：8px 红色 + 外发光）
class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEF4444),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
