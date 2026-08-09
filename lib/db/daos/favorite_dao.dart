import 'package:drift/drift.dart';

import '../../models/song.dart';
import '../app_database.dart';
import '../tables.dart';

part 'favorite_dao.g.dart';

/// 收藏数据访问对象（需同步表：local_favorites）
@DriftAccessor(tables: [LocalFavorites])
class FavoriteDao extends DatabaseAccessor<AppDatabase> with _$FavoriteDaoMixin {
  FavoriteDao(super.attachedDatabase);

  /// 清空全部收藏（退出登录/登录失效时调用，重新登录后由 syncNow(forcePull) 拉回）
  Future<void> clearAll() async {
    await (delete(localFavorites)).go();
  }

  /// 收藏一首歌：不存在则插入；已 soft delete 则恢复（deleted=0、is_synced=0）；
  /// 已存在且未删除则幂等跳过
  Future<void> insertFavorite(Song song) async {
    final existing = await _findByKey(song.id, song.source);
    if (existing == null) {
      await into(localFavorites).insert(LocalFavoritesCompanion.insert(
        songId: song.id,
        source: song.source,
        name: song.name,
        artist: song.artist,
        album: Value(song.album),
        picId: Value(song.picId),
        lyricId: Value(song.lyricId),
        audioUrl: Value(song.audioUrl),
        coverUrl: Value(song.coverUrl),
        lyricsUrl: Value(song.lyricsUrl),
      ));
    } else if (existing.deleted) {
      await (update(localFavorites)
            ..where((t) => t.songId.equals(song.id) & t.source.equals(song.source)))
          .write(
            LocalFavoritesCompanion(
              deleted: const Value(false),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  /// 取消收藏（soft delete）：曾同步过的标记 deleted=1 待同步删除；从未同步过的直接物理删除
  Future<void> softDelete(String songId, String source) async {
    final existing = await _findByKey(songId, source);
    if (existing == null) return;
    if (existing.syncedEver) {
      await (update(localFavorites)
            ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
          .write(
            LocalFavoritesCompanion(
              deleted: const Value(true),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      await (delete(localFavorites)
            ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
          .go();
    }
  }

  /// 是否已收藏（忽略 soft delete 标记）
  Future<bool> isFavorited(String songId, String source) async {
    final existing = await _findByKey(songId, source);
    return existing != null && !existing.deleted;
  }

  /// 流式监听全部未删除收藏（按收藏时间倒序）
  Stream<List<LocalFavorite>> watchAll() {
    return (select(localFavorites)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 一次性读取全部未删除收藏
  Future<List<LocalFavorite>> getAll() async {
    return (select(localFavorites)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 按歌曲 ID 查询全部行（含已删除，跨音源）；取消收藏/收藏状态需要
  Future<List<LocalFavorite>> getBySongId(String songId) async {
    return (select(localFavorites)..where((t) => t.songId.equals(songId))).get();
  }

  /// 按 (songId, source) 查询收藏行（含已删除），无则 null
  Future<LocalFavorite?> queryByKey(String songId, String source) async {
    return _findByKey(songId, source);
  }

  /// 待推送的收藏（未删除且未同步）
  Future<List<LocalFavorite>> pendingToPush() async {
    return (select(localFavorites)
          ..where((t) => t.deleted.equals(false) & t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 待同步删除的收藏（已 soft delete 且曾同步过）
  Future<List<LocalFavorite>> pendingToDelete() async {
    return (select(localFavorites)
          ..where((t) => t.deleted.equals(true) & t.syncedEver.equals(true)))
        .get();
  }

  /// 标记收藏已同步
  Future<void> markSynced(String songId, String source) async {
    await (update(localFavorites)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .write(
          LocalFavoritesCompanion(
            isSynced: const Value(true),
            syncedEver: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 回填收藏的可播放音频地址（播放解析成功后调用，避免下次重新解析）
  Future<void> updateAudioUrl(String songId, String source, String? audioUrl) async {
    await (update(localFavorites)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .write(
          LocalFavoritesCompanion(
            audioUrl: Value(audioUrl),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 回填收藏的 lyric_id（为空才补），并标记待同步（供 likeSong 补传 lyric_id）
  Future<void> backfillLyricId(String songId, String source, String lyricId) async {
    await (update(localFavorites)
          ..where((t) =>
              t.songId.equals(songId) &
              t.source.equals(source) &
              t.lyricId.isNull()))
        .write(
          LocalFavoritesCompanion(
            lyricId: Value(lyricId),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 物理删除一条收藏（同步删除成功后调用）
  Future<void> removeRow(String songId, String source) async {
    await (delete(localFavorites)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .go();
  }

  /// 收藏总数（忽略 soft delete）
  Future<int> count() async {
    final countExpr = countAll();
    final result = await (selectOnly(localFavorites)
          ..addColumns([countExpr])
          ..where(localFavorites.deleted.equals(false)))
        .getSingle();
    return result.read(countExpr) ?? 0;
  }

  Future<LocalFavorite?> _findByKey(String songId, String source) async {
    return (select(localFavorites)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .getSingleOrNull();
  }
}
