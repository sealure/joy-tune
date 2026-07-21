import 'package:flutter/material.dart';

import '../api/gdmusic_client.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultSource = 'netease';
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

          // 默认音源
          Card(
            child: ListTile(
              title: const Text('默认音源'),
              subtitle: Text(_defaultSource),
              trailing: DropdownButton<String>(
                value: _defaultSource,
                underline: const SizedBox(),
                items: GdMusicClient.sources.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _defaultSource = v);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

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
          Text('关于', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                _aboutTile('版本', '0.1.0'),
                const Divider(height: 1),
                _aboutTile('数据来源', 'GD Music API'),
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
