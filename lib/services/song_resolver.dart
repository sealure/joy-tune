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

  /// 判断搜索结果是否与目标歌曲匹配（歌名+歌手）
  bool _isMatch(Song original, Song candidate) {
    // 歌名必须完全一致
    if (candidate.name != original.name) return false;
    // 歌手匹配：处理 "周杰伦 / 温岚" 这类拼接格式
    // 将候选人歌手按 / 拆分，检查是否包含目标歌手
    final candidateArtists = candidate.artist
        .split(RegExp(r'\s*/\s*'))
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList();
    final targetArtist = original.artist.trim().toLowerCase();
    // 目标歌手可能也是拼接的，取第一部分作为主歌手
    final targetMainArtist = targetArtist.split(RegExp(r'\s*/\s*')).first.trim();
    return candidateArtists.any((a) => a.contains(targetMainArtist) || targetMainArtist.contains(a));
  }

  /// 在指定源上搜索，优先精确匹配（歌名+歌手），其次歌名匹配
  Future<Song?> _searchSource(Song song, String source) async {
    try {
      final results = await _ref.read(searchServiceProvider).search(
            keyword: '${song.name} ${song.artist}',
            source: source,
          );
      if (results.isEmpty) return null;
      // 优先精确匹配（歌名+歌手）
      for (final s in results) {
        if (_isMatch(song, s)) return s;
      }
      // 退而求其次：只匹配歌名
      for (final s in results) {
        if (s.name == song.name) return s;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 直接用已有的 songId + source 获取播放 URL（不重新搜索）
  /// 适用于搜索结果、歌单等已有正确 ID 的场景
  Future<SongResolveResult?> resolveDirectly(Song song) async {
    final client = _ref.read(gdMusicClientProvider);
    try {
      await client.getPlayUrl(
        songId: song.id,
        source: song.source,
      );
      // 并发加载封面 + 歌词
      final results = await Future.wait([
        fetchCoverUrl(song),
        fetchLyricsText(song),
      ]);
      return SongResolveResult(
        playable: song,
        coverUrl: results[0],
        lyricsText: results[1],
      );
    } catch (_) {
      // 直接解析失败，回退到搜索解析
      return resolve(song);
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
