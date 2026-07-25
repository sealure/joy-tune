// GD Music API 封装
// 支持从后端配置动态获取 API URL

import 'package:dio/dio.dart';
import '../models/song.dart';

/// GD Music API 封装
class GdMusicClient {
  static const _defaultBaseUrl = 'https://music-api.gdstudio.xyz/api.php';
  final Dio _dio;
  String _baseUrl;

  GdMusicClient({String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  /// 更新 API 地址（从后端配置获取后调用）
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// 获取当前 API 地址
  String get baseUrl => _baseUrl;

  /// 支持的音源列表（可从后端配置覆盖）
  static const sources = [
    'netease',
    'tencent',
    'kuwo',
    'tidal',
    'qobuz',
    'joox',
    'bilibili',
    'apple',
    'ytmusic',
    'spotify',
  ];

  /// 搜索歌曲
  Future<List<Song>> search({
    required String keyword,
    String source = 'netease',
    int count = 20,
    int page = 1,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'types': 'search',
      'source': source,
      'name': keyword,
      'count': count,
      'pages': page,
    });

    final list = response.data as List<dynamic>;
    print('[GdMusicClient] search: keyword=$keyword, source=$source, count=$count, resultCount=${list.length}');
    return list.map((e) => Song.fromJson(e as Map<String, dynamic>, source: source)).toList();
  }

  /// 获取播放 URL
  Future<PlayUrl> getPlayUrl({
    required String songId,
    required String source,
    int bitrate = 320,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'types': 'url',
      'source': source,
      'id': songId,
      'br': bitrate,
    });

    return PlayUrl.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取封面图 URL
  Future<String> getCoverUrl({
    required String picId,
    required String source,
    int size = 500,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'types': 'pic',
      'source': source,
      'id': picId,
      'size': size,
    });

    return (response.data as Map<String, dynamic>)['url']?.toString() ?? '';
  }

  /// 获取歌词
  Future<Lyric?> getLyric({
    required String lyricId,
    required String source,
  }) async {
    final response = await _dio.get('', queryParameters: {
      'types': 'lyric',
      'source': source,
      'id': lyricId,
    });

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return null;
    return Lyric.fromJson(data);
  }
}
