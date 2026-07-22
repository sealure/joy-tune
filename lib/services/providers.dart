import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gdmusic_client.dart';
import '../models/mock_data.dart';
import '../models/song.dart';
import '../repositories/local_favorite_repository.dart';
import '../repositories/favorite_repository.dart';
import '../services/search_service.dart';
import '../services/favorite_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/song_resolver.dart';

// ── 单例 Provider ──

final gdMusicClientProvider = Provider<GdMusicClient>((ref) => GdMusicClient());

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) => LocalFavoriteRepository());

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(gdMusicClientProvider));
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(favoriteRepositoryProvider));
});

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

final songResolverProvider = Provider<SongResolver>((ref) => SongResolver(ref));

/// 认证服务 Provider（单例）
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── 歌单歌曲 Provider ──

/// 根据歌单元数据中的搜索关键词，通过搜索接口动态获取歌曲列表
/// key: playlist.id (String)，value: 歌曲列表
/// 使用 autoDispose 自动释放，避免内存泄漏
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
  // 通过搜索接口获取歌曲，每次搜索10首
  return client.search(keyword: keyword, source: playlist.source, count: 99);
});
