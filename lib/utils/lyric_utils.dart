import '../models/song.dart';

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
