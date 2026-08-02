import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// 客户端本地数据库（drift/SQLite）
///
/// 结构化数据统一落本地：需同步表带 is_synced 标记，由 SyncService 后台增量同步；
/// 纯本地表（搜索历史/播放会话/设置）不带同步标记。
@DriftDatabase(tables: [
  LocalFavorites,
  LocalPlaylists,
  LocalPlaylistSongs,
  LocalPlayRecords,
  LocalSearchHistory,
  LocalPlaySessions,
  LocalSettings,
])
class AppDatabase extends _$AppDatabase {
  /// 默认构造：drift_flutter 统一移动端原生 + 桌面端 ffi
  AppDatabase() : super(driftDatabase(name: 'via_music'));

  /// 测试构造：使用内存数据库（纯 Dart VM，无需平台通道）
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        // v2 起在此迁移
        onUpgrade: (m, from, to) async {},
      );
}
