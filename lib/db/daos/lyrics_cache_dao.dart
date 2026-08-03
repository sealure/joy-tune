import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'lyrics_cache_dao.g.dart';

/// 歌词缓存数据访问对象（纯本地表：local_lyrics_cache）
@DriftAccessor(tables: [LocalLyricsCache])
class LyricsCacheDao extends DatabaseAccessor<AppDatabase>
    with _$LyricsCacheDaoMixin {
  LyricsCacheDao(super.attachedDatabase);

  /// 读取缓存的歌词，无则 null
  Future<String?> get(String songId, String source) async {
    final row = await (select(localLyricsCache)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .getSingleOrNull();
    return row?.lyrics;
  }

  /// 回填歌词（播放解析成功后调用，按 (song_id, source) upsert）
  Future<void> save(String songId, String source, String lyrics) async {
    await into(localLyricsCache).insertOnConflictUpdate(
      LocalLyricsCacheCompanion.insert(
        songId: songId,
        source: source,
        lyrics: lyrics,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 清空歌词缓存
  Future<void> clearAll() async {
    await (delete(localLyricsCache)).go();
  }
}
