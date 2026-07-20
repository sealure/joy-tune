import '../models/song.dart';

/// 收藏数据仓库抽象接口
/// LocalFavoriteRepository → 本地（现在用）
/// ApiFavoriteRepository   → 自建后端（以后用）
abstract class FavoriteRepository {
  Future<List<Song>> getAll();
  Future<void> add(Song song);
  Future<void> remove(String songId);
  Future<bool> isFavorited(String songId);
  Future<List<Song>> search(String keyword);
  Future<int> count();
}
