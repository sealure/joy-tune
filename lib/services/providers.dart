// Riverpod Provider 定义
// 注册所有全局服务和状态

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gdmusic_client.dart';
import '../api/backend_client.dart';
import '../db/app_database.dart';
import '../db/daos/favorite_dao.dart';
import '../db/daos/play_record_dao.dart';
import '../db/daos/playlist_dao.dart';
import '../db/daos/playlist_follow_dao.dart';
import '../db/daos/search_history_dao.dart';
import '../db/daos/session_dao.dart';
import '../db/daos/settings_dao.dart';
import '../db/daos/song_meta_dao.dart';
import '../models/mock_data.dart';
import '../models/song.dart';
import '../repositories/drift_favorite_repository.dart';
import '../repositories/play_record_repository.dart';
import '../repositories/playlist_follow_repository.dart';
import '../repositories/playlist_repository.dart';
import '../services/search_service.dart';
import '../services/favorite_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/song_resolver.dart';
import '../services/sync/legacy_prefs_migrator.dart';
import '../services/sync/sync_service.dart';

// ── 单例 Provider ──

/// 音乐 API 客户端（GD Music）
final gdMusicClientProvider = Provider<GdMusicClient>((ref) => GdMusicClient());

/// 后端 API 客户端
final backendClientProvider = Provider<BackendClient>((ref) => BackendClient());

// ── 本地数据库 Provider ──

/// 客户端本地数据库（drift/SQLite，单例）
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

/// 收藏数据访问对象
final favoriteDaoProvider = Provider<FavoriteDao>((ref) => FavoriteDao(ref.watch(databaseProvider)));

/// 歌单数据访问对象
final playlistDaoProvider = Provider<PlaylistDao>((ref) => PlaylistDao(ref.watch(databaseProvider)));

/// 收藏歌单数据访问对象（订阅他人公开歌单）
final playlistFollowDaoProvider =
    Provider<PlaylistFollowDao>((ref) => PlaylistFollowDao(ref.watch(databaseProvider)));

/// 播放记录数据访问对象
final playRecordDaoProvider = Provider<PlayRecordDao>((ref) => PlayRecordDao(ref.watch(databaseProvider)));

/// 搜索历史数据访问对象
final searchHistoryDaoProvider =
    Provider<SearchHistoryDao>((ref) => SearchHistoryDao(ref.watch(databaseProvider)));

/// 播放会话数据访问对象
final sessionDaoProvider = Provider<SessionDao>((ref) => SessionDao(ref.watch(databaseProvider)));

/// 设置数据访问对象
final settingsDaoProvider = Provider<SettingsDao>((ref) => SettingsDao(ref.watch(databaseProvider)));

/// 歌曲元数据缓存数据访问对象（封面/歌词/lyric_id 统一缓存，纯本地）
final songMetaDaoProvider = Provider<SongMetaDao>((ref) {
  return SongMetaDao(ref.watch(databaseProvider));
});

/// 歌单仓库（本地 SQLite）
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository(
    ref.watch(playlistDaoProvider),
    ref.watch(backendClientProvider),
  );
});

/// 收藏歌单仓库（本地 SQLite，订阅他人公开歌单）
final playlistFollowRepositoryProvider = Provider<PlaylistFollowRepository>((ref) {
  return PlaylistFollowRepository(ref.watch(playlistFollowDaoProvider));
});

/// 播放记录仓库（本地 SQLite）
final playRecordRepositoryProvider = Provider<PlayRecordRepository>((ref) {
  return PlayRecordRepository(ref.watch(playRecordDaoProvider));
});

/// 搜索历史关键词列表（本地 SQLite 流式，纯本地不同步）
final searchHistoryProvider = StreamProvider<List<String>>((ref) {
  final dao = ref.watch(searchHistoryDaoProvider);
  return dao.watchAll().map((rows) => rows.map((r) => r.keyword).toList());
});

/// 登录状态（供需要登录的功能开关使用）
final isLoggedInProvider = StateProvider<bool>((ref) => false);

/// 收藏数据仓库：统一本地 SQLite（登录/游客一致），由 SyncService 后台同步
final favoriteRepositoryProvider = Provider<DriftFavoriteRepository>((ref) {
  return DriftFavoriteRepository(ref.watch(favoriteDaoProvider));
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(gdMusicClientProvider));
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(favoriteRepositoryProvider));
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final audio = AudioService(sessionDao: ref.watch(sessionDaoProvider));
  // 播放上报：无论登录与否先写本地播放记录（is_synced=0），
  // 登录后由 SyncService 定时（30s）同步上报到后端 play-records
  audio.onSongPlayed = (song) async {
    await ref.read(playRecordRepositoryProvider).addRecord(song);
  };
  return audio;
});

final songResolverProvider = Provider<SongResolver>((ref) => SongResolver(ref));

/// 认证服务 Provider（单例）
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 旧 SharedPreferences 数据迁移器（启动时把旧数据写入 SQLite）
final legacyPrefsMigratorProvider = Provider<LegacyPrefsMigrator>((ref) {
  return LegacyPrefsMigrator(
    favoriteDao: ref.watch(favoriteDaoProvider),
    searchHistoryDao: ref.watch(searchHistoryDaoProvider),
    sessionDao: ref.watch(sessionDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
  );
});

/// 后台同步服务（扫描 is_synced=0 记录同步到服务端）
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    client: ref.watch(backendClientProvider),
    auth: ref.watch(authServiceProvider),
    favoriteDao: ref.watch(favoriteDaoProvider),
    playlistDao: ref.watch(playlistDaoProvider),
    playlistFollowDao: ref.watch(playlistFollowDaoProvider),
    playRecordDao: ref.watch(playRecordDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
    songMetaDao: ref.watch(songMetaDaoProvider),
  );
  return service;
});

/// 收藏列表（本地 SQLite 流式读取，登录后 SyncService 后台同步）
final favoritesProvider = StreamProvider<List<Song>>((ref) {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.watchAll();
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

  // 将后端歌曲信息转换为前端 Song 模型（保留 pic_id/lyric_id，供列表/播放实时解析）
  return detail.songs.map((s) => Song(
    id: s.songId,
    name: s.songName,
    artist: s.artist,
    album: s.album,
    source: s.source,
    coverUrl: s.coverUrl.isNotEmpty ? s.coverUrl : null,
    picId: s.picId.isNotEmpty ? s.picId : null,
    lyricId: s.lyricId.isNotEmpty ? s.lyricId : null,
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

/// 我的歌单列表（本地 SQLite 流式，登录后 SyncService 同步到服务端）
final myPlaylistsProvider = StreamProvider<List<LocalPlaylistInfo>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchAll();
});

/// 单个歌单信息（本地 SQLite 流式）
final myPlaylistProvider =
    StreamProvider.family<LocalPlaylistInfo?, String>((ref, localId) {
  return ref.watch(playlistRepositoryProvider).watchById(localId);
});

/// 歌单内歌曲列表（本地 SQLite 流式，按本地排序）
final myPlaylistSongsProvider =
    StreamProvider.family<List<LocalPlaylistSongInfo>, String>((ref, localId) {
  return ref.watch(playlistRepositoryProvider).watchSongs(localId);
});

/// 我收藏的歌单列表（本地 SQLite 流式，订阅他人公开歌单；登录后 SyncService 同步服务端）
final myFollowedPlaylistsProvider =
    StreamProvider<List<LocalPlaylistFollowInfo>>((ref) {
  return ref.watch(playlistFollowRepositoryProvider).watchAll();
});

// ── 听歌总数 Provider ──

/// 当前用户累计播放次数（听歌总数），未登录为 0
final playCountProvider = FutureProvider<int>((ref) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  if (!isLoggedIn) return 0;
  final client = ref.watch(backendClientProvider);
  return client.getPlayCount();
});

// ── 播放历史 Provider ──

/// 播放历史（本地 SQLite 流式；登录后 SyncService 同步上报到服务端）
final playHistoryProvider = StreamProvider<List<PlayHistoryItem>>((ref) {
  return ref.watch(playRecordRepositoryProvider).watchAll();
});
