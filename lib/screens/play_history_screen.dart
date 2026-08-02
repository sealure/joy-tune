// 播放历史页
// 展示当前用户最近播放的歌曲（按时间倒序、日期分组），支持清空历史

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/backend_client.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../utils/player_utils.dart';
import '../widgets/song_cover.dart';

/// 播放历史页
class PlayHistoryScreen extends ConsumerWidget {
  const PlayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(playHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放历史'),
        actions: [
          // 清空历史按钮
          TextButton.icon(
            onPressed: () => _confirmClear(context, ref),
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            label: const Text('清空', style: TextStyle(color: Colors.red, fontSize: 13)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return Column(
            children: [
              // 副标题
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '最近播放的歌曲，最多保留 100 条',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              // 按日期分组列表（迷你播放栏由 _MainShell 统一提供）
              Expanded(
                child: _buildGroupedList(context, ref, records),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 按日期分组的歌曲列表
  Widget _buildGroupedList(BuildContext context, WidgetRef ref, List<PlayHistoryItem> records) {
    // 后端已按播放时间倒序返回，这里仅按日期分组保持顺序
    final groups = <String, List<PlayHistoryItem>>{};
    final groupOrder = <String>[];
    final now = DateTime.now();

    for (final r in records) {
      final title = _groupTitle(r.playedAt, now);
      if (!groups.containsKey(title)) {
        groups[title] = [];
        groupOrder.add(title);
      }
      groups[title]!.add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        for (final title in groupOrder) ...[
          // 日期分组标题
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
            ),
          ),
          for (final r in groups[title]!) _buildSongRow(context, ref, r),
        ],
      ],
    );
  }

  /// 单条播放记录行
  Widget _buildSongRow(BuildContext context, WidgetRef ref, PlayHistoryItem r) {
    final song = _toSong(r);
    final timeText = _formatTime(r.playedAt, DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => playSong(context, ref, song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 封面
              SongCover(
                song: song,
                coverUrl: r.coverUrl.isEmpty ? null : r.coverUrl,
                size: 44,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              // 歌名 & 歌手 · 播放时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.name, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.artist,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(timeText, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ),
              ),
              // 播放图标
              Icon(Icons.play_circle_outline_rounded, size: 22, color: Theme.of(context).colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('还没有播放记录', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('去听一首歌，你的播放历史会出现在这里', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// 清空历史二次确认
  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空播放历史'),
        content: const Text('确定要清空全部播放记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 本地清空 + 标记待同步清服务端（SyncService 登录后调 DELETE /play-records）
    await ref.read(playRecordRepositoryProvider).clear();
    await ref.read(settingsDaoProvider).set('pending_clear_play_history', 'true');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空播放历史')),
      );
    }
  }

  /// 播放历史项 → 可播放的 Song（音频地址由播放解析流程补齐）
  Song _toSong(PlayHistoryItem r) {
    return Song(
      id: r.songId,
      source: r.source,
      name: r.songName,
      artist: r.artist,
      album: r.album,
      coverUrl: r.coverUrl.isEmpty ? null : r.coverUrl,
      audioUrl: null,
    );
  }

  /// 日期分组标题
  String _groupTitle(DateTime? playedAt, DateTime now) {
    final t = playedAt?.toLocal();
    if (t == null) return '未知时间';
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(thatDay).inDays;
    if (diff <= 0) return '今天';
    if (diff == 1) return '昨天';
    return '${t.month}月${t.day}日';
  }

  /// 相对时间格式
  String _formatTime(DateTime? playedAt, DateTime now) {
    final t = playedAt?.toLocal();
    if (t == null) return '';
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(thatDay).inDays;
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    if (diff <= 0) {
      final minutes = now.difference(t).inMinutes;
      if (minutes < 1) return '刚刚';
      if (minutes < 60) return '$minutes分钟前';
      return '${now.difference(t).inHours}小时前';
    }
    if (diff == 1) return '昨天 $hm';
    return '${t.month}月${t.day}日 $hm';
  }
}
