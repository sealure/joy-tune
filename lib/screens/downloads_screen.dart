// 已下载页
// 展示用户显式下载到系统下载目录（下载/JoyTune/）的歌曲，支持全部播放/删除下载。
// 数据源：local_downloads 表（StreamProvider 流式），与缓存完全独立（清理缓存不触碰）。
// 对应设计稿 ui/downloads/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../utils/player_utils.dart';
import '../widgets/song_cover.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('已下载')),
      body: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 64, color: const Color(0xFF0EA5E9)),
                  const SizedBox(height: 16),
                  Text('还没有下载的歌曲', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('下载后无网络也能离线播放', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    child: const Text('去下载歌曲', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              _buildHero(context, ref, songs),
              // 歌曲列表
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                  itemBuilder: (_, i) {
                    final song = songs[i];
                    return _DownloadRow(
                      song: song,
                      onTap: () => playSong(context, ref, song),
                      onRemove: () async {
                        // 二次确认删除（含本地文件）
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除下载'),
                            content: Text('将删除「${song.name}」的本地下载文件，确定？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        await ref.read(downloadServiceProvider).remove(song);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已删除下载')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 渐变 Hero：本地音乐 + 全部播放
  Widget _buildHero(BuildContext context, WidgetRef ref, List<Song> songs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFF0369A1)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本地音乐',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${songs.length} 首 · 存储于 下载/JoyTune',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final audio = ref.read(audioServiceProvider);
                      audio.stop();
                      audio.setQueue(songs, startIndex: 0);
                      context.push('/player', extra: songs[0]);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF0EA5E9), size: 20),
                          SizedBox(width: 6),
                          Text('全部播放', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已下载歌曲行
class _DownloadRow extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DownloadRow({
    required this.song,
    required this.onTap,
    required this.onRemove,
  });

  @override
  ConsumerState<_DownloadRow> createState() => _DownloadRowState();
}

class _DownloadRowState extends ConsumerState<_DownloadRow> {
  /// 本地封面路径（<歌名>-<歌手>.jpg，已下载则存在）
  String? _localCoverPath;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPaths();
  }

  Future<void> _loadLocalPaths() async {
    final record = await ref
        .read(downloadRepositoryProvider)
        .getByKey(widget.song.id, widget.song.source);
    if (!mounted) return;
    setState(() {
      final coverPath = record?.coverPath;
      _localCoverPath = (coverPath != null && File(coverPath).existsSync()) ? coverPath : null;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: widget.onTap,
      leading: SizedBox(
        width: 44,
        height: 44,
        child: _localCoverPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_localCoverPath!), fit: BoxFit.cover),
              )
            : SongCover(song: widget.song, size: 44, borderRadius: 8),
      ),
      title: Text(widget.song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(widget.song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_ready)
            const Text('✓已下载', style: TextStyle(fontSize: 11, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 22),
            tooltip: '删除下载',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}