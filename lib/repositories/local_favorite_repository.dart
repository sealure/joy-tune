import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 本地收藏仓库实现（SharedPreferences + JSON）
class LocalFavoriteRepository implements FavoriteRepository {
  @override
  Future<List<Song>> getAll() async {
    debugPrint('[LocalFavoriteRepo] getAll()');
    final songs = await AppDatabase.getFavorites();
    debugPrint('[LocalFavoriteRepo] getAll() 返回 ${songs.length} 首');
    return songs;
  }

  @override
  Future<void> add(Song song) async {
    debugPrint('[LocalFavoriteRepo] add: id=${song.id}, name=${song.name}');
    final list = await AppDatabase.getFavorites();
    if (list.any((s) => s.id == song.id)) {
      debugPrint('[LocalFavoriteRepo] add: 已存在，跳过');
      return;
    }
    list.add(song);
    await AppDatabase.saveFavorites(list);
    debugPrint('[LocalFavoriteRepo] add: 保存成功，共 ${list.length} 首');
  }

  @override
  Future<void> remove(String songId) async {
    debugPrint('[LocalFavoriteRepo] remove: id=$songId');
    final list = await AppDatabase.getFavorites();
    list.removeWhere((s) => s.id == songId);
    await AppDatabase.saveFavorites(list);
    debugPrint('[LocalFavoriteRepo] remove: 完成，剩余 ${list.length} 首');
  }

  @override
  Future<bool> isFavorited(String songId) async {
    final list = await AppDatabase.getFavorites();
    final fav = list.any((s) => s.id == songId);
    debugPrint('[LocalFavoriteRepo] isFavorited: id=$songId, result=$fav');
    return fav;
  }

  @override
  Future<List<Song>> search(String keyword) async {
    final list = await AppDatabase.getFavorites();
    final kw = keyword.toLowerCase();
    return list
        .where((s) =>
            s.name.toLowerCase().contains(kw) ||
            s.artist.toLowerCase().contains(kw) ||
            s.album.toLowerCase().contains(kw))
        .toList();
  }

  @override
  Future<int> count() async {
    final list = await AppDatabase.getFavorites();
    return list.length;
  }
}
