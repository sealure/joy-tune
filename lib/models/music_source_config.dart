/// 服务端下发的音源配置（对应后端 music_sources 独立表，GET /config/music-sources）
///
/// 每个音源独立配置，其中：
/// - [enabled] 为 false 的源不参与搜索
/// - [url] 为该源专用的 API 地址（source 只是查询参数，不同源可指向不同 API 服务器）
class MusicSourceConfig {
  /// 音源标识（GD Music API 的 source 参数，如 joox / netease）
  final String id;
  /// 展示名称
  final String name;
  /// 是否启用
  final bool enabled;
  /// 优先级（数字越小越靠前）
  final int priority;
  /// 该源专用的 API 地址（可为空，空则回落全局默认地址）
  final String? url;
  /// 备注
  final String? description;

  const MusicSourceConfig({
    required this.id,
    required this.name,
    required this.enabled,
    required this.priority,
    this.url,
    this.description,
  });

  factory MusicSourceConfig.fromJson(Map<String, dynamic> json) {
    return MusicSourceConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] == true,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

/// 服务端音源列表接口（GET /config/music-sources）的返回结果
class MusicSourcesResult {
  /// 音源配置列表（服务端已按优先级排序）
  final List<MusicSourceConfig> sources;
  /// 默认音源标识（为空时客户端回落默认值）
  final String defaultSource;

  const MusicSourcesResult({
    required this.sources,
    this.defaultSource = '',
  });
}
