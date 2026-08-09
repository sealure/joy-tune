// GD Music API 封装
// 支持从后端配置动态获取 API URL

import 'package:dio/dio.dart';
import '../models/music_source_config.dart';
import '../models/song.dart';

/// GD Music API 封装
class GdMusicClient {
  static const _defaultBaseUrl = 'https://music-api.gdstudio.xyz/api.php';
  final Dio _dio;
  /// 各音源专属 API 服务器的请求客户端缓存（同一 API 地址复用同一个 Dio）
  final Map<String, Dio> _sourceDios = {};
  /// 适用各源专用 API 地址（source 只是查询参数，不同源可指向不同 API 服务器；未配置则走全局默认地址）
  Map<String, String> _sourceBaseUrls = const {};
  /// 当前可查询的音源集合（服务端配置启用；未配置时为内置兜底列表）
  Set<String> _enabledSources = supportedSources.toSet();
  String _baseUrl;

  GdMusicClient({String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  /// 更新 API 地址（从后端配置获取后调用，作为未单独配 url 的源的默认地址）
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  /// 获取当前 API 地址
  String get baseUrl => _baseUrl;

  /// 当前可查询的音源集合
  /// 优先级：服务端 [configureMusicSources] 配置的启用集合 > 内置 [supportedSources] 兜底
  Set<String> get enabledSources => _enabledSources;

  /// 应用服务端下发的音源配置（system_configs.music_sources）
  /// - [sources] 中 enabled=true 的源加入可查询集合；集合为空则保留内置兜底
  /// - 每个源带独立 API url，请求时按源选择；无 url 的源走全局默认地址
  void configureMusicSources(List<MusicSourceConfig> sources) {
    final urls = <String, String>{};
    for (final cfg in sources) {
      final url = cfg.url?.trim() ?? '';
      if (url.isNotEmpty) urls[cfg.id] = url;
    }
    _sourceBaseUrls = urls;
    final enabled = sources.where((c) => c.enabled).map((c) => c.id).toSet();
    if (enabled.isNotEmpty) _enabledSources = enabled;
  }

  /// 取指定音源应使用的请求客户端：
  /// 源配置了专属 API 地址且与全局默认不同 → 用该地址对应的 Dio（缓存复用）；否则用全局默认 Dio
  Dio _clientFor(String source) {
    final url = _sourceBaseUrls[source];
    if (url == null || url.isEmpty || url == _baseUrl) return _dio;
    return _sourceDios.putIfAbsent(
      url,
      () => Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      )),
    );
  }

  /// 支持的音源列表（顺序即搜索结果的固定展示顺序）
  /// joox → tencent → netease → tidal → kuwo → qobuz → bilibili → apple → ytmusic → spotify
  static const sources = [
    'joox',
    'tencent',
    'netease',
    'tidal',
    'kuwo',
    'qobuz',
    'bilibili',
    'apple',
    'ytmusic',
    'spotify',
  ];

  /// 当前 API 实际支持的音源（2026-08-09 实测：仅这 4 个返回 200，其余源 HTTP 400
  /// `Value of 'source' is not supported.`）。
  /// 搜索请求只走这些源，避免每页在无效源上空耗请求配额（限流 50 次/5 分钟）；
  /// 展示顺序仍按 [sources] 固定顺序，未支持的源自然不出现。
  static const supportedSources = [
    'joox',
    'netease',
    'kuwo',
    'bilibili',
  ];

  /// 搜索歌曲
  /// [albumSearch] 为 true 时 source 加 _album 后缀，用于专辑搜索
  Future<List<Song>> search({
    required String keyword,
    String source = 'netease',
    int count = 20,
    int page = 1,
    bool albumSearch = false,
  }) async {
    final searchSource = albumSearch ? '${source}_album' : source;
    final response = await _clientFor(source).get('', queryParameters: {
      'types': 'search',
      'source': searchSource,
      'name': keyword,
      'count': count,
      'pages': page,
    });

    final list = response.data as List<dynamic>;
    print('[GdMusicClient] search: keyword=$keyword, source=$searchSource, count=$count, resultCount=${list.length}');
    return list.map((e) => Song.fromJson(e as Map<String, dynamic>, source: source)).toList();
  }

  /// 当前默认音质（kbps），会话级默认播放 bitrate；默认 128
  /// 由设置页「默认音质」持久化并同步至此处；getPlayUrl 不传 bitrate 时使用
  int defaultBitrate = 128;

  /// 获取播放 URL
  /// [bitrate] 不传时使用当前默认音质（默认音质设置真正生效的入口）
  Future<PlayUrl> getPlayUrl({
    required String songId,
    required String source,
    int? bitrate,
  }) async {
    final br = bitrate ?? defaultBitrate;
    final response = await _clientFor(source).get('', queryParameters: {
      'types': 'url',
      'source': source,
      'id': songId,
      'br': br,
    });

    return PlayUrl.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取封面图 URL
  Future<String> getCoverUrl({
    required String picId,
    required String source,
    int size = 500,
  }) async {
    final response = await _clientFor(source).get('', queryParameters: {
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
    final response = await _clientFor(source).get('', queryParameters: {
      'types': 'lyric',
      'source': source,
      'id': lyricId,
    });

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data.isEmpty) return null;
    return Lyric.fromJson(data);
  }
}
