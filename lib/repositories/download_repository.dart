import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/daos/download_dao.dart';
import '../models/song.dart';

/// 下载记录仓库（本地 SQLite，纯本地不同步）
///
/// 记录用户显式下载到 `下载/JoyTune/<歌名>-<歌手>/` 的歌曲元数据与本地路径；
/// watchAll() 提供流式数据源，已下载页订阅后自动响应。
class DownloadRepository {
  final DownloadDao _dao;

  DownloadRepository(this._dao);

  /// 流式监听全部下载记录（按下载时间倒序），转换为 Song 列表
  Stream<List<Song>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(_toSong).toList());
  }

  /// 一次性读取全部下载记录（按下载时间倒序）
  Future<List<Song>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toSong).toList();
  }

  /// 按 (song_id, source) 读取下载记录
  Future<LocalDownload?> getByKey(String songId, String source) {
    return _dao.getByKey(songId, source);
  }

  /// 是否已下载（存在记录且音频文件存在）
  Future<bool> isDownloaded(String songId, String source) {
    return _dao.isDownloaded(songId, source);
  }

  /// 记录一次下载（幂等覆盖同 (song_id, source)）
  Future<void> recordDownload({
    required Song song,
    required String folderPath,
    required String audioPath,
    String? coverPath,
    String? lyricsPath,
  }) {
    debugPrint('[DownloadRepo] record: ${song.name} → $audioPath');
    return _dao.upsert(
      song: song,
      folderPath: folderPath,
      audioPath: audioPath,
      coverPath: coverPath,
      lyricsPath: lyricsPath,
    );
  }

  /// 删除下载记录（DB 行；本地文件删除由调用方负责）
  Future<void> removeRecord(String songId, String source) {
    return _dao.remove(songId, source);
  }

  /// LocalDownload 数据行 → Song 模型
  Song _toSong(LocalDownload d) => Song(
        id: d.songId,
        source: d.source,
        name: d.name,
        artist: d.artist,
        album: d.album,
        picId: d.picId,
        lyricId: d.lyricId,
        coverUrl: d.coverUrl,
      );
}