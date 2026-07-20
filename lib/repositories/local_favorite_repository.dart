import '../db/app_database.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 本地收藏仓库实现（SharedPreferences + JSON）
class LocalFavoriteRepository implements FavoriteRepository {
  @override
  Future<List<Song>> getAll() async {
    return AppDatabase.getFavorites();
  }

  @override
  Future<void> add(Song song) async {
    final list = await AppDatabase.getFavorites();
    if (list.any((s) => s.id == song.id)) return; // 已存在
    list.add(song);
    await AppDatabase.saveFavorites(list);
  }

  @override
  Future<void> remove(String songId) async {
    final list = await AppDatabase.getFavorites();
    list.removeWhere((s) => s.id == songId);
    await AppDatabase.saveFavorites(list);
  }

  @override
  Future<bool> isFavorited(String songId) async {
    final list = await AppDatabase.getFavorites();
    return list.any((s) => s.id == songId);
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
