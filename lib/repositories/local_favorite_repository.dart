import '../db/app_database.dart';
import '../models/song.dart';

/// 收藏数据仓库抽象接口
/// 当前用 Isar 本地实现，以后加后端时额外写 ApiFavoriteRepository
abstract class FavoriteRepository {
  Future<List<Song>> getAll();
  Future<void> add(Song song);
  Future<void> remove(String songId);
  Future<bool> isFavorited(String songId);
  Future<List<Song>> search(String keyword);
  Future<int> count();
}

/// 本地数据库实现（Isar）
class LocalFavoriteRepository implements FavoriteRepository {
  @override
  Future<List<Song>> getAll() async {
    final isar = await AppDatabase.instance;
    final records = await isar.favoriteSongDbs.where().findAll();
    return records.map((r) => r.toSong()).toList();
  }

  @override
  Future<void> add(Song song) async {
    final isar = await AppDatabase.instance;
    final exists = await isar.favoriteSongDbs
        .filter()
        .songIdEqualTo(song.id)
        .findFirst();

    if (exists != null) return; // 已收藏，跳过

    final record = FavoriteSongDb()
      ..songId = song.id
      ..source = song.source
      ..name = song.name
      ..artist = song.artist
      ..album = song.album
      ..coverUrl = song.picId
      ..lyricId = song.lyricId
      ..addedAt = DateTime.now();

    await isar.writeTxn(() => isar.favoriteSongDbs.put(record));
  }

  @override
  Future<void> remove(String songId) async {
    final isar = await AppDatabase.instance;
    final record = await isar.favoriteSongDbs
        .filter()
        .songIdEqualTo(songId)
        .findFirst();
    if (record != null) {
      await isar.writeTxn(() => isar.favoriteSongDbs.delete(record.id));
    }
  }

  @override
  Future<bool> isFavorited(String songId) async {
    final isar = await AppDatabase.instance;
    final record = await isar.favoriteSongDbs
        .filter()
        .songIdEqualTo(songId)
        .findFirst();
    return record != null;
  }

  @override
  Future<List<Song>> search(String keyword) async {
    final isar = await AppDatabase.instance;
    final records = await isar.favoriteSongDbs
        .filter()
        .anyOf([keyword.toLowerCase()], (q, kw) => q
            .nameLowerCase(kw)
            .or()
            .artistLowerCase(kw)
            .or()
            .albumLowerCase(kw))
        .findAll();
    return records.map((r) => r.toSong()).toList();
  }

  @override
  Future<int> count() async {
    final isar = await AppDatabase.instance;
    return await isar.favoriteSongDbs.count();
  }
}
