// 后端 API 收藏仓库实现
// 登录用户使用此实现，通过后端 Like API 管理收藏数据

import 'package:flutter/foundation.dart';

import '../api/backend_client.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 后端 API 收藏仓库
class ApiFavoriteRepository implements FavoriteRepository {
  final BackendClient _client;

  ApiFavoriteRepository(this._client);

  @override
  Future<List<Song>> getAll() async {
    debugPrint('[ApiFavoriteRepo] getAll()');
    final songs = await _client.getUserLikedSongs();
    debugPrint('[ApiFavoriteRepo] getAll() 返回 ${songs.length} 首');
    return songs;
  }

  @override
  Future<void> add(Song song) async {
    debugPrint('[ApiFavoriteRepo] add: id=${song.id}, name=${song.name}');
    final result = await _client.likeSong(song.id,
        songName: song.name,
        artist: song.artist,
        source: song.source);
    debugPrint('[ApiFavoriteRepo] add 结果: ${result?.success}, likeCount=${result?.likeCount}');
  }

  @override
  Future<void> remove(String songId) async {
    debugPrint('[ApiFavoriteRepo] remove: id=$songId');
    final result = await _client.unlikeSong(songId);
    debugPrint('[ApiFavoriteRepo] remove 结果: ${result?.success}');
  }

  @override
  Future<bool> isFavorited(String songId) async {
    debugPrint('[ApiFavoriteRepo] isFavorited: id=$songId');
    final status = await _client.getLikeStatus(songId);
    debugPrint('[ApiFavoriteRepo] isFavorited 结果: isLiked=${status.isLiked}');
    return status.isLiked;
  }

  @override
  Future<List<Song>> search(String keyword) async {
    // 获取全部收藏后本地过滤
    final all = await getAll();
    final kw = keyword.toLowerCase();
    return all
        .where((s) =>
            s.name.toLowerCase().contains(kw) ||
            s.artist.toLowerCase().contains(kw) ||
            s.album.toLowerCase().contains(kw))
        .toList();
  }

  @override
  Future<int> count() async {
    final all = await getAll();
    return all.length;
  }
}