import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_cache.dart';
import '../services/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _defaultBitrate = 320;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      // 清音频缓存 + 歌曲元数据缓存（封面URL/歌词/lyric_id）+ 封面图片字节缓存
                      await AudioCache.instance.clear();
                      try {
                        await ref.read(songMetaDaoProvider).clearAll();
                      } catch (_) {}
                      try {
                        await DefaultCacheManager().emptyCache();
                      } catch (_) {
                        // 图片缓存清理失败不影响其它缓存清除
                      }
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('缓存已清除')),
                        );
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
                _aboutTile('版本', '0.0.1'),
                const Divider(height: 1),
                _aboutTile('技术栈', 'Flutter + SharedPreferences'),
              ],
            ),
          ),
        ],
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
