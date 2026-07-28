// 后端 API 收藏仓库实现
// 登录用户使用此实现，通过后端 Like API 管理收藏数据

import 'package:flutter/foundation.dart';

import '../api/backend_client.dart';
import '../api/gdmusic_client.dart';
import '../models/song.dart';
import 'favorite_repository.dart';

/// 后端 API 收藏仓库
class ApiFavoriteRepository implements FavoriteRepository {
  final BackendClient _client;
  final GdMusicClient _gdMusic;

  ApiFavoriteRepository(this._client, this._gdMusic);

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
    // 异步后台上传元信息，不阻塞 UI
    _uploadMetadata(song);
  }

  /// 异步后台上传歌曲元信息到后端
  Future<void> _uploadMetadata(Song song) async {
    try {
      // 并发解析封面 URL、音频 URL 和歌词
      final results = await Future.wait([
        _resolveCoverUrl(song),
        _resolveAudioUrl(song),
        _resolveLyrics(song),
      ]);
      final coverUrl = results[0];
      final audioUrl = results[1];
      final lyricsText = results[2];

      await _client.likeSong(song.id,
          songName: song.name,
          artist: song.artist,
          coverUrl: coverUrl,
          source: song.source,
          audioUrl: audioUrl,
          lyricsUrl: lyricsText,
          album: song.album.isNotEmpty ? song.album : null);
      debugPrint('[ApiFavoriteRepo] 后台上传成功');
    } catch (e) {
      debugPrint('[ApiFavoriteRepo] 后台上传失败: $e');
    }
  }

  /// 解析封面 URL
  Future<String?> _resolveCoverUrl(Song song) async {
    if (song.picId == null || song.picId!.isEmpty) return null;
    try {
      return await _gdMusic.getCoverUrl(picId: song.picId!, source: song.source);
    } catch (e) {
      debugPrint('[ApiFavoriteRepo] 解析封面失败: $e');
      return null;
    }
  }

  /// 解析音频 URL
  Future<String?> _resolveAudioUrl(Song song) async {
    try {
      final playUrl = await _gdMusic.getPlayUrl(songId: song.id, source: song.source);
      return playUrl.url;
    } catch (e) {
      debugPrint('[ApiFavoriteRepo] 解析音频 URL 失败: $e');
      return null;
    }
  }

  /// 解析歌词文本
  Future<String?> _resolveLyrics(Song song) async {
    if (song.lyricId == null || song.lyricId!.isEmpty) return null;
    try {
      final lyric = await _gdMusic.getLyric(lyricId: song.lyricId!, source: song.source);
      return lyric?.lyric;
    } catch (e) {
      debugPrint('[ApiFavoriteRepo] 解析歌词失败: $e');
      return null;
    }
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