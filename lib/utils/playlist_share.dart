// 歌单分享工具
// 提供可复用的"分享歌单"底部弹层：公开开关（is_public）、复制链接、生成分享卡片预览
// 我的歌单列表页 ⋮ 菜单与详情页 AppBar 分享图标共用

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/backend_client.dart';
import '../config/api_config.dart';
import '../services/providers.dart';

/// 弹出"分享歌单"底部弹层
Future<void> showPlaylistShareSheet(
  BuildContext context,
  WidgetRef ref,
  UserPlaylist playlist,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PlaylistShareSheet(playlist: playlist),
  );
}

/// 分享歌单弹层内容
class _PlaylistShareSheet extends ConsumerStatefulWidget {
  final UserPlaylist playlist;
  const _PlaylistShareSheet({required this.playlist});

  @override
  ConsumerState<_PlaylistShareSheet> createState() => _PlaylistShareSheetState();
}

class _PlaylistShareSheetState extends ConsumerState<_PlaylistShareSheet> {
  late bool _isPublic = widget.playlist.isPublic;
  bool _saving = false;

  /// 提示信息
  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  /// 切换公开状态，调 updatePlaylist(isPublic)
  Future<void> _togglePublic(bool value) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _isPublic = value;
    });
    final updated = await ref
        .read(backendClientProvider)
        .updatePlaylist(widget.playlist.id, isPublic: value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (updated != null) {
      // 同步刷新列表与详情
      ref.invalidate(myPlaylistsProvider);
      ref.invalidate(myPlaylistDetailProvider(widget.playlist.id));
      _toast(value ? '已公开，歌单将出现在首页推荐' : '已取消公开');
    } else {
      // 失败回滚开关状态
      setState(() => _isPublic = widget.playlist.isPublic);
      _toast('操作失败，请重试');
    }
  }

  /// 复制歌单链接（使用无需登录的推荐详情接口，游客可访问）
  void _copyLink() {
    final link = '$apiBaseUrl/recommend/playlists/${widget.playlist.id}';
    Clipboard.setData(ClipboardData(text: link));
    _toast('已复制分享链接');
  }

  /// 生成分享卡片预览
  void _showShareCard() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ShareCardDialog(playlist: widget.playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Text('分享歌单', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('让更多人听到你的歌单', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),

            // 公开分享开关
            SwitchListTile(
              value: _isPublic,
              onChanged: _saving ? null : _togglePublic,
              activeTrackColor: const Color(0xFF6366F1),
              title: const Text('公开分享'),
              subtitle: const Text('公开后歌单将出现在首页「推荐歌单」，其他用户可查看'),
            ),
            const Divider(height: 1),

            // 复制链接
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.link_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              title: const Text('复制歌单链接'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: _copyLink,
            ),
            // 生成分享卡片
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.image_outlined, color: Color(0xFF6366F1), size: 20),
              ),
              title: const Text('生成分享卡片'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: _showShareCard,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 分享卡片预览弹窗
/// 渐变封面 + 歌单名 + 歌曲数/创建者 + 二维码占位 + 品牌，支持保存为图片
class _ShareCardDialog extends StatefulWidget {
  final UserPlaylist playlist;
  const _ShareCardDialog({required this.playlist});

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  /// 保存卡片为 PNG 图片（无相册依赖，保存到系统临时目录并提示路径）
  Future<void> _saveCard() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await Directory.systemTemp.createTemp('via_share_');
      final file = File('${dir.path}/playlist_${widget.playlist.id}.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('卡片已保存: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }

  /// 复制链接（分享给朋友，游客可访问）
  void _copyLink() {
    final link = '$apiBaseUrl/recommend/playlists/${widget.playlist.id}';
    Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制分享链接')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 卡片主体（RepaintBoundary 用于截图）
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.playlist.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${widget.playlist.songCount} 首 · 来自悦听',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Via Music · 好歌一起听',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      // 二维码占位
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6366F1), size: 34),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: _saving ? null : _saveCard,
                child: Text(_saving ? '保存中...' : '保存图片'),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: _copyLink,
                child: const Text('复制链接'),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
