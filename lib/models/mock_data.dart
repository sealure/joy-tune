import 'package:flutter/material.dart';
import 'song.dart';

/// 推荐歌单
class MockPlaylist {
  final String id;
  final String name;
  final String subtitle;
  final List<Song> songs;

  const MockPlaylist({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.songs,
  });
}

final List<MockPlaylist> recommendedPlaylists = [
  MockPlaylist(
    id: 'today',
    name: '今日推荐',
    subtitle: '为你精选的好音乐',
    songs: [
      Song(id: '', source: 'netease', name: '起风了', artist: '周深', album: '起风了'),
      Song(id: '', source: 'netease', name: '向云端', artist: '黄绮珊', album: '向云端'),
      Song(id: '', source: 'netease', name: '我记得', artist: '赵雷', album: '署前街少年'),
      Song(id: '', source: 'netease', name: '孤勇者', artist: '陈奕迅', album: '孤勇者'),
      Song(id: '', source: 'netease', name: '唯一', artist: '告五人', album: '运气来得若有似无'),
      Song(id: '', source: 'netease', name: '是你', artist: '梦然', album: '是你'),
      Song(id: '', source: 'netease', name: '错位时空', artist: '艾辰', album: '错位时空'),
      Song(id: '', source: 'netease', name: '星辰大海', artist: '黄霄雲', album: '星辰大海'),
    ],
  ),
  MockPlaylist(
    id: 'hot',
    name: '热歌榜',
    subtitle: '热门歌曲推荐',
    songs: [
      Song(id: '', source: 'netease', name: '裹着心的光', artist: '林俊杰', album: '裹着心的光'),
      Song(id: '', source: 'netease', name: '奢香夫人', artist: '凤凰传奇', album: '奢香夫人'),
      Song(id: '', source: 'netease', name: '指纹', artist: '胡歌', album: '指纹'),
      Song(id: '', source: 'netease', name: '就让这大雨全都落下', artist: '容祖儿', album: '就让这大雨全都落下'),
      Song(id: '', source: 'netease', name: '可能', artist: '程响', album: '可能'),
    ],
  ),
  MockPlaylist(
    id: 'chinese',
    name: '华语金曲',
    subtitle: '经典华语歌曲',
    songs: [
      Song(id: '', source: 'netease', name: '晴天', artist: '周杰伦', album: '叶惠美'),
      Song(id: '', source: 'netease', name: '七里香', artist: '周杰伦', album: '七里香'),
      Song(id: '', source: 'netease', name: '后来', artist: '刘若英', album: '我等你'),
      Song(id: '', source: 'netease', name: '小幸运', artist: '田馥甄', album: '我的少女时代'),
      Song(id: '', source: 'netease', name: '光年之外', artist: '邓紫棋', album: '光年之外'),
    ],
  ),
  MockPlaylist(
    id: 'relax',
    name: '午后轻音乐',
    subtitle: '放松心情的旋律',
    songs: [
      Song(id: '', source: 'netease', name: 'Summer', artist: '久石让', album: '菊次郎的夏天'),
      Song(id: '', source: 'netease', name: 'River Flows In You', artist: 'Yiruma', album: 'First Love'),
      Song(id: '', source: 'netease', name: 'Kiss The Rain', artist: 'Yiruma', album: 'From The Yellow Room'),
      Song(id: '', source: 'netease', name: '夜的钢琴曲五', artist: '石进', album: '夜的钢琴曲'),
    ],
  ),
  MockPlaylist(
    id: 'hiphop',
    name: '嘻哈说唱',
    subtitle: '节奏与押韵',
    songs: [
      Song(id: '', source: 'netease', name: '麒麟', artist: '早安', album: '麒麟'),
      Song(id: '', source: 'netease', name: '隆里电丝', artist: '盛宇/刘聪/ICE', album: '隆里电丝'),
      Song(id: '', source: 'netease', name: '一般的一天', artist: 'Wiz_H张子豪', album: '一般的一天'),
    ],
  ),
  MockPlaylist(
    id: 'electronic',
    name: '电子节奏',
    subtitle: '电子音乐精选',
    songs: [
      Song(id: '', source: 'netease', name: 'Faded', artist: 'Alan Walker', album: 'Faded'),
      Song(id: '', source: 'netease', name: 'Alone', artist: 'Alan Walker', album: 'Alone'),
      Song(id: '', source: 'netease', name: 'The Spectre', artist: 'Alan Walker', album: 'The Spectre'),
    ],
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
