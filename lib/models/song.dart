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
        ? (artistRaw as List).join(' / ')
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

/// 解析 LRC 格式歌词文本
List<LyricLine> parseLrc(String lrc) {
  final lines = <LyricLine>[];
  final regex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');
  for (final line in lrc.split('\n')) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final min = int.parse(match.group(1)!);
      final sec = double.parse(match.group(2)!);
      final text = match.group(3)?.trim() ?? '';
      if (text.isNotEmpty) {
        lines.add(LyricLine(
          time: Duration(milliseconds: (min * 60000 + sec * 1000).round()),
          text: text,
        ));
      }
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

/// 播放状态
enum PlayState { stopped, playing, paused, loading }

/// 播放模式
enum PlayMode { sequential, loop, shuffle }
