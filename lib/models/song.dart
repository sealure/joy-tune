import 'dart:math' as math;

/// 歌曲搜索结果
class Song {
  final String id;
  final String source;
  final String name;
  final String artist;
  final String album;
  final String? picId;
  final String? lyricId;

  const Song({
    required this.id,
    required this.source,
    required this.name,
    required this.artist,
    required this.album,
    this.picId,
    this.lyricId,
  });

  factory Song.fromJson(Map<String, dynamic> json, {String? source}) {
    // artist 可能是数组 ["周杰伦", "温岚"] 或单字符串
    final artistRaw = json['artist'];
    final artistStr = artistRaw is List
        ? (artistRaw).join(' / ')
        : (artistRaw?.toString() ?? '');

    return Song(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? source ?? 'netease',
      name: json['name']?.toString() ?? '',
      artist: artistStr,
      album: json['album']?.toString() ?? '',
      picId: json['pic_id']?.toString(),
      lyricId: json['lyric_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'name': name,
        'artist': artist,
        'album': album,
        'pic_id': picId,
        'lyric_id': lyricId,
      };
}

/// 播放 URL 响应
class PlayUrl {
  final String url;
  final int bitrate;
  final int size;

  const PlayUrl({required this.url, this.bitrate = 320000, this.size = 0});

  factory PlayUrl.fromJson(Map<String, dynamic> json) {
    return PlayUrl(
      url: json['url']?.toString() ?? '',
      bitrate: json['br'] is int ? json['br'] : int.tryParse(json['br']?.toString() ?? '0') ?? 0,
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }
}

/// 歌词响应
class Lyric {
  final String? lyric;
  final String? tlyric;

  const Lyric({this.lyric, this.tlyric});

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      lyric: json['lyric']?.toString(),
      tlyric: json['tlyric']?.toString(),
    );
  }
}

/// LRC 歌词中的一行
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}

/// 播放状态
enum PlayState { stopped, playing, paused, loading }

/// 播放模式
enum PlayMode { sequential, loop, shuffle }

/// 播放模式扩展：计算下一首歌的索引
extension PlayModeCalc on PlayMode {
  /// 根据播放模式计算下一首歌的索引
  int nextIndex(int currentIndex, int queueLength) {
    switch (this) {
      case PlayMode.loop:
        return (currentIndex + 1) % queueLength;
      case PlayMode.sequential:
        return currentIndex;
      case PlayMode.shuffle:
        if (queueLength <= 1) return 0;
        final rng = math.Random();
        int next;
        do {
          next = rng.nextInt(queueLength);
        } while (next == currentIndex);
        return next;
    }
  }
}
