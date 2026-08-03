import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../api/gdmusic_client.dart';
import '../utils/cover_resolver.dart';
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

/// 歌词解析结果（文本 + 实际使用的 lyric_id）
class LyricsInfo {
  final String text;
  final String? lyricId;

  const LyricsInfo({required this.text, this.lyricId});
}

/// 多源搜索 + 元数据获取服务
class SongResolver {
  final Ref _ref;

  SongResolver(this._ref);

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
        .replaceAll('體', '体');
  }

  /// 判断搜索结果是否与目标歌曲精确匹配（歌名+歌手，支持繁简）
  bool _isMatch(Song original, Song candidate) {
    if (candidate.name != original.name) return false;
    // 歌手匹配：处理 "周杰伦 / 温岚" 这类拼接格式
    final candidateArtists = candidate.artist
        .split(RegExp(r'\s*/\s*'))
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList();
    final targetArtist = original.artist.trim().toLowerCase();
    // 目标歌手取主歌手（拼接格式取第一部分）
    final targetMainArtist = targetArtist.split(RegExp(r'\s*/\s*')).first.trim();
    final normalizedTarget = _normalizeChinese(targetMainArtist);
    return candidateArtists.any((a) {
      final normalizedCandidate = _normalizeChinese(a);
      return normalizedCandidate.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedCandidate);
    });
  }

  /// 并发搜索所有音源，返回所有结果
  Future<List<Song>> _searchAllSources(Song song) async {
    final keyword = '${song.name} ${song.artist}';
    // 并发搜索所有源
    final futures = GdMusicClient.sources.map((source) async {
      try {
        return await _ref.read(searchServiceProvider).search(
              keyword: keyword,
              source: source,
            );
      } catch (_) {
        return <Song>[];
      }
    });
    final results = await Future.wait(futures);
    // 汇总所有结果
    return results.expand((list) => list).toList();
  }

  /// 从汇总结果中精确匹配，返回最佳候选
  Song? _findBestMatch(Song original, List<Song> allResults) {
    // 优先：歌名+歌手都匹配
    for (final s in allResults) {
      if (_isMatch(original, s)) return s;
    }
    return null;
  }

  /// 直接用已有的 songId + source 获取播放 URL（不重新搜索）
  /// 适用于搜索结果、歌单等已有正确 ID 的场景
  Future<SongResolveResult?> resolveDirectly(Song song) async {
    final client = _ref.read(gdMusicClientProvider);
    try {
      final playUrl = await client.getPlayUrl(
        songId: song.id,
        source: song.source,
      );
      // URL 为空说明后端解析失败，回退到多源搜索解析
      if (playUrl.url.isEmpty) {
        return resolve(song);
      }
      // 并发加载封面 + 歌词（歌词带"缺 lyricId 搜索兜底"）
      final results = await Future.wait([
        searchCoverUrl(song),
        searchLyricsText(song),
      ]);
      return SongResolveResult(
        playable: song,
        coverUrl: results[0],
        lyricsText: results[1],
      );
    } catch (_) {
      // 直接解析失败，回退到多源搜索解析
      return resolve(song);
    }
  }

  /// 获取封面 URL（优先使用已带 URL，否则按 picId 解析）
  Future<String?> fetchCoverUrl(Song song) async {
    return resolveCoverUrl(_ref.read(gdMusicClientProvider), song);
  }

  /// 兜底获取封面 URL：无 coverUrl 且无 picId 时（历史 songs 数据不全），
  /// 按歌名+歌手搜索精确匹配后解析封面，用于封面回填
  Future<String?> searchCoverUrl(Song song) async {
    // 已有封面信息则直接返回
    final direct = await fetchCoverUrl(song);
    if (direct != null && direct.isNotEmpty) return direct;

    try {
      final all = await _searchAllSources(song);
      final matched = _findBestMatch(song, all);
      if (matched != null) {
        return fetchCoverUrl(matched);
      }
    } catch (_) {
      // 搜索失败降级为无封面（占位图）
    }
    return null;
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

  /// 歌词解析结果（文本 + 实际使用的 lyric_id）
  Future<String?> searchLyricsText(Song song) async {
    final info = await searchLyricsInfo(song);
    return info?.text;
  }

  /// 解析歌词并返回文本 + 实际 lyric_id（优先 song.lyricId；缺失时搜索匹配的 lyric_id）
  /// 供播放页回填本地缓存并同步服务端
  Future<LyricsInfo?> searchLyricsInfo(Song song) async {
    // 有 lyricId 直接取歌词
    if (song.lyricId != null && song.lyricId!.isNotEmpty) {
      final text = await fetchLyricsText(song);
      if (text != null && text.isNotEmpty) {
        return LyricsInfo(text: text, lyricId: song.lyricId);
      }
    }
    // 缺失或取不到：多源搜索匹配，用匹配结果的 lyric_id 再取歌词
    try {
      final all = await _searchAllSources(song);
      final matched = _findBestMatch(song, all);
      if (matched != null && matched.lyricId != null && matched.lyricId!.isNotEmpty) {
        final client = _ref.read(gdMusicClientProvider);
        final lyric = await client.getLyric(lyricId: matched.lyricId!, source: matched.source);
        if (lyric?.lyric != null && lyric!.lyric!.isNotEmpty) {
          return LyricsInfo(text: lyric.lyric!, lyricId: matched.lyricId);
        }
      }
    } catch (_) {
      // 搜索兜底失败则无歌词
    }
    return null;
  }

  /// 多源并发搜索 + 精确匹配，返回可播放的歌曲及元数据
  Future<SongResolveResult?> resolve(Song song, {int maxAttempts = 3}) async {
    final client = _ref.read(gdMusicClientProvider);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 并发搜索所有音源，汇总结果
      final allResults = await _searchAllSources(song);
      // 从汇总中精确匹配
      final matched = _findBestMatch(song, allResults);
      if (matched == null) {
        // 无精确匹配，等待后重试
        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
        continue;
      }

      try {
        await client.getPlayUrl(
          songId: matched.id,
          source: matched.source,
        );
        // 并发加载封面 + 歌词
        final results = await Future.wait([
          fetchCoverUrl(matched),
          fetchLyricsText(matched),
        ]);
        return SongResolveResult(
          playable: matched,
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
