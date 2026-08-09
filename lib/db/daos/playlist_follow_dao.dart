import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'playlist_follow_dao.g.dart';

/// 收藏歌单数据访问对象（需同步表：local_playlist_follows）
/// 收藏 = 订阅引用，主键为服务端歌单 id；收藏/取消先写本地，SyncService 登录后同步服务端。
@DriftAccessor(tables: [LocalPlaylistFollows])
class PlaylistFollowDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistFollowDaoMixin {
  PlaylistFollowDao(super.attachedDatabase);

  /// 清空全部收藏的歌单（退出登录/登录失效时调用，重新登录后由 syncNow(forcePull) 拉回）
  Future<void> clearAll() async {
    await (delete(localPlaylistFollows)).go();
  }

  /// 收藏歌单（幂等）：不存在则插入；已 soft delete 则恢复并置顶（deleted=0、is_synced=0）
  Future<void> insertFollow({
    required int playlistId,
    String name = '',
    String description = '',
    String coverUrl = '',
    String? coverPicId,
    String? coverSource,
    String ownerNickname = '',
    String ownerAvatarUrl = '',
    int songCount = 0,
  }) async {
    final existing = await (select(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .getSingleOrNull();
    if (existing == null) {
      await into(localPlaylistFollows).insert(
        LocalPlaylistFollowsCompanion.insert(
          playlistId: Value(playlistId),
          name: Value(name),
          description: Value(description),
          coverUrl: Value(coverUrl),
          coverPicId: Value(coverPicId),
          coverSource: Value(coverSource),
          ownerNickname: Value(ownerNickname),
          ownerAvatarUrl: Value(ownerAvatarUrl),
          songCount: Value(songCount),
        ),
      );
    } else if (existing.deleted) {
      // 恢复已取消收藏的歌单（重新收藏置顶）
      await (update(localPlaylistFollows)
            ..where((t) => t.playlistId.equals(playlistId)))
          .write(
            LocalPlaylistFollowsCompanion(
              deleted: const Value(false),
              isSynced: const Value(false),
              name: Value(name),
              description: Value(description),
              coverUrl: Value(coverUrl),
              coverPicId: Value(coverPicId),
              coverSource: Value(coverSource),
              ownerNickname: Value(ownerNickname),
              ownerAvatarUrl: Value(ownerAvatarUrl),
              songCount: Value(songCount),
              createdAt: Value(DateTime.now()),
            ),
          );
    }
  }

  /// 同步拉取远端后补全元信息（创建者/歌曲数/封面），不重置已同步状态
  Future<void> updateMeta({
    required int playlistId,
    String? name,
    String? description,
    String? coverUrl,
    String? coverPicId,
    String? coverSource,
    String? ownerNickname,
    String? ownerAvatarUrl,
    int? songCount,
  }) async {
    await (update(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .write(
          LocalPlaylistFollowsCompanion(
            name: name == null ? const Value.absent() : Value(name),
            description: description == null ? const Value.absent() : Value(description),
            coverUrl: coverUrl == null ? const Value.absent() : Value(coverUrl),
            coverPicId: coverPicId == null ? const Value.absent() : Value(coverPicId),
            coverSource: coverSource == null ? const Value.absent() : Value(coverSource),
            ownerNickname:
                ownerNickname == null ? const Value.absent() : Value(ownerNickname),
            ownerAvatarUrl:
                ownerAvatarUrl == null ? const Value.absent() : Value(ownerAvatarUrl),
            songCount: songCount == null ? const Value.absent() : Value(songCount),
          ),
        );
  }

  /// 取消收藏（soft delete）：曾同步过的标记待同步删除；从未同步过的直接物理删除
  Future<void> softDelete(int playlistId) async {
    final existing = await (select(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .getSingleOrNull();
    if (existing == null) return;
    if (existing.syncedEver) {
      await (update(localPlaylistFollows)
            ..where((t) => t.playlistId.equals(playlistId)))
          .write(
            LocalPlaylistFollowsCompanion(
              deleted: const Value(true),
              isSynced: const Value(false),
            ),
          );
    } else {
      await (delete(localPlaylistFollows)
            ..where((t) => t.playlistId.equals(playlistId)))
          .go();
    }
  }

  /// 是否已收藏（忽略 soft delete 标记）
  Future<bool> isFollowed(int playlistId) async {
    final existing = await (select(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .getSingleOrNull();
    return existing != null && !existing.deleted;
  }

  /// 流式监听全部未删除收藏歌单（按收藏时间倒序）
  Stream<List<LocalPlaylistFollow>> watchAll() {
    return (select(localPlaylistFollows)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 一次性读取全部未删除收藏歌单
  Future<List<LocalPlaylistFollow>> getAll() async {
    return (select(localPlaylistFollows)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 待推送的收藏歌单（未删除且未同步）
  Future<List<LocalPlaylistFollow>> pendingToPush() async {
    return (select(localPlaylistFollows)
          ..where((t) => t.deleted.equals(false) & t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 待同步删除的收藏歌单（已 soft delete 且曾同步过）
  Future<List<LocalPlaylistFollow>> pendingToDelete() async {
    return (select(localPlaylistFollows)
          ..where((t) => t.deleted.equals(true) & t.syncedEver.equals(true)))
        .get();
  }

  /// 标记收藏已同步
  Future<void> markSynced(int playlistId) async {
    await (update(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .write(
          LocalPlaylistFollowsCompanion(
            isSynced: const Value(true),
            syncedEver: const Value(true),
          ),
        );
  }

  /// 物理删除一条收藏（同步删除成功后调用）
  Future<void> removeRow(int playlistId) async {
    await (delete(localPlaylistFollows)
          ..where((t) => t.playlistId.equals(playlistId)))
        .go();
  }
}
