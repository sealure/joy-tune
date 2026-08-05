import 'package:flutter/material.dart';

/// 歌单元数据
class MockPlaylist {
  final String id;
  final String name;
  final String subtitle;
  /// 用于搜索接口的关键词，为空时使用 name 搜索
  final String? searchKeyword;
  /// 音源，默认 joox（Joox 原版歌曲齐全且播放 URL 可用）
  final String source;

  const MockPlaylist({
    required this.id,
    required this.name,
    required this.subtitle,
    this.searchKeyword,
    this.source = 'joox',
  });
}

/// 推荐歌单列表（元数据，不含歌曲列表）
final List<MockPlaylist> recommendedPlaylists = [
  MockPlaylist(
    id: 'chinese',
    name: '华语',
    subtitle: '经典华语歌曲',
    source: 'joox',
  ),
  MockPlaylist(
    id: 'relax',
    name: '轻音乐',
    subtitle: '放松心情的旋律',
    source: 'joox',
  ),
  MockPlaylist(
    id: 'electronic',
    name: '电音',
    subtitle: '电子音乐精选',
    source: 'joox',
  ),
];

/// 今日推荐的渐变色
final List<List<Color>> recommendationGradients = [
  [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
  [const Color(0xFFEC4899), const Color(0xFFF472B6)],
  [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
  [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
  [const Color(0xFF10B981), const Color(0xFF34D399)],
  [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
  [const Color(0xFFEF4444), const Color(0xFFF87171)],
  [const Color(0xFF06B6D4), const Color(0xFF22D3EE)],
];
