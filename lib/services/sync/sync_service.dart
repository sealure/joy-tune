import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../api/backend_client.dart';
import '../../db/app_database.dart';
import '../../db/daos/favorite_dao.dart';
import '../../db/daos/play_record_dao.dart';
import '../../db/daos/playlist_dao.dart';
import '../../db/daos/playlist_follow_dao.dart';
import '../../db/daos/settings_dao.dart';
import '../../db/daos/song_meta_dao.dart';
import '../auth_service.dart';

/// 后台同步服务
///
/// 扫描本地需同步表中 is_synced=0 的记录，调用服务端 API 增量同步，成功后置 1。
/// 触发时机：启动 / 定时 / 网络恢复 / 登录成功后（syncNow）。
/// 游客态跳过推送（数据留本地，登录后再同步）。
class SyncService {
  final BackendClient _client;
  final AuthService _auth;
  final FavoriteDao _favoriteDao;
  final PlaylistDao _playlistDao;
  final PlaylistFollowDao _playlistFollowDao;
  final PlayRecordDao _playRecordDao;
  final SettingsDao _settingsDao;
  final SongMetaDao _songMetaDao;

  /// 非重入锁，防止并发同步
  bool _running = false;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// 401 时回调（由调用方注入，用于清 token 并置登录态）
  Future<void> Function()? onUnauthorized;

  SyncService({
    required BackendClient client,
    required AuthService auth,
    required FavoriteDao favoriteDao,
    required PlaylistDao playlistDao,
    required PlaylistFollowDao playlistFollowDao,
    required PlayRecordDao playRecordDao,
    required SettingsDao settingsDao,
    required SongMetaDao songMetaDao,
  })  : _client = client,
        _auth = auth,
        _favoriteDao = favoriteDao,
        _playlistDao = playlistDao,
        _playlistFollowDao = playlistFollowDao,
        _playRecordDao = playRecordDao,
        _settingsDao = settingsDao,
        _songMetaDao = songMetaDao;

  /// 启动后台同步任务：立即首扫 + 定时（30 秒，保证播放/收藏等写操作尽快同步）+ 网络恢复时
  void start({Duration interval = const Duration(seconds: 30)}) {
    // 立即首扫（不阻塞启动）
    syncNow();
    // 周期扫描
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
    // 网络恢复时触发同步（离线期间累积的 is_synced=0 数据补推）
    _connectivitySub ??=
        Connectivity().onConnectivityChanged.listen((_) => syncNow());
  }

  /// 停止定时任务与网络监听
  void stop() {
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// 手动触发一次同步。[forcePull] 时先从服务端拉取数据合并到本地
  Future<void> syncNow({bool forcePull = false}) async {
    if (_running) return;
    _running = true;
    try {
      // 游客不推送（数据留本地，登录后再推）
      final loggedIn = await _auth.isLoggedIn;
      if (!loggedIn) return;
      if (forcePull) {
        await _pullRemote();
      }
      await _pushFavorites();
      await _pushPlaylists();
      await _pushPlaylistSongs();
      await _pushPlaylistFollows();
      await _pushPlayRecords();
      await _handleClearHistory();
    } catch (e) {
      debugPrint('[SyncService] syncNow 异常: $e');
    } finally {
      _running = false;
    }
  }

  // ── 推送收藏 ──

  Future<void> _pushFavorites() async {
    // 先处理取消收藏（soft delete 且曾同步过的）
    final toDelete = await _favoriteDao.pendingToDelete();
    for (final f in toDelete) {
      final ok = await _client.unlikeSong(f.songId);
      if (ok?.success == true) {
        await _favoriteDao.removeRow(f.songId, f.source);
      }
    }
    // 再推送新增收藏
    final toPush = await _favoriteDao.pendingToPush();
    for (final f in toPush) {
      final ok = await _client.likeSong(
        f.songId,
        songName: f.name,
        artist: f.artist,
        source: f.source,
        album: f.album.isNotEmpty ? f.album : null,
        picId: f.picId,
        lyricId: f.lyricId,
      );
      if (ok?.success == true) {
        await _favoriteDao.markSynced(f.songId, f.source);
      }
    }
  }

  // ── 推送歌单 ──

  Future<void> _pushPlaylists() async {
    // 待创建/待更新的歌单（未删除且未同步）
    final pending = await _playlistDao.pendingPlaylists();
    for (final p in pending) {
      if (p.remoteId == null) {
        // 尚未创建：POST 创建并回填 remoteId
        final created = await _client.createPlaylist(
          name: p.name,
          description: p.description.isEmpty ? null : p.description,
          coverUrl: p.coverUrl.isEmpty ? null : p.coverUrl,
          isPublic: p.isPublic,
        );
        if (created != null) {
          await _playlistDao.markSynced(p.id, remoteId: created.id);
        }
      } else {
        // 已创建：PUT 更新信息
        final updated = await _client.updatePlaylist(
          p.remoteId!,
          name: p.name,
          description: p.description.isEmpty ? null : p.description,
          coverUrl: p.coverUrl.isEmpty ? null : p.coverUrl,
          isPublic: p.isPublic,
        );
        if (updated != null) {
          await _playlistDao.markSynced(p.id, remoteId: p.remoteId);
        }
      }
    }
    // 待删除的歌单（soft delete 且有远端 id）
    final toDelete = await _playlistDao.pendingDeletePlaylists();
    for (final p in toDelete) {
      final ok = await _client.deletePlaylist(p.remoteId!);
      if (ok) {
        await _playlistDao.removeRow(p.id);
      }
    }
  }

  // ── 推送歌单歌曲 ──

  Future<void> _pushPlaylistSongs() async {
    // 需父歌单已回填 remoteId 才能同步
    // 1) 先处理新增
    final toPush = await _playlistDao.pendingSongsToPush();
    for (final s in toPush) {
      final parent = await _playlistDao.getById(s.playlistId);
      if (parent?.remoteId == null) continue;
      final ok = await _client.addSongToPlaylist(
        parent!.remoteId!,
        songId: s.songId,
        songName: s.songName,
        artist: s.artist,
        album: s.album.isEmpty ? null : s.album,
        source: s.source,
        picId: s.picId,
        lyricId: s.lyricId,
      );
      if (ok) {
        await _playlistDao.markSongSynced(s.id);
      }
    }
    // 再删除（soft delete 且曾同步过）
    final toDelete = await _playlistDao.pendingSongsToDelete();
    for (final s in toDelete) {
      final parent = await _playlistDao.getById(s.playlistId);
      if (parent?.remoteId == null) continue;
      final ok = await _client.removeSongFromPlaylist(parent!.remoteId!, s.songId);
      if (ok) {
        await _playlistDao.removeSongRow(s.id);
      }
    }
  }

  // ── 推送收藏歌单（订阅引用）──

  Future<void> _pushPlaylistFollows() async {
    // 先处理取消收藏（soft delete 且曾同步过的）
    final toDelete = await _playlistFollowDao.pendingToDelete();
    for (final f in toDelete) {
      final ok = await _client.unfollowPlaylist(f.playlistId);
      debugPrint('[SyncService] 取消收藏歌单 unfollowPlaylist(${f.playlistId}) => $ok');
      if (ok) {
        await _playlistFollowDao.removeRow(f.playlistId);
      }
    }
    // 再推送新增收藏
    final toPush = await _playlistFollowDao.pendingToPush();
    debugPrint('[SyncService] 收藏歌单待推送: ${toPush.map((f) => f.playlistId).toList()}');
    for (final f in toPush) {
      final ok = await _client.followPlaylist(f.playlistId);
      debugPrint('[SyncService] 收藏歌单 followPlaylist(${f.playlistId}) => $ok');
      if (ok) {
        await _playlistFollowDao.markSynced(f.playlistId);
      }
    }
  }

  // ── 推送播放记录 ──

  Future<void> _pushPlayRecords() async {
    final pending = await _playRecordDao.pendingToPush();
    for (final r in pending) {
      // lyric_id 兜底：本地播放记录为空时，从歌曲元数据缓存取（播放时已解析回填过）
      var lyricId = r.lyricId;
      if (lyricId == null || lyricId.isEmpty) {
        final meta = await _songMetaDao.get(r.songId, r.source);
        lyricId = meta?.lyricId;
      }
      print('[SyncService] 上报播放: song=${r.songId} source=${r.source} lyricId=${lyricId ?? "空"}');
      final ok = await _client.reportPlay(
        r.songId,
        source: r.source,
        songName: r.songName,
        artist: r.artist,
        album: r.album.isEmpty ? null : r.album,
        picId: r.picId,
        lyricId: lyricId,
      );
      if (ok) {
        await _playRecordDao.markSynced(r.id);
      } else {
        await _playRecordDao.incrementAttempt(r.id);
      }
    }
  }

  // ── 清空播放历史（同步清服务端）──

  Future<void> _handleClearHistory() async {
    final pending = await _settingsDao.get('pending_clear_play_history');
    if (pending != 'true') return;
    final ok = await _client.clearPlayHistory();
    if (ok) {
      await _settingsDao.remove('pending_clear_play_history');
    }
  }

  // ── 拉取服务端数据合并到本地（登录后首次）──

  Future<void> _pullRemote() async {
    await _pullFavorites();
    await _pullPlaylists();
    await _pullFollowedPlaylists();
  }

  /// 拉取远端收藏歌单并合并到本地（幂等更新元信息：创建者/歌曲数/封面跟随服务端）
  Future<void> _pullFollowedPlaylists() async {
    final remote = await _client.getFollowedPlaylists();
    for (final p in remote) {
      await _playlistFollowDao.insertFollow(
        playlistId: p.id,
        name: p.name,
        description: p.description,
        coverUrl: p.coverUrl,
        ownerNickname: p.ownerNickname,
        ownerAvatarUrl: p.ownerAvatarUrl,
        songCount: p.songCount,
      );
      await _playlistFollowDao.markSynced(p.id);
    }
  }

  /// 拉取远端收藏并合并到本地（本地优先：已存在的本地收藏不覆盖）
  Future<void> _pullFavorites() async {
    final remote = await _client.getUserLikedSongs();
    for (final song in remote) {
      final exists = await _favoriteDao.isFavorited(song.id, song.source);
      if (!exists) {
        await _favoriteDao.insertFavorite(song);
        await _favoriteDao.markSynced(song.id, song.source);
      }
    }
  }

  /// 拉取远端歌单并合并到本地（服务端→客户端）
  /// 本地已有同 remoteId 的歌单则复用，否则新建；随后拉取该歌单的歌曲并入本地
  Future<void> _pullPlaylists() async {
    final remote = await _client.getUserPlaylists();
    final locals = await _playlistDao.getAll();
    for (final p in remote) {
      final existing = locals.where((l) => l.remoteId == p.id).toList();
      final localId = existing.isNotEmpty ? existing.first.id : _newLocalId();
      if (existing.isEmpty) {
        await _playlistDao.create(LocalPlaylistsCompanion.insert(
          id: localId,
          name: p.name,
          description: drift.Value(p.description),
          coverUrl: drift.Value(p.coverUrl),
          isPublic: drift.Value(p.isPublic),
        ));
        await _playlistDao.markSynced(localId, remoteId: p.id);
      }
      // 拉取该歌单的歌曲并入本地（补齐"服务端→客户端"方向）
      await _pullPlaylistSongs(localId, p.id);
    }
  }

  /// 拉取单个远端歌单的歌曲并入本地（本地优先：已存在的本地歌曲跳过，不覆盖未同步新增）
  Future<void> _pullPlaylistSongs(String localId, int remoteId) async {
    final detail = await _client.getUserPlaylistDetail(remoteId);
    if (detail == null) return;
    var order = 0;
    for (final s in detail.songs) {
      await _playlistDao.mergeRemoteSong(
        playlistId: localId,
        songId: s.songId,
        source: s.source,
        songName: s.songName,
        artist: s.artist,
        album: s.album,
        picId: s.picId.isNotEmpty ? s.picId : null,
        lyricId: s.lyricId.isNotEmpty ? s.lyricId : null,
        sortOrder: order++,
      );
    }
  }

  /// 生成本地歌单 UUID
  String _newLocalId() => const Uuid().v4();
}