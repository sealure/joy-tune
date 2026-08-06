import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recommend_dao.g.dart';

/// 推荐歌单缓存数据访问对象（只读下行缓存表，无 is_synced）
///
/// 镜像服务端推荐歌单列表与歌曲，由 SyncService 后台异步拉取后整体覆盖；
/// 首页/详情优先读本地（即时、离线可用），同步完成后 drift watch 自动刷新 UI。
@DriftAccessor(tables: [
  LocalRecommendPlaylists,
  LocalRecommendPlaylistSongs,
  LocalSettings,
])
class RecommendDao extends DatabaseAccessor<AppDatabase>
    with _$RecommendDaoMixin {
  RecommendDao(super.attachedDatabase);

  /// 推荐歌单缓存同步时间戳 key（存 local_settings）
  static const syncedAtKey = 'recommend_synced_at';

  // ── 歌单列表 ──

  /// 整体覆盖推荐歌单列表（清空后按服务端返回顺序插入，事务内原子）
  Future<void> replacePlaylists({
    required List<LocalRecommendPlaylistsCompanion> playlists,
  }) async {
    await transaction(() async {
      await delete(localRecommendPlaylists).go();
      if (playlists.isNotEmpty) {
        await batch((b) => b.insertAll(localRecommendPlaylists, playlists));
      }
    });
  }

  /// 流式监听推荐歌单列表（按服务端返回顺序）
  Stream<List<LocalRecommendPlaylist>> watchPlaylists() {
    return (select(localRecommendPlaylists)
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  /// 一次性读取推荐歌单列表
  Future<List<LocalRecommendPlaylist>> getPlaylists() async {
    return (select(localRecommendPlaylists)
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  /// 是否已有推荐歌单缓存（首页判断是否首拉用）
  Future<bool> hasPlaylistCache() async {
    final count = await localRecommendPlaylists.count().getSingle();
    return count > 0;
  }

  // ── 歌单歌曲 ──

  /// 整体覆盖单个推荐歌单的歌曲列表（按歌单内顺序插入，事务内原子）
  Future<void> replaceSongs({
    required int playlistId,
    required List<LocalRecommendPlaylistSongsCompanion> songs,
  }) async {
    await transaction(() async {
      await (delete(localRecommendPlaylistSongs)
            ..where((t) => t.playlistRemoteId.equals(playlistId)))
          .go();
      if (songs.isNotEmpty) {
        await batch((b) => b.insertAll(localRecommendPlaylistSongs, songs));
      }
    });
  }

  /// 流式监听某个推荐歌单的歌曲列表
  Stream<List<LocalRecommendPlaylistSong>> watchSongs(int playlistId) {
    return (select(localRecommendPlaylistSongs)
          ..where((t) => t.playlistRemoteId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// 一次性读取某个推荐歌单的歌曲列表
  Future<List<LocalRecommendPlaylistSong>> getSongs(int playlistId) async {
    return (select(localRecommendPlaylistSongs)
          ..where((t) => t.playlistRemoteId.equals(playlistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  // ── 同步时间戳（local_settings） ──

  /// 最近一次推荐缓存同步时间（无记录返回 null）
  Future<DateTime?> lastSyncedAt() async {
    final row = await (select(localSettings)
          ..where((t) => t.key.equals(syncedAtKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return DateTime.tryParse(row.value);
  }

  /// 记录推荐缓存同步时间
  Future<void> setSyncedAt(DateTime time) async {
    await into(localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(key: syncedAtKey, value: time.toIso8601String()),
    );
  }
}
