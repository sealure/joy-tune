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
  /// 支持繁简中文匹配（如 "周杰倫" 匹配 "周杰伦"）
  bool _isMatch(Song original, Song candidate) {
    // 歌名必须完全一致
    if (candidate.name != original.name) return false;
    // 歌手匹配：处理 "周杰伦 / 温岚" 这类拼接格式
    final candidateArtists = candidate.artist
        .split(RegExp(r'\s*/\s*'))
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList();
    final targetArtist = original.artist.trim().toLowerCase();
    // 目标歌手可能也是拼接的，取第一部分作为主歌手
    final targetMainArtist = targetArtist.split(RegExp(r'\s*/\s*')).first.trim();
    // 繁简归一化：将繁体中文映射为简体进行比较
    final normalizedTarget = _normalizeChinese(targetMainArtist);
    return candidateArtists.any((a) {
      final normalizedCandidate = _normalizeChinese(a);
      return normalizedCandidate.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedCandidate);
    });
  }

  /// 繁体中文 → 简体中文 归一化（常用字映射）
  String _normalizeChinese(String text) {
    return text
        .replaceAll('傑', '杰').replaceAll('倫', '伦').replaceAll('週', '周')
        .replaceAll('風', '风').replaceAll('東', '东').replaceAll('華', '华')
        .replaceAll('國', '国').replaceAll('學', '学').replaceAll('對', '对')
        .replaceAll('說', '说').replaceAll('記', '记').replaceAll('開', '开')
        .replaceAll('關', '关').replaceAll('點', '点').replaceAll('機', '机')
        .replaceAll('電', '电').replaceAll('車', '车').replaceAll('門', '门')
        .replaceAll('問', '问').replaceAll('間', '间').replaceAll('見', '见')
        .replaceAll('話', '话').replaceAll('實', '实').replaceAll('書', '书')
        .replaceAll('長', '长').replaceAll('認', '认').replaceAll('識', '识')
        .replaceAll('飛', '飞').replaceAll('魚', '鱼').replaceAll('鳥', '鸟')
        .replaceAll('馬', '马').replaceAll('龍', '龙').replaceAll('雲', '云')
        .replaceAll('霧', '雾').replaceAll('頭', '头').replaceAll('頁', '页')
        .replaceAll('項', '项').replaceAll('順', '顺').replaceAll('須', '须')
        .replaceAll('體', '体').replaceAll('魚', '鱼');
  }

  /// 在指定源上搜索，优先精确匹配（歌名+歌手），不匹配则返回 null 让其他源兜底
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
      // 歌手不匹配 → 返回 null，让 resolver 尝试其他音源
      // 避免在网易云拿到翻唱后直接使用
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
