import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'song_meta_dao.g.dart';

/// 歌曲元数据缓存数据访问对象（纯本地表：local_song_meta）
/// 统一缓存封面 URL / 歌词 ID / 歌词全文（key = song_id + source），
/// 封面、歌词读取统一走此表，播放解析结果回填。
@DriftAccessor(tables: [LocalSongMeta])
class SongMetaDao extends DatabaseAccessor<AppDatabase> with _$SongMetaDaoMixin {
  SongMetaDao(super.attachedDatabase);

  /// 读取缓存的歌曲元数据，无则 null
  Future<LocalSongMetaData?> get(String songId, String source) async {
    return (select(localSongMeta)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .getSingleOrNull();
  }

  /// 读取缓存的歌词全文，无则 null
  Future<String?> getLyrics(String songId, String source) async {
    final row = await get(songId, source);
    final lyrics = row?.lyrics;
    return (lyrics == null || lyrics.isEmpty) ? null : lyrics;
  }

  /// 读取缓存的封面 URL，无则 null
  Future<String?> getCoverUrl(String songId, String source) async {
    final row = await get(songId, source);
    final url = row?.coverUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// 回填/更新歌曲元数据缓存（按 (song_id, source) upsert，仅非空字段覆盖）
  Future<void> upsert({
    required String songId,
    required String source,
    String name = '',
    String artist = '',
    String album = '',
    String? picId,
    String? lyricId,
    String? coverUrl,
    String? lyrics,
  }) async {
    await into(localSongMeta).insertOnConflictUpdate(
      LocalSongMetaCompanion.insert(
        songId: songId,
        source: source,
        name: Value(name),
        artist: Value(artist),
        album: Value(album),
        picId: Value(picId),
        lyricId: Value(lyricId),
        coverUrl: Value(coverUrl),
        lyrics: Value(lyrics),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 清空歌曲元数据缓存
  Future<void> clearAll() async {
    await (delete(localSongMeta)).go();
  }
}
