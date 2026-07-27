// 收藏按钮独立 Widget
// 独立的 ConsumerStatefulWidget，setState 不影响父级 widget 树重建

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 收藏按钮（心形）
/// 独立 widget，避免状态变化时触发父级重建导致的类型转换异常
class FavoriteButton extends ConsumerStatefulWidget {
  final Song song;

  const FavoriteButton({super.key, required this.song});

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      final fav = await repo.isFavorited(widget.song.id);
      if (mounted) {
        setState(() => _isFavorited = fav);
      }
    } catch (e, stack) {
      debugPrint('[FavBtn] _checkFavorite 异常: $e\n$stack');
    }
  }

  Future<void> _toggle() async {
    debugPrint('[FavBtn] _toggle: id=${widget.song.id}, current=$_isFavorited');
    try {
      final repo = ref.read(favoriteRepositoryProvider);
      if (_isFavorited) {
        await repo.remove(widget.song.id);
        if (mounted) setState(() => _isFavorited = false);
      } else {
        await repo.add(widget.song);
        debugPrint('[FavBtn] 收藏成功');
        if (mounted) setState(() => _isFavorited = true);
      }
    } catch (e, stack) {
      debugPrint('[FavBtn] _toggle 异常: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        icon: Icon(
          _isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: _isFavorited ? const Color(0xFFEF4444) : Colors.white.withValues(alpha: 0.6),
          size: 24,
        ),
        onPressed: _toggle,
        splashRadius: 22,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
