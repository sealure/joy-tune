import '../api/backend_client.dart';
import '../db/app_database.dart';
import '../db/daos/play_record_dao.dart';
import '../models/song.dart';

/// 播放记录仓库（本地 SQLite 实现）
///
/// 播放成功先写本地（is_synced=0），由 SyncService 登录后上报服务端；
/// 播放历史列表从本地读取，游客也可记录，登录后自动合并。
class PlayRecordRepository {
  final PlayRecordDao _dao;

  PlayRecordRepository(this._dao);

  /// 记录一次播放
  Future<void> addRecord(Song song) => _dao.addRecord(song);

  /// 流式监听全部播放记录（按播放时间倒序）
  Stream<List<PlayHistoryItem>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(_toItem).toList());
  }

  /// 一次性读取全部播放记录
  Future<List<PlayHistoryItem>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toItem).toList();
  }

  /// 清空全部播放记录
  Future<void> clear() => _dao.clearAll();

  /// 本地数据行 → 播放历史模型
  PlayHistoryItem _toItem(LocalPlayRecord r) => PlayHistoryItem(
        songId: r.songId,
        songName: r.songName,
        artist: r.artist,
        coverUrl: r.coverUrl ?? '',
        source: r.source,
        album: r.album,
        lyricId: r.lyricId ?? '',
        playedAt: r.playedAt,
      );
}
