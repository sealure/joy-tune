// 后端 API 客户端
// 封装所有与后端的交互：配置、歌单、喜欢、评论、推荐

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/song.dart';

/// 后端 API 客户端
class BackendClient {
  // 后端地址从 api_config.dart 中获取
  static const _defaultBaseUrl = apiBaseUrl;
  static const _tokenKey = 'auth_jwt_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;
  String _baseUrl;

  BackendClient({String? baseUrl, Dio? dio, FlutterSecureStorage? storage})
      : _baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _storage = storage ?? const FlutterSecureStorage();

  /// 更新后端地址
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// 获取后端地址
  String get baseUrl => _baseUrl;

  /// 获取带认证头的 Dio 实例
  Future<Dio> get _authedDio async {
    final token = await _storage.read(key: _tokenKey);
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));
  }

  // ══════════════════════════════════════════
  // 配置相关
  // ══════════════════════════════════════════

  /// 获取系统配置（客户端启动时调用）
  Future<Map<String, dynamic>> getConfigs({String? keys}) async {
    try {
      final params = <String, dynamic>{};
      if (keys != null) params['keys'] = keys;

      final response = await _dio.get('/config', queryParameters: params);
      return response.data['configs'] as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('>>> [CONFIG] 获取配置失败: ${e.message}');
      return {};
    }
  }

  /// 检查停服开关
  Future<ShutdownCheckResult> checkShutdown({String? deviceId}) async {
    try {
      final params = <String, dynamic>{};
      if (deviceId != null) params['device_id'] = deviceId;

      final response = await _dio.get('/config/shutdown-check', queryParameters: params);
      return ShutdownCheckResult(
        enabled: response.data['enabled'] as bool? ?? false,
        message: response.data['message'] as String? ?? '',
      );
    } on DioException catch (e) {
      debugPrint('>>> [CONFIG] 检查停服失败: ${e.message}');
      return ShutdownCheckResult(enabled: false, message: '');
    }
  }

  // ══════════════════════════════════════════
  // 推荐歌单
  // ══════════════════════════════════════════

  /// 获取推荐歌单列表（首页用）
  Future<RecommendPlaylistsResult> getRecommendPlaylists({
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await _dio.get('/recommend/playlists', queryParameters: {
        'page': page,
        'size': size,
      });

      final data = response.data;
      final playlists = (data['playlists'] as List? ?? [])
          .map((p) => RecommendPlaylist.fromJson(p as Map<String, dynamic>))
          .toList();

      return RecommendPlaylistsResult(
        playlists: playlists,
        total: BackendClient._parseUint64(data['total']),
      );
    } on DioException catch (e) {
      debugPrint('>>> [RECOMMEND] 获取推荐歌单失败: ${e.message}');
      return RecommendPlaylistsResult(playlists: [], total: 0);
    }
  }

  /// 获取推荐歌单详情
  Future<RecommendPlaylistDetail?> getRecommendPlaylistDetail(int id) async {
    try {
      final response = await _dio.get('/recommend/playlists/$id');
      final data = response.data;

      final playlist = RecommendPlaylist.fromJson(data['playlist'] as Map<String, dynamic>);
      final songs = (data['songs'] as List? ?? [])
          .map((s) => PlaylistSongInfo.fromJson(s as Map<String, dynamic>))
          .toList();

      return RecommendPlaylistDetail(playlist: playlist, songs: songs);
    } on DioException catch (e) {
      debugPrint('>>> [RECOMMEND] 获取歌单详情失败: ${e.message}');
      return null;
    }
  }

  // ══════════════════════════════════════════
  // 歌单管理（需登录）
  // ══════════════════════════════════════════

  /// 获取当前用户的歌单列表
  Future<List<UserPlaylist>> getUserPlaylists() async {
    try {
      final dio = await _authedDio;
      final response = await dio.get('/playlists');
      final playlists = (response.data['playlists'] as List? ?? [])
          .map((p) => UserPlaylist.fromJson(p as Map<String, dynamic>))
          .toList();
      return playlists;
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 获取歌单列表失败: ${e.message}');
      return [];
    }
  }

  /// 获取歌单详情（含歌曲列表）
  Future<UserPlaylistDetail?> getUserPlaylistDetail(int id) async {
    try {
      final dio = await _authedDio;
      final response = await dio.get('/playlists/$id');
      final data = response.data;

      final playlist = UserPlaylist.fromJson(data['playlist'] as Map<String, dynamic>);
      final songs = (data['songs'] as List? ?? [])
          .map((s) => PlaylistSongInfo.fromJson(s as Map<String, dynamic>))
          .toList();

      return UserPlaylistDetail(playlist: playlist, songs: songs);
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 获取歌单详情失败: ${e.message}');
      return null;
    }
  }

  /// 创建歌单
  Future<UserPlaylist?> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
    bool isPublic = false,
  }) async {
    try {
      final dio = await _authedDio;
      final response = await dio.post('/playlists', data: {
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
        'is_public': isPublic,
      });
      return UserPlaylist.fromJson(response.data['playlist'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 创建歌单失败: ${e.message}');
      return null;
    }
  }

  /// 往歌单添加歌曲
  Future<bool> addSongToPlaylist(int playlistId, {
    required String songId,
    required String songName,
    required String artist,
    String? album,
    String? coverUrl,
    String? source,
    String? picId,
  }) async {
    try {
      final dio = await _authedDio;
      await dio.post('/playlists/$playlistId/songs', data: {
        'song_id': songId,
        'song_name': songName,
        'artist': artist,
        if (album != null) 'album': album,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (source != null) 'source': source,
        if (picId != null) 'pic_id': picId,
      });
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 添加歌曲失败: ${e.message}');
      return false;
    }
  }

  /// 从歌单移除歌曲
  Future<bool> removeSongFromPlaylist(int playlistId, String songId) async {
    try {
      final dio = await _authedDio;
      await dio.delete('/playlists/$playlistId/songs/$songId');
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 移除歌曲失败: ${e.message}');
      return false;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(int id) async {
    try {
      final dio = await _authedDio;
      await dio.delete('/playlists/$id');
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 删除歌单失败: ${e.message}');
      return false;
    }
  }

  /// 调整歌单内歌曲顺序（songIds 为 playlist_songs 记录 ID 的新顺序）
  Future<bool> reorderPlaylistSongs(int playlistId, List<int> songIds) async {
    try {
      final dio = await _authedDio;
      await dio.post('/playlists/$playlistId/reorder', data: {
        'song_ids': songIds,
      });
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 调整排序失败: ${e.message}');
      return false;
    }
  }

  /// 更新歌单信息（编辑名称/描述/封面/公开状态）
  /// 仅传入需要修改的字段，未传字段保持原值
  Future<UserPlaylist?> updatePlaylist(int id, {
    String? name,
    String? description,
    String? coverUrl,
    bool? isPublic,
  }) async {
    try {
      final dio = await _authedDio;
      final response = await dio.put('/playlists/$id', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (isPublic != null) 'is_public': isPublic,
      });
      return UserPlaylist.fromJson(response.data['playlist'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('>>> [PLAYLIST] 更新歌单失败: ${e.message}');
      return null;
    }
  }

  /// 安全解析 proto uint64 字段（JSON 中可能为数字或字符串）
  static int _parseUint64(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ══════════════════════════════════════════
  // 喜欢（收藏）
  // ══════════════════════════════════════════

  /// 喜欢一首歌
  Future<LikeResult?> likeSong(String songId, {
    String? songName,
    String? artist,
    String? coverUrl,
    String? source,
    String? audioUrl,
    String? lyricsUrl,
    String? album,
    String? picId,
  }) async {
    debugPrint('[BACKEND] likeSong: songId=$songId, songName=$songName');
    try {
      final dio = await _authedDio;
      debugPrint('[BACKEND] likeSong: 发送 POST /songs/$songId/like');
      final response = await dio.post('/songs/$songId/like', data: {
        if (songName != null) 'song_name': songName,
        if (artist != null) 'artist': artist,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (source != null) 'source': source,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (lyricsUrl != null) 'lyrics_url': lyricsUrl,
        if (album != null) 'album': album,
        if (picId != null) 'pic_id': picId,
      });
      debugPrint('[BACKEND] likeSong 响应: status=${response.statusCode}, data=${response.data}');
      return LikeResult(
        success: response.data['success'] == true,
        likeCount: _parseUint64(response.data['like_count']),
      );
    } on DioException catch (e) {
      debugPrint('>>> [BACKEND] likeSong Dio异常: ${e.message}, type=${e.type}, response=${e.response?.statusCode}');
      return null;
    }
  }

  /// 取消喜欢
  Future<LikeResult?> unlikeSong(String songId) async {
    debugPrint('[BACKEND] unlikeSong: songId=$songId');
    try {
      final dio = await _authedDio;
      final response = await dio.delete('/songs/$songId/like');
      return LikeResult(
        success: response.data['success'] == true,
        likeCount: _parseUint64(response.data['like_count']),
      );
    } on DioException catch (e) {
      debugPrint('[BACKEND] unlikeSong Dio异常: ${e.message}');
      return null;
    }
  }

  /// 查询是否已喜欢
  Future<LikeStatusResult> getLikeStatus(String songId) async {
    debugPrint('[BACKEND] getLikeStatus: songId=$songId');
    try {
      final dio = await _authedDio;
      final response = await dio.get('/songs/$songId/like-status');
      debugPrint('[BACKEND] getLikeStatus 响应: ${response.data}');
      return LikeStatusResult(
        isLiked: response.data['is_liked'] == true,
        likeCount: _parseUint64(response.data['like_count']),
      );
    } on DioException catch (e) {
      debugPrint('[BACKEND] getLikeStatus Dio异常: ${e.message}, response=${e.response?.statusCode}');
      return LikeStatusResult(isLiked: false, likeCount: 0);
    }
  }

  /// 批量查询喜欢状态
  Future<Map<String, LikeStatusResult>> batchGetLikeStatus(List<String> songIds) async {
    try {
      final dio = await _authedDio;
      final response = await dio.get('/songs/like-counts', queryParameters: {
        'song_ids': songIds.join(','),
      });

      final counts = response.data['counts'] as Map<String, dynamic>? ?? {};
      final result = <String, LikeStatusResult>{};
      for (final entry in counts.entries) {
        final info = entry.value as Map<String, dynamic>;
        result[entry.key] = LikeStatusResult(
          isLiked: info['is_liked'] == true,
          likeCount: _parseUint64(info['like_count']),
        );
      }
      return result;
    } on DioException catch (e) {
      debugPrint('>>> [LIKE] 批量查询失败: ${e.message}');
      return {};
    }
  }

  /// 获取用户收藏的所有歌曲
  Future<List<Song>> getUserLikedSongs() async {
    debugPrint('[BACKEND] getUserLikedSongs');
    try {
      final dio = await _authedDio;
      final response = await dio.get('/songs/liked');
      final songs = response.data['songs'] as List<dynamic>? ?? [];
      debugPrint('[BACKEND] getUserLikedSongs 原始数据: ${response.data}');
      final result = songs.map((s) {
        final json = s as Map<String, dynamic>;
        final audioUrl = json['audio_url']?.toString();
        debugPrint('[BACKEND] 解析收藏歌曲: id=${json['song_id']}, name=${json['song_name']}, audioUrl=$audioUrl');
        final song = Song(
          id: json['song_id']?.toString() ?? '',
          name: json['song_name']?.toString() ?? '',
          artist: json['artist']?.toString() ?? '',
          source: json['source']?.toString() ?? 'netease',
          album: json['album']?.toString() ?? '',
          picId: json['pic_id']?.toString(),
          audioUrl: audioUrl,
          coverUrl: json['cover_url']?.toString(),
          lyricsUrl: json['lyrics_url']?.toString(),
        );
        debugPrint('[BACKEND] 解析后: id=${song.id}, name=${song.name}');
        return song;
      }).toList();
      debugPrint('[BACKEND] getUserLikedSongs 返回 ${result.length} 首');
      return result;
    } on DioException catch (e) {
      debugPrint('[BACKEND] getUserLikedSongs Dio异常: ${e.message}, response=${e.response?.statusCode}');
      return [];
    }
  }

  // ══════════════════════════════════════════
  // 评论
  // ══════════════════════════════════════════

  /// 获取歌曲评论列表
  Future<CommentsResult> getComments(String songId, {
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get('/songs/$songId/comments', queryParameters: {
        'page': page,
        'size': size,
      });

      final data = response.data;
      final comments = (data['comments'] as List? ?? [])
          .map((c) => CommentInfo.fromJson(c as Map<String, dynamic>))
          .toList();

      return CommentsResult(
        comments: comments,
        total: BackendClient._parseUint64(data['total']),
      );
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 获取评论失败: ${e.message}');
      return CommentsResult(comments: [], total: 0);
    }
  }

  /// 发表评论
  Future<CommentInfo?> createComment(String songId, String content, {int? parentId}) async {
    try {
      final dio = await _authedDio;
      final response = await dio.post('/songs/$songId/comments', data: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      });
      return CommentInfo.fromJson(response.data['comment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 发表评论失败: ${e.message}');
      return null;
    }
  }

  /// 删除评论
  Future<bool> deleteComment(int commentId) async {
    try {
      final dio = await _authedDio;
      await dio.delete('/comments/$commentId');
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 删除评论失败: ${e.message}');
      return false;
    }
  }

  /// 点赞评论
  Future<bool> likeComment(int commentId) async {
    try {
      final dio = await _authedDio;
      await dio.post('/comments/$commentId/like');
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 点赞失败: ${e.message}');
      return false;
    }
  }

  /// 取消点赞评论
  Future<bool> unlikeComment(int commentId) async {
    try {
      final dio = await _authedDio;
      await dio.delete('/comments/$commentId/like');
      return true;
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 取消点赞失败: ${e.message}');
      return false;
    }
  }

  /// 获取评论回复列表
  Future<List<CommentInfo>> getReplies(int commentId, {
    int page = 1,
    int size = 20,
  }) async {
    try {
      final dio = await _authedDio;
      final response = await dio.get('/comments/$commentId/replies', queryParameters: {
        'page': page,
        'size': size,
      });
      final replies = (response.data['replies'] as List? ?? [])
          .map((r) => CommentInfo.fromJson(r as Map<String, dynamic>))
          .toList();
      return replies;
    } on DioException catch (e) {
      debugPrint('>>> [COMMENT] 获取回复失败: ${e.message}');
      return [];
    }
  }
}

// ══════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════

/// 停服检查结果
class ShutdownCheckResult {
  final bool enabled;
  final String message;
  const ShutdownCheckResult({required this.enabled, required this.message});
}

/// 推荐歌单信息
class RecommendPlaylist {
  final int id;
  final String name;
  final String description;
  final String coverUrl;
  final String type;
  final int songCount;
  final int playCount;
  final String? userName;
  final String? userAvatar;

  const RecommendPlaylist({
    required this.id,
    required this.name,
    this.description = '',
    this.coverUrl = '',
    this.type = 'system',
    this.songCount = 0,
    this.playCount = 0,
    this.userName,
    this.userAvatar,
  });

  factory RecommendPlaylist.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return RecommendPlaylist(
      id: BackendClient._parseUint64(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      songCount: BackendClient._parseUint64(json['song_count']),
      playCount: BackendClient._parseUint64(json['play_count']),
      userName: user?['nickname'] as String?,
      userAvatar: user?['avatar_url'] as String?,
    );
  }
}

/// 推荐歌单列表结果
class RecommendPlaylistsResult {
  final List<RecommendPlaylist> playlists;
  final int total;
  const RecommendPlaylistsResult({required this.playlists, required this.total});
}

/// 歌单歌曲信息
class PlaylistSongInfo {
  final int id;
  final String songId;
  final String songName;
  final String artist;
  final String album;
  final String coverUrl;
  final String source;
  final String picId;

  const PlaylistSongInfo({
    required this.id,
    required this.songId,
    required this.songName,
    this.artist = '',
    this.album = '',
    this.coverUrl = '',
    this.source = '',
    this.picId = '',
  });

  factory PlaylistSongInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistSongInfo(
      id: BackendClient._parseUint64(json['id']),
      songId: json['song_id'] as String? ?? '',
      songName: json['song_name'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      album: json['album'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      source: json['source'] as String? ?? '',
      picId: json['pic_id'] as String? ?? '',
    );
  }
}

/// 推荐歌单详情
class RecommendPlaylistDetail {
  final RecommendPlaylist playlist;
  final List<PlaylistSongInfo> songs;
  const RecommendPlaylistDetail({required this.playlist, required this.songs});
}

/// 用户歌单信息
class UserPlaylist {
  final int id;
  final String name;
  final String description;
  final String coverUrl;
  final String type;
  final bool isPublic;
  final int songCount;
  final int playCount;
  final String shareCode;
  final DateTime? createdAt;

  const UserPlaylist({
    required this.id,
    required this.name,
    this.description = '',
    this.coverUrl = '',
    this.type = 'user',
    this.isPublic = false,
    this.songCount = 0,
    this.playCount = 0,
    this.shareCode = '',
    this.createdAt,
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: BackendClient._parseUint64(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      type: json['type'] as String? ?? 'user',
      isPublic: json['is_public'] as bool? ?? false,
      songCount: BackendClient._parseUint64(json['song_count']),
      playCount: BackendClient._parseUint64(json['play_count']),
      shareCode: json['share_code'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// 用户歌单详情
class UserPlaylistDetail {
  final UserPlaylist playlist;
  final List<PlaylistSongInfo> songs;
  const UserPlaylistDetail({required this.playlist, required this.songs});
}

/// 喜欢结果
class LikeResult {
  final bool success;
  final int likeCount;
  const LikeResult({required this.success, required this.likeCount});
}

/// 喜欢状态
class LikeStatusResult {
  final bool isLiked;
  final int likeCount;
  const LikeStatusResult({required this.isLiked, required this.likeCount});
}

/// 评论信息
class CommentInfo {
  final int id;
  final int userId;
  final String content;
  final int likeCount;
  final bool isLiked;
  final int? parentId;
  final String? userName;
  final String? userAvatar;
  final List<CommentInfo> replies;

  const CommentInfo({
    required this.id,
    this.userId = 0,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.parentId,
    this.userName,
    this.userAvatar,
    this.replies = const [],
  });

  factory CommentInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final repliesList = (json['replies'] as List? ?? [])
        .map((r) => CommentInfo.fromJson(r as Map<String, dynamic>))
        .toList();

    return CommentInfo(
      id: BackendClient._parseUint64(json['id']),
      userId: BackendClient._parseUint64(json['user_id']),
      content: json['content'] as String? ?? '',
      likeCount: BackendClient._parseUint64(json['like_count']),
      isLiked: json['is_liked'] as bool? ?? false,
      parentId: json['parent_id'] == null ? null : BackendClient._parseUint64(json['parent_id']),
      userName: user?['nickname'] as String?,
      userAvatar: user?['avatar_url'] as String?,
      replies: repliesList,
    );
  }
}

/// 评论列表结果
class CommentsResult {
  final List<CommentInfo> comments;
  final int total;
  const CommentsResult({required this.comments, required this.total});
}
