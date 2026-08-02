import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/daos/favorite_dao.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 收藏数据仓库（本地 SQLite 实现）
///
/// 收藏先写本地（is_synced=0），由 SyncService 后台增量同步到服务端；
/// watchAll() 提供流式数据源，UI 订阅后自动响应，无需手动刷新。
class DriftFavoriteRepository implements FavoriteRepository {
  final FavoriteDao _dao;

  DriftFavoriteRepository(this._dao);

  /// 流式监听全部收藏（未删除，按收藏时间倒序）
  Stream<List<Song>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(_toSong).toList());
  }

  @override
  Future<List<Song>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toSong).toList();
  }

  @override
  Future<void> add(Song song) async {
    debugPrint('[DriftFavoriteRepo] add: id=${song.id}, name=${song.name}');
    await _dao.insertFavorite(song);
  }

  @override
  Future<void> remove(String songId) async {
    debugPrint('[DriftFavoriteRepo] remove: id=$songId');
    // 同一 song_id 可能有多音源记录，逐个 soft delete
    final rows = await _dao.getBySongId(songId);
    for (final row in rows) {
      await _dao.softDelete(songId, row.source);
    }
  }

  @override
  Future<bool> isFavorited(String songId) async {
    final rows = await _dao.getBySongId(songId);
    return rows.any((r) => !r.deleted);
  }

  @override
  Future<List<Song>> search(String keyword) async {
    final all = await getAll();
    final kw = keyword.toLowerCase();
    return all
        .where((s) =>
            s.name.toLowerCase().contains(kw) ||
            s.artist.toLowerCase().contains(kw) ||
            s.album.toLowerCase().contains(kw))
        .toList();
  }

  @override
  Future<int> count() async => _dao.count();

  /// LocalFavorite 数据行 → Song 模型
  Song _toSong(LocalFavorite f) => Song(
        id: f.songId,
        source: f.source,
        name: f.name,
        artist: f.artist,
        album: f.album,
        picId: f.picId,
        lyricId: f.lyricId,
        audioUrl: f.audioUrl,
        coverUrl: f.coverUrl,
        lyricsUrl: f.lyricsUrl,
      );
}
