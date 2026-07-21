import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../api/gdmusic_client.dart';
import 'providers.dart';

/// 歌曲解析结果
class SongResolveResult {
  final Song playable;
  final String? coverUrl;
  final String? lyricsText;

  const SongResolveResult({
    required this.playable,
    this.coverUrl,
    this.lyricsText,
  });
}

/// 多源搜索 + 元数据获取服务
class SongResolver {
  final Ref _ref;

  SongResolver(this._ref);

  /// 在指定源上搜索，严格按歌名精确匹配，不匹配则返回 null
  Future<Song?> _searchSource(Song song, String source) async {
    try {
      final results = await _ref.read(searchServiceProvider).search(
            keyword: '${song.name} ${song.artist}',
            source: source,
          );
      if (results.isEmpty) return null;
      for (final s in results) {
        if (s.name == song.name) return s;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 并发搜索除 [skip] 外的所有源，返回第一个成功结果
  Future<Song?> _raceOtherSources(Song song, String skip) async {
    final completer = Completer<Song?>();
    int completed = 0;
    final others = GdMusicClient.sources.where((s) => s != skip).toList();
    for (final source in others) {
      _searchSource(song, source).then((result) {
        if (result != null && !completer.isCompleted) {
          completer.complete(result);
        }
      }).whenComplete(() {
        completed++;
        if (completed >= others.length && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }
    return completer.future;
  }

  /// 获取封面 URL
  Future<String?> fetchCoverUrl(Song song) async {
    if (song.picId == null || song.picId!.isEmpty) return null;
    try {
      final client = _ref.read(gdMusicClientProvider);
      return await client.getCoverUrl(picId: song.picId!, source: song.source);
    } catch (_) {
      return null;
    }
  }

  /// 获取歌词文本
  Future<String?> fetchLyricsText(Song song) async {
    if (song.lyricId == null || song.lyricId!.isEmpty) return null;
    try {
      final client = _ref.read(gdMusicClientProvider);
      final lyric = await client.getLyric(lyricId: song.lyricId!, source: song.source);
      return lyric?.lyric;
    } catch (_) {
      return null;
    }
  }

  /// 多源搜索 + 重试，返回可播放的歌曲及元数据
  Future<SongResolveResult?> resolve(Song song, {int maxAttempts = 3}) async {
    final client = _ref.read(gdMusicClientProvider);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 优先使用原始源
      Song? playable = await _searchSource(song, song.source);
      // 原始源无结果 → 并发其他源
      playable ??= await _raceOtherSources(song, song.source);
      if (playable == null) continue;

      try {
        await client.getPlayUrl(
          songId: playable.id,
          source: playable.source,
        );

        // 并发加载封面 + 歌词
        final results = await Future.wait([
          fetchCoverUrl(playable),
          fetchLyricsText(playable),
        ]);

        return SongResolveResult(
          playable: playable,
          coverUrl: results[0],
          lyricsText: results[1],
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
