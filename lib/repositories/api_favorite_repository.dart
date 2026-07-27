// 后端 API 收藏仓库实现
// 登录用户使用此实现，通过后端 Like API 管理收藏数据

import '../api/backend_client.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 后端 API 收藏仓库
class ApiFavoriteRepository implements FavoriteRepository {
  final BackendClient _client;

  ApiFavoriteRepository(this._client);

  @override
  Future<List<Song>> getAll() async {
    return _client.getUserLikedSongs();
  }

  @override
  Future<void> add(Song song) async {
    await _client.likeSong(song.id,
        songName: song.name,
        artist: song.artist,
        source: song.source);
  }

  @override
  Future<void> remove(String songId) async {
    await _client.unlikeSong(songId);
  }

  @override
  Future<bool> isFavorited(String songId) async {
    final status = await _client.getLikeStatus(songId);
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