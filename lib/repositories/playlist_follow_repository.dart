import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/daos/playlist_follow_dao.dart';

// ── 收藏歌单 UI 模型 ──

/// 收藏歌单列表项（本地，引用服务端歌单）
class LocalPlaylistFollowInfo {
  /// 服务端歌单 id（收藏的源歌单）
  final int playlistId;
  /// 歌单名称
  final String name;
  /// 封面 URL
  final String coverUrl;
  /// 封面来源歌曲 pic_id（为空则按 coverUrl 或占位图；非空则客户端实时解析封面）
  final String? coverPicId;
  /// 封面来源歌曲音源标识
  final String? coverSource;
  /// 创建者昵称（同步拉取后补全）
  final String ownerNickname;
  /// 创建者头像 URL
  final String ownerAvatarUrl;
  /// 歌曲数（收藏时快照，同步拉取后刷新）
  final int songCount;
  /// 收藏时间
  final DateTime createdAt;
  /// 是否已同步到服务端（false=离线收藏待同步）
  final bool synced;

  const LocalPlaylistFollowInfo({
    required this.playlistId,
    this.name = '',
    this.coverUrl = '',
    this.coverPicId,
    this.coverSource,
    this.ownerNickname = '',
    this.ownerAvatarUrl = '',
    this.songCount = 0,
    required this.createdAt,
    this.synced = true,
  });
}

/// 收藏歌单仓库（本地 SQLite 实现）
///
/// 收藏动作先写本地（is_synced=0），SyncService 登录后推送 POST /playlists/{id}/follow；
/// 取消收藏 soft delete，曾同步过的走 DELETE /playlists/{id}/follow 清算。
class PlaylistFollowRepository {
  final PlaylistFollowDao _dao;

  PlaylistFollowRepository(this._dao);

  /// 流式监听全部已收藏歌单
  Stream<List<LocalPlaylistFollowInfo>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(_toInfo).toList());
  }

  /// 一次性读取全部已收藏歌单
  Future<List<LocalPlaylistFollowInfo>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toInfo).toList();
  }

  /// 是否已收藏某歌单
  Future<bool> isFollowed(int playlistId) => _dao.isFollowed(playlistId);

  /// 收藏歌单（写本地，等待后台同步到服务端）
  Future<void> follow({
    required int playlistId,
    String name = '',
    String description = '',
    String coverUrl = '',
    String? coverPicId,
    String? coverSource,
    String ownerNickname = '',
    String ownerAvatarUrl = '',
    int songCount = 0,
  }) {
    debugPrint('[FollowRepo] follow: playlistId=$playlistId, name=$name');
    return _dao.insertFollow(
      playlistId: playlistId,
      name: name,
      description: description,
      coverUrl: coverUrl,
      coverPicId: coverPicId,
      coverSource: coverSource,
      ownerNickname: ownerNickname,
      ownerAvatarUrl: ownerAvatarUrl,
      songCount: songCount,
    );
  }

  /// 同步拉取远端后补全元信息（创建者/歌曲数/封面）
  Future<void> updateMeta({
    required int playlistId,
    String? name,
    String? description,
    String? coverUrl,
    String? coverPicId,
    String? coverSource,
    String? ownerNickname,
    String? ownerAvatarUrl,
    int? songCount,
  }) {
    return _dao.updateMeta(
      playlistId: playlistId,
      name: name,
      description: description,
      coverUrl: coverUrl,
      coverPicId: coverPicId,
      coverSource: coverSource,
      ownerNickname: ownerNickname,
      ownerAvatarUrl: ownerAvatarUrl,
      songCount: songCount,
    );
  }

  /// 取消收藏（soft delete，同步任务清算）
  Future<void> remove(int playlistId) {
    debugPrint('[FollowRepo] remove: playlistId=$playlistId');
    return _dao.softDelete(playlistId);
  }

  /// 数据行 → 列表项
  LocalPlaylistFollowInfo _toInfo(LocalPlaylistFollow row) => LocalPlaylistFollowInfo(
        playlistId: row.playlistId,
        name: row.name,
        coverUrl: row.coverUrl,
        coverPicId: row.coverPicId,
        coverSource: row.coverSource,
        ownerNickname: row.ownerNickname,
        ownerAvatarUrl: row.ownerAvatarUrl,
        songCount: row.songCount,
        createdAt: row.createdAt,
        synced: row.isSynced,
      );
}
