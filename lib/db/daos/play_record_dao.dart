import 'package:drift/drift.dart';

import '../../models/song.dart';
import '../app_database.dart';
import '../tables.dart';

part 'play_record_dao.g.dart';

/// 播放记录数据访问对象（需同步表：local_play_records）
@DriftAccessor(tables: [LocalPlayRecords])
class PlayRecordDao extends DatabaseAccessor<AppDatabase>
    with _$PlayRecordDaoMixin {
  PlayRecordDao(super.attachedDatabase);

  /// 记录一次播放（is_synced=0，等待同步上报）
  Future<void> addRecord(Song song) async {
    await into(localPlayRecords).insert(LocalPlayRecordsCompanion.insert(
      songId: song.id,
      source: Value(song.source),
      songName: Value(song.name),
      artist: Value(song.artist),
      album: Value(song.album),
      coverUrl: Value(song.coverUrl),
      picId: Value(song.picId),
      lyricId: Value(song.lyricId),
    ));
  }

  /// 流式监听全部播放记录（按播放时间倒序）
  Stream<List<LocalPlayRecord>> watchAll() {
    return (select(localPlayRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt), (t) => OrderingTerm.desc(t.id)]))
        .watch();
  }

  /// 一次性读取全部播放记录（按播放时间倒序）
  Future<List<LocalPlayRecord>> getAll() async {
    return (select(localPlayRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.playedAt), (t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  /// 待上报的播放记录（未同步且尝试次数未超限，按 id 升序保证后端顺序=本地时间顺序）
  Future<List<LocalPlayRecord>> pendingToPush() async {
    return (select(localPlayRecords)
          ..where((t) => t.isSynced.equals(false) & t.attemptCount.isSmallerThanValue(10))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  /// 标记已同步
  Future<void> markSynced(int id) async {
    await (update(localPlayRecords)..where((t) => t.id.equals(id))).write(
          LocalPlayRecordsCompanion(isSynced: const Value(true)),
        );
  }

  /// 同步失败，尝试次数 +1（读当前值再加一写回，避免表达式类型问题）
  Future<void> incrementAttempt(int id) async {
    final row = await (select(localPlayRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (update(localPlayRecords)..where((t) => t.id.equals(id))).write(
          LocalPlayRecordsCompanion(attemptCount: Value(row.attemptCount + 1)),
        );
  }

  /// 清空全部播放记录
  Future<void> clearAll() async {
    await (delete(localPlayRecords)).go();
  }
}
