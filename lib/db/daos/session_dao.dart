import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'session_dao.g.dart';

/// 播放会话单行主键
const _sessionRowId = 1;

/// 播放会话数据访问对象（纯本地表：local_play_sessions，单行 id=1）
@DriftAccessor(tables: [LocalPlaySessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.attachedDatabase);

  /// 保存播放会话（单行 upsert：队列 JSON + 索引 + 进度 + 模式）
  Future<void> saveSession({
    String? queueJson,
    int currentIndex = 0,
    int positionMs = 0,
    String playMode = 'loop',
  }) async {
    await into(localPlaySessions).insertOnConflictUpdate(
      LocalPlaySessionsCompanion.insert(
        id: Value(_sessionRowId),
        queueJson: Value(queueJson),
        currentIndex: Value(currentIndex),
        positionMs: Value(positionMs),
        playMode: Value(playMode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 读取播放会话，无则返回 null
  Future<LocalPlaySession?> loadSession() async {
    return (select(localPlaySessions)..where((t) => t.id.equals(_sessionRowId)))
        .getSingleOrNull();
  }

  /// 清除播放会话
  Future<void> clearSession() async {
    await (delete(localPlaySessions)..where((t) => t.id.equals(_sessionRowId))).go();
  }
}
