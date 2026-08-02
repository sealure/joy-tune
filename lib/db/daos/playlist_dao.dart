import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'playlist_dao.g.dart';

/// 歌单及其歌曲数（列表展示用）
class PlaylistWithCount {
  /// 歌单本体
  final LocalPlaylist playlist;
  /// 未删除歌曲数
  final int songCount;

  const PlaylistWithCount(this.playlist, this.songCount);
}

/// 歌单数据访问对象（需同步表：local_playlists + local_playlist_songs）
@DriftAccessor(tables: [LocalPlaylists, LocalPlaylistSongs])
class PlaylistDao extends DatabaseAccessor<AppDatabase> with _$PlaylistDaoMixin {
  PlaylistDao(super.attachedDatabase);

  // ── 歌单列表 ──

  /// 流式监听全部未删除歌单（带了未删除歌曲数，按创建时间倒序）
  /// 用子查询统计歌曲数，readsFrom 声明依赖表以保证流式自动响应
  Stream<List<PlaylistWithCount>> watchAllWithCount() {
    final selectable = attachedDatabase.customSelect(
      '''
      SELECT p.*,
        (SELECT COUNT(*) FROM local_playlist_songs s
         WHERE s.playlist_id = p.id AND s.deleted = 0) AS song_count
      FROM local_playlists p
      WHERE p.deleted = 0
      ORDER BY p.created_at DESC
      ''',
      readsFrom: {localPlaylists, localPlaylistSongs},
    );
    return selectable.watch().map(
          (rows) => rows.map((row) {
            final data = Map<String, dynamic>.from(row.data);
            final playlist = localPlaylists.map(data);
            final count = data['song_count'] is int
                ? data['song_count'] as int
                : int.tryParse(data['song_count']?.toString() ?? '0') ?? 0;
            return PlaylistWithCount(playlist, count);
          }).toList(),
        );
  }

  /// 一次性读取全部未删除歌单
  Future<List<LocalPlaylist>> getAll() async {
    return (select(localPlaylists)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ── 歌单详情 ──

  /// 读取单个未删除歌单
  Future<LocalPlaylist?> getById(String localId) async {
    return (select(localPlaylists)..where((t) => t.id.equals(localId))).getSingleOrNull();
  }

  /// 流式监听单个歌单
  Stream<LocalPlaylist?> watchById(String localId) {
    return (select(localPlaylists)..where((t) => t.id.equals(localId)))
        .watchSingleOrNull();
  }

  /// 流式监听歌单内未删除歌曲（按本地排序序号升序）
  Stream<List<LocalPlaylistSong>> watchSongs(String localId) {
    return (select(localPlaylistSongs)
          ..where((t) => t.playlistId.equals(localId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  /// 一次性读取歌单内未删除歌曲
  Future<List<LocalPlaylistSong>> getSongs(String localId) async {
    return (select(localPlaylistSongs)
          ..where((t) => t.playlistId.equals(localId) & t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  // ── 歌单写操作 ──

  /// 创建歌单（本地 UUID 主键，is_synced=0，remoteId 暂空）
  Future<void> create(LocalPlaylistsCompanion companion) async {
    await into(localPlaylists).insert(companion);
  }

  /// 更新歌单信息（标记待同步）
  Future<void> updatePlaylist(
    String localId, {
    String? name,
    String? description,
    String? coverUrl,
    bool? isPublic,
  }) async {
    await (update(localPlaylists)..where((t) => t.id.equals(localId))).write(
          LocalPlaylistsCompanion(
            name: name == null ? const Value.absent() : Value(name),
            description: description == null ? const Value.absent() : Value(description),
            coverUrl: coverUrl == null ? const Value.absent() : Value(coverUrl),
            isPublic: isPublic == null ? const Value.absent() : Value(isPublic),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 删除歌单（soft delete）：曾同步过的标记待同步删除；从未同步过的连同歌曲直接物理删除
  Future<void> softDelete(String localId) async {
    final existing = await getById(localId);
    if (existing == null) return;
    if (existing.syncedEver || existing.remoteId != null) {
      await (update(localPlaylists)..where((t) => t.id.equals(localId))).write(
            LocalPlaylistsCompanion(
              deleted: const Value(true),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      await (delete(localPlaylists)..where((t) => t.id.equals(localId))).go();
      // 级联删除子歌曲
      await (delete(localPlaylistSongs)..where((t) => t.playlistId.equals(localId))).go();
    }
  }

  // ── 歌单歌曲写操作 ──

  /// 往歌单添加歌曲（幂等：歌单内同 (song_id, source) 已存在则恢复/更新并标记待同步）
  Future<void> addSong({
    required String playlistId,
    required String songId,
    required String source,
    required String songName,
    required String artist,
    String album = '',
    String? coverUrl,
    String? picId,
  }) async {
    final existing = await (select(localPlaylistSongs)
          ..where((t) =>
              t.playlistId.equals(playlistId) &
              t.songId.equals(songId) &
              t.source.equals(source)))
        .getSingleOrNull();
    if (existing == null) {
      // 计算当前最大 sortOrder，追加到末尾
      final maxOrder = await (selectOnly(localPlaylistSongs)
            ..addColumns([localPlaylistSongs.sortOrder.max()])
            ..where(localPlaylistSongs.playlistId.equals(playlistId) &
                localPlaylistSongs.deleted.equals(false)))
          .getSingle();
      final nextOrder = (maxOrder.read(localPlaylistSongs.sortOrder.max()) ?? -1) + 1;
      await into(localPlaylistSongs).insert(LocalPlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: songId,
        source: source,
        songName: songName,
        artist: artist,
        album: Value(album),
        coverUrl: Value(coverUrl),
        picId: Value(picId),
        sortOrder: Value(nextOrder),
      ));
    } else if (existing.deleted) {
      // 恢复已删除的歌单歌曲
      await (update(localPlaylistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) &
                t.songId.equals(songId) &
                t.source.equals(source)))
          .write(
            LocalPlaylistSongsCompanion(
              deleted: const Value(false),
              isSynced: const Value(false),
              songName: Value(songName),
              artist: Value(artist),
              album: Value(album),
              coverUrl: Value(coverUrl),
              picId: Value(picId),
            ),
          );
    } else {
      // 已存在：更新元信息并标记待同步
      await (update(localPlaylistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) &
                t.songId.equals(songId) &
                t.source.equals(source)))
          .write(
            LocalPlaylistSongsCompanion(
              isSynced: const Value(false),
              songName: Value(songName),
              artist: Value(artist),
              album: Value(album),
              coverUrl: Value(coverUrl),
              picId: Value(picId),
            ),
          );
    }
  }

  /// 从歌单移除歌曲（soft delete，逻辑同收藏）
  Future<void> softDeleteSong(String playlistId, String songId, String source) async {
    final existing = await (select(localPlaylistSongs)
          ..where((t) =>
              t.playlistId.equals(playlistId) &
              t.songId.equals(songId) &
              t.source.equals(source)))
        .getSingleOrNull();
    if (existing == null) return;
    if (existing.syncedEver) {
      await (update(localPlaylistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) &
                t.songId.equals(songId) &
                t.source.equals(source)))
          .write(
            LocalPlaylistSongsCompanion(
              deleted: const Value(true),
              isSynced: const Value(false),
            ),
          );
    } else {
      await (delete(localPlaylistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) &
                t.songId.equals(songId) &
                t.source.equals(source)))
          .go();
    }
  }

  /// 更新歌单内歌曲排序（仅本地 sortOrder，标记该歌单待同步）
  Future<void> reorder(String playlistId, List<String> songIdsInOrder) async {
    await transaction(() async {
      for (var i = 0; i < songIdsInOrder.length; i++) {
        await (update(localPlaylistSongs)
              ..where((t) =>
                  t.playlistId.equals(playlistId) & t.songId.equals(songIdsInOrder[i])))
            .write(LocalPlaylistSongsCompanion(sortOrder: Value(i)));
      }
      await (update(localPlaylists)..where((t) => t.id.equals(playlistId))).write(
            LocalPlaylistsCompanion(
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  // ── 同步相关 ──

  /// 待创建/待更新的歌单（未删除且未同步）
  Future<List<LocalPlaylist>> pendingPlaylists() async {
    return (select(localPlaylists)
          ..where((t) => t.deleted.equals(false) & t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 待同步删除的歌单（已 soft delete 且有远端 id）
  Future<List<LocalPlaylist>> pendingDeletePlaylists() async {
    return (select(localPlaylists)
          ..where((t) => t.deleted.equals(true) & t.remoteId.isNotNull()))
        .get();
  }

  /// 标记歌单已同步并回填远端 id
  Future<void> markSynced(String localId, {int? remoteId}) async {
    await (update(localPlaylists)..where((t) => t.id.equals(localId))).write(
          LocalPlaylistsCompanion(
            remoteId: remoteId == null ? const Value.absent() : Value(remoteId),
            isSynced: const Value(true),
            syncedEver: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// 物理删除歌单（同步删除成功后调用，级联删歌曲）
  Future<void> removeRow(String localId) async {
    await (delete(localPlaylistSongs)..where((t) => t.playlistId.equals(localId))).go();
    await (delete(localPlaylists)..where((t) => t.id.equals(localId))).go();
  }

  /// 待推送的歌单歌曲（父歌单已回填远端 id 才处理，条件在 SyncService 判断）
  Future<List<LocalPlaylistSong>> pendingSongsToPush() async {
    return (select(localPlaylistSongs)
          ..where((t) => t.deleted.equals(false) & t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.playlistId), (t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// 待同步删除的歌单歌曲（已 soft delete 且曾同步过）
  Future<List<LocalPlaylistSong>> pendingSongsToDelete() async {
    return (select(localPlaylistSongs)
          ..where((t) => t.deleted.equals(true) & t.syncedEver.equals(true)))
        .get();
  }

  /// 标记歌单歌曲已同步
  Future<void> markSongSynced(int id, {int? remoteId}) async {
    await (update(localPlaylistSongs)..where((t) => t.id.equals(id))).write(
          LocalPlaylistSongsCompanion(
            remoteId: remoteId == null ? const Value.absent() : Value(remoteId),
            isSynced: const Value(true),
            syncedEver: const Value(true),
          ),
        );
  }

  /// 物理删除歌单歌曲（同步删除成功后调用）
  Future<void> removeSongRow(int id) async {
    await (delete(localPlaylistSongs)..where((t) => t.id.equals(id))).go();
  }
}
