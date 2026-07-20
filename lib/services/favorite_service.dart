import '../models/song.dart';
import '../repositories/favorite_repository.dart';

/// 收藏服务
class FavoriteService {
  final FavoriteRepository _repo;

  FavoriteService(this._repo);

  Future<List<Song>> getAll() => _repo.getAll();
  Future<void> add(Song song) => _repo.add(song);
  Future<void> remove(String songId) => _repo.remove(songId);
  Future<bool> isFavorited(String songId) => _repo.isFavorited(songId);
  Future<List<Song>> search(String keyword) => _repo.search(keyword);
  Future<int> count() => _repo.count();
}
