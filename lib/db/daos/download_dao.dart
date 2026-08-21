import 'dart:io';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';
import '../../models/song.dart';

part 'download_dao.g.dart';

/// 下载记录数据访问对象（纯本地表：local_downloads）
/// 记录用户显式下载到 `下载/JoyTune/<歌名>-<歌手>/` 的歌曲，
/// 与应用缓存独立：清理缓存不触碰下载文件。
@DriftAccessor(tables: [LocalDownloads])
class DownloadDao extends DatabaseAccessor<AppDatabase> with _$DownloadDaoMixin {
  DownloadDao(super.attachedDatabase);

  /// 按 (song_id, source) 读取下载记录，无则 null
  Future<LocalDownload?> getByKey(String songId, String source) async {
    return (select(localDownloads)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .getSingleOrNull();
  }

  /// 是否已下载（按 (song_id, source)）
  Future<bool> isDownloaded(String songId, String source) async {
    final row = await getByKey(songId, source);
    return row != null && File(row.audioPath).existsSync();
  }

  /// 插入下载记录（按 (song_id, source) 幂等覆盖）
  Future<void> upsert({
    required Song song,
    required String folderPath,
    required String audioPath,
    String? coverPath,
    String? lyricsPath,
  }) async {
    await into(localDownloads).insertOnConflictUpdate(
      LocalDownloadsCompanion.insert(
        songId: song.id,
        source: song.source,
        name: song.name,
        artist: song.artist,
        album: Value(song.album),
        picId: Value(song.picId),
        lyricId: Value(song.lyricId),
        coverUrl: Value(song.coverUrl),
        folderPath: folderPath,
        audioPath: audioPath,
        coverPath: Value(coverPath),
        lyricsPath: Value(lyricsPath),
      ),
    );
  }

  /// 流式监听全部下载记录（按下载时间倒序）
  Stream<List<LocalDownload>> watchAll() {
    return (select(localDownloads)
          ..orderBy([(t) => OrderingTerm.desc(t.downloadedAt)]))
        .watch();
  }

  /// 一次性读取全部下载记录（按下载时间倒序）
  Future<List<LocalDownload>> getAll() async {
    return (select(localDownloads)
          ..orderBy([(t) => OrderingTerm.desc(t.downloadedAt)]))
        .get();
  }

  /// 删除下载记录（仅删 DB 行，不删本地文件；文件删除由调用方负责）
  Future<void> remove(String songId, String source) async {
    await (delete(localDownloads)
          ..where((t) => t.songId.equals(songId) & t.source.equals(source)))
        .go();
  }
}