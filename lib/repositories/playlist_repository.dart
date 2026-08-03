import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../api/backend_client.dart';
import '../db/app_database.dart';
import '../db/daos/playlist_dao.dart';
import '../models/song.dart';

// ── 本地歌单 UI 模型 ──

/// 歌单列表项（本地）
class LocalPlaylistInfo {
  /// 本地 UUID 主键
  final String localId;
  /// 服务端 id（同步成功后回填，null 表示尚未同步）
  final int? remoteId;
  /// 歌单名称
  final String name;
  /// 描述
  final String description;
  /// 封面 URL
  final String coverUrl;
  /// 是否公开
  final bool isPublic;
  /// 未删除歌曲数
  final int songCount;
  /// 创建时间
  final DateTime createdAt;

  const LocalPlaylistInfo({
    required this.localId,
    this.remoteId,
    this.name = '',
    this.description = '',
    this.coverUrl = '',
    this.isPublic = false,
    this.songCount = 0,
    required this.createdAt,
  });

  /// 是否已同步到服务端（分享等依赖 remoteId 的操作用它判断）
  bool get synced => remoteId != null;
}

/// 歌单内的歌曲项（本地 play order + 元信息）
class LocalPlaylistSongInfo {
  /// 本地行自增 id
  final int rowId;
  /// 所属歌单本地 id
  final String playlistId;
  /// 歌曲 ID
  final String songId;
  /// 音源
  final String source;
  /// 歌曲名
  final String songName;
  /// 歌手
  final String artist;
  /// 专辑
  final String album;
  /// 封面 URL
  final String? coverUrl;
  /// 封面 pic_id
  final String? picId;
  /// 歌词 ID（音源原始歌词 ID，实时解析歌词）
  final String? lyricId;
  /// 本地排序序号
  final int sortOrder;

  const LocalPlaylistSongInfo({
    required this.rowId,
    required this.playlistId,
    required this.songId,
    required this.source,
    this.songName = '',
    this.artist = '',
    this.album = '',
    this.coverUrl,
    this.picId,
    this.lyricId,
    this.sortOrder = 0,
  });

  /// 转为可播放的 Song 模型
  Song toSong() => Song(
        id: songId,
        source: source,
        name: songName,
        artist: artist,
        album: album,
        coverUrl: coverUrl,
        picId: picId,
        lyricId: lyricId,
      );
}

/// 歌单仓库（本地 SQLite 实现）
///
/// 歌单先写本地（本地 UUID 主键，is_synced=0），SyncService 登录后同步到服务端，
/// 创建成功回填 remoteId。分享等依赖 remoteId 的操作需在 synced 后可用。
class PlaylistRepository {
  final PlaylistDao _dao;
  final BackendClient _client;

  PlaylistRepository(this._dao, this._client);

  /// 流式监听全部未删除歌单（带歌曲数）
  Stream<List<LocalPlaylistInfo>> watchAll() {
    return _dao.watchAllWithCount().map(
          (rows) => rows.map((row) => _toInfo(row.playlist, row.songCount)).toList(),
        );
  }

  /// 流式监听单个歌单
  Stream<LocalPlaylistInfo?> watchById(String localId) {
    return _dao
        .watchById(localId)
        .map((p) => p == null ? null : _toInfo(p, 0));
  }

  /// 流式监听歌单内未删除歌曲
  Stream<List<LocalPlaylistSongInfo>> watchSongs(String localId) {
    return _dao.watchSongs(localId).map((rows) => rows.map(_toSongInfo).toList());
  }

  /// 一次性读取单个歌单
  Future<LocalPlaylistInfo?> getById(String localId) async {
    final p = await _dao.getById(localId);
    return p == null ? null : _toInfo(p, 0);
  }

  /// 创建歌单，返回本地 UUID
  Future<String> create({
    required String name,
    String description = '',
    String coverUrl = '',
    bool isPublic = false,
  }) async {
    final localId = const Uuid().v4();
    debugPrint('[PlaylistRepo] create: localId=$localId, name=$name');
    await _dao.create(daoCompanion(
      localId: localId,
      name: name,
      description: description,
      coverUrl: coverUrl,
      isPublic: isPublic,
    ));
    return localId;
  }

  /// 更新歌单信息（标记待同步）
  Future<void> update(
    String localId, {
    String? name,
    String? description,
    String? coverUrl,
    bool? isPublic,
  }) {
    debugPrint('[PlaylistRepo] update: localId=$localId');
    return _dao.updatePlaylist(
      localId,
      name: name,
      description: description,
      coverUrl: coverUrl,
      isPublic: isPublic,
    );
  }

  /// 删除歌单（soft delete，同步任务清算）
  Future<void> delete(String localId) {
    debugPrint('[PlaylistRepo] delete: localId=$localId');
    return _dao.softDelete(localId);
  }

  /// 创建"已同步"歌单（复制歌单功能用）：服务端已创建副本，本地直接建行并回填 remoteId
  Future<String> createSynced({
    required int remoteId,
    required String name,
    String description = '',
    String coverUrl = '',
    bool isPublic = false,
  }) async {
    final localId = const Uuid().v4();
    debugPrint('[PlaylistRepo] createSynced: localId=$localId, remoteId=$remoteId, name=$name');
    await _dao.create(LocalPlaylistsCompanion.insert(
      id: localId,
      name: name,
      description: drift.Value(description),
      coverUrl: drift.Value(coverUrl),
      isPublic: drift.Value(isPublic),
      remoteId: drift.Value(remoteId),
      isSynced: const drift.Value(true),
      syncedEver: const drift.Value(true),
    ));
    return localId;
  }

  /// 拉取远端歌单歌曲并入本地（复制歌单功能用：副本已建行，拉歌曲灌入，本地优先）
  Future<void> pullRemoteSongs(String localId, int remoteId) async {
    final detail = await _client.getUserPlaylistDetail(remoteId);
    if (detail == null) return;
    var order = 0;
    for (final s in detail.songs) {
      await _dao.mergeRemoteSong(
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

  /// 往歌单添加歌曲
  Future<void> addSong(String localId, Song song) {
    debugPrint('[PlaylistRepo] addSong: localId=$localId, song=${song.id}');
    return _dao.addSong(
      playlistId: localId,
      songId: song.id,
      source: song.source,
      songName: song.name,
      artist: song.artist,
      album: song.album,
      coverUrl: song.coverUrl,
      picId: song.picId,
      lyricId: song.lyricId,
    );
  }

  /// 从歌单移除歌曲
  Future<void> removeSong(String localId, String songId, String source) {
    debugPrint('[PlaylistRepo] removeSong: localId=$localId, song=$songId');
    return _dao.softDeleteSong(localId, songId, source);
  }

  /// 歌单内歌曲排序（仅本地 sortOrder）
  Future<void> reorder(String localId, List<String> songIdsInOrder) {
    return _dao.reorder(localId, songIdsInOrder);
  }

  /// 构造歌单插入数据（供 DAO 使用）
  LocalPlaylistsCompanion daoCompanion({
    required String localId,
    required String name,
    String description = '',
    String coverUrl = '',
    bool isPublic = false,
  }) =>
      LocalPlaylistsCompanion.insert(
        id: localId,
        name: name,
        description: drift.Value(description),
        coverUrl: drift.Value(coverUrl),
        isPublic: drift.Value(isPublic),
      );

  /// 数据行 → 列表项
  LocalPlaylistInfo _toInfo(LocalPlaylist p, int songCount) => LocalPlaylistInfo(
        localId: p.id,
        remoteId: p.remoteId,
        name: p.name,
        description: p.description,
        coverUrl: p.coverUrl,
        isPublic: p.isPublic,
        songCount: songCount,
        createdAt: p.createdAt,
      );

  /// 数据行 → 歌曲项
  LocalPlaylistSongInfo _toSongInfo(LocalPlaylistSong s) => LocalPlaylistSongInfo(
        rowId: s.id,
        playlistId: s.playlistId,
        songId: s.songId,
        source: s.source,
        songName: s.songName,
        artist: s.artist,
        album: s.album,
        coverUrl: s.coverUrl,
        picId: s.picId,
        lyricId: s.lyricId,
        sortOrder: s.sortOrder,
      );
}