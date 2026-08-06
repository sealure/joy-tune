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
  LocalSongMeta,
  LocalPlaylistFollows,
  LocalRecommendPlaylists,
  LocalRecommendPlaylistSongs,
  LocalPicCovers,
])
class AppDatabase extends _$AppDatabase {
  /// 默认构造：drift_flutter 统一移动端原生 + 桌面端 ffi
  AppDatabase() : super(driftDatabase(name: 'joy_tune'));

  /// 测试构造：使用内存数据库（纯 Dart VM，无需平台通道）
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

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
          // v4：统一歌曲元数据缓存表 local_song_meta（封面/歌词/lyric_id 缓存统一来源）
          if (from < 4) {
            await m.createTable(localSongMeta);
            // 开发期的 local_lyrics_cache 表废弃，残留不影响使用（不再读写）
          }
          // v5：新增本地收藏歌单表 local_playlist_follows（订阅他人公开歌单）
          if (from < 5) {
            await m.createTable(localPlaylistFollows);
          }
          // v6：新增推荐歌单缓存表 local_recommend_playlists / 歌曲缓存表（只读下行，SyncService 异步拉取覆盖）
          if (from < 6) {
            await m.createTable(localRecommendPlaylists);
            await m.createTable(localRecommendPlaylistSongs);
          }
          // v7：歌单/收藏歌单/推荐歌单新增封面来源字段 cover_pic_id + cover_source；
          //     新增封面解析结果缓存表 local_pic_covers（按 pic_id+source，重启免外部 API）
          if (from < 7) {
            await m.addColumn(localPlaylists, localPlaylists.coverPicId);
            await m.addColumn(localPlaylists, localPlaylists.coverSource);
            await m.addColumn(localPlaylistFollows, localPlaylistFollows.coverPicId);
            await m.addColumn(localPlaylistFollows, localPlaylistFollows.coverSource);
            await m.addColumn(localRecommendPlaylists, localRecommendPlaylists.coverPicId);
            await m.addColumn(localRecommendPlaylists, localRecommendPlaylists.coverSource);
            await m.createTable(localPicCovers);
          }
        },
      );
}
