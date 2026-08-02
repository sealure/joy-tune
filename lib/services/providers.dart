// Riverpod Provider 定义
// 注册所有全局服务和状态

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../api/gdmusic_client.dart';
import '../api/backend_client.dart';
import '../models/mock_data.dart';
import '../models/song.dart';
import '../repositories/local_favorite_repository.dart';
import '../repositories/api_favorite_repository.dart';
import '../repositories/favorite_repository.dart';
import '../services/search_service.dart';
import '../services/favorite_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/song_resolver.dart';

// ── 单例 Provider ──

/// 音乐 API 客户端（GD Music）
final gdMusicClientProvider = Provider<GdMusicClient>((ref) => GdMusicClient());

/// 后端 API 客户端
final backendClientProvider = Provider<BackendClient>((ref) => BackendClient());

/// 登录状态（供收藏数据源切换使用）
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// 收藏数据仓库：登录用户使用后端 API，游客使用本地存储
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  debugPrint('[PROVIDER] favoriteRepositoryProvider: isLoggedIn=$isLoggedIn');
  if (isLoggedIn) {
    final repo = ApiFavoriteRepository(ref.watch(backendClientProvider), ref.watch(gdMusicClientProvider));
    debugPrint('[PROVIDER] 使用 ApiFavoriteRepository');
    return repo;
  }
  debugPrint('[PROVIDER] 使用 LocalFavoriteRepository');
  return LocalFavoriteRepository();
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(gdMusicClientProvider));
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(favoriteRepositoryProvider));
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final audio = AudioService();
  // 播放上报埋点：登录用户成功开始播放一首歌时上报一次
  audio.onSongPlayed = (song) async {
    final isLoggedIn = await ref.read(authServiceProvider).isLoggedIn;
    if (!isLoggedIn) return;
    await ref.read(backendClientProvider).reportPlay(song.id, source: song.source);
  };
  return audio;
});

final songResolverProvider = Provider<SongResolver>((ref) => SongResolver(ref));

/// 认证服务 Provider（单例）
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 收藏列表（登录用户从后端获取，游客从本地获取）
final favoritesProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.getAll();
});

// ── 推荐歌单 Provider ──

/// 从后端获取推荐歌单列表
final recommendPlaylistsProvider = FutureProvider<List<RecommendPlaylist>>((ref) async {
  final client = ref.watch(backendClientProvider);
  final result = await client.getRecommendPlaylists(page: 1, size: 20);
  return result.playlists;
});

/// 从后端获取推荐歌单歌曲列表
final recommendPlaylistSongsProvider =
    FutureProvider.family<List<Song>, int>((ref, playlistId) async {  final client = ref.watch(backendClientProvider);
  final detail = await client.getRecommendPlaylistDetail(playlistId);
  if (detail == null) return [];

  // 将后端歌曲信息转换为前端 Song 模型（保留封面/图片ID，供列表/播放使用）
  return detail.songs.map((s) => Song(
    id: s.songId,
    name: s.songName,
    artist: s.artist,
    album: s.album,
    source: s.source,
    coverUrl: s.coverUrl.isNotEmpty ? s.coverUrl : null,
    picId: s.picId.isNotEmpty ? s.picId : null,
    lyricId: null,
  )).toList();
});

// ── 歌单歌曲 Provider（兼容旧的 mock 数据方式）──

/// 根据歌单元数据中的搜索关键词，通过搜索接口动态获取歌曲列表
/// key: playlist.id (String)，value: 歌曲列表
/// 失败时自动重试最多3次
final playlistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  // 根据 playlistId 查找歌单元数据
  final playlist = recommendedPlaylists.firstWhere(
    (p) => p.id == playlistId,
    orElse: () => MockPlaylist(id: playlistId, name: playlistId, subtitle: ''),
  );
  // 获取搜索客户端
  final client = ref.watch(gdMusicClientProvider);
  // 搜索关键词：优先使用 searchKeyword，否则使用歌单名称
  final keyword = playlist.searchKeyword ?? playlist.name;
  // 自动重试最多99次（API 不稳定，同一关键词可能随机返回空）
  const maxRetries = 99;
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print('[playlistSongsProvider] 请求: playlistId=$playlistId, keyword=$keyword, attempt=$attempt');
      final result = await client.search(keyword: keyword, source: playlist.source, count: 99);
      print('[playlistSongsProvider] 结果: playlistId=$playlistId, songs=${result.length}');
      if (result.isNotEmpty || attempt == maxRetries) return result;
      // 返回空结果且未达最大重试次数，等待后重试
      print('[playlistSongsProvider] 空结果，等待重试...');
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    } catch (e) {
      print('[playlistSongsProvider] 失败: playlistId=$playlistId, attempt=$attempt, error=$e');
      if (attempt == maxRetries) rethrow;
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }
  }
  // 不会到达这里，但 Dart 静态分析需要
  throw StateError('unreachable');
});

// ── 我的歌单 Provider ──

/// 我的歌单列表（登录用户从后端获取，游客为空）
final myPlaylistsProvider = FutureProvider<List<UserPlaylist>>((ref) async {
  final client = ref.watch(backendClientProvider);
  return client.getUserPlaylists();
});

/// 我的歌单详情（含歌曲列表）
final myPlaylistDetailProvider =
    FutureProvider.family<UserPlaylistDetail?, int>((ref, playlistId) async {
  final client = ref.watch(backendClientProvider);
  return client.getUserPlaylistDetail(playlistId);
});

// ── 听歌总数 Provider ──

/// 当前用户累计播放次数（听歌总数），未登录为 0
final playCountProvider = FutureProvider<int>((ref) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return 0;
  final client = ref.watch(backendClientProvider);
  return client.getPlayCount();
});
