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
  LocalLyricsCache,
])
class AppDatabase extends _$AppDatabase {
  /// 默认构造：drift_flutter 统一移动端原生 + 桌面端 ffi
  AppDatabase() : super(driftDatabase(name: 'via_music'));

  /// 测试构造：使用内存数据库（纯 Dart VM，无需平台通道）
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2：歌单歌曲/播放记录新增 lyric_id、播放记录新增 pic_id（音源原始 ID，供实时解析歌词/封面）
          if (from < 2) {
            await m.addColumn(localPlaylistSongs, localPlaylistSongs.lyricId);
            await m.addColumn(localPlayRecords, localPlayRecords.lyricId);
            await m.addColumn(localPlayRecords, localPlayRecords.picId);
          }
          // v3：新增本地歌词缓存表（播放后回填歌词）
          if (from < 3) {
            await m.createTable(localLyricsCache);
          }
        },
      );
}
