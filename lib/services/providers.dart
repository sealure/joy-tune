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
import '../db/daos/pic_cover_dao.dart';
import '../db/daos/recommend_dao.dart';
import '../db/daos/search_history_dao.dart';
import '../db/daos/session_dao.dart';
import '../db/daos/settings_dao.dart';
import '../db/daos/song_meta_dao.dart';
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
import '../services/update/github_release_client.dart';
import '../services/update/update_models.dart';
import '../services/update/update_service.dart';
import '../utils/app_info.dart';

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

/// 封面解析结果缓存数据访问对象（纯本地：key=(pic_id, source)，歌曲/歌单封面共用）
final picCoverDaoProvider = Provider<PicCoverDao>((ref) {
  return PicCoverDao(ref.watch(databaseProvider));
});

/// 推荐歌单缓存数据访问对象（只读下行缓存：镜像后端推荐列表/歌曲，后台异步拉取覆盖）
final recommendDaoProvider = Provider<RecommendDao>((ref) {
  return RecommendDao(ref.watch(databaseProvider));
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

/// 后台同步服务（扫描 is_synced=0 记录同步到服务端；推荐歌单只读下行缓存也在此异步拉取）
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
    recommendDao: ref.watch(recommendDaoProvider),
  );
  return service;
});

/// 收藏列表（本地 SQLite 流式读取，登录后 SyncService 后台同步）
final favoritesProvider = StreamProvider<List<Song>>((ref) {
  final repo = ref.watch(favoriteRepositoryProvider);
  return repo.watchAll();
});

// ── 推荐歌单 Provider ──

/// 推荐歌单列表（本地 SQLite 流式）
/// SyncService 后台异步拉取后端推荐列表并覆盖本地缓存，首页即时显示（离线可用缓存）。
final recommendPlaylistsProvider = StreamProvider<List<RecommendPlaylist>>((ref) {
  final dao = ref.watch(recommendDaoProvider);
  return dao.watchPlaylists().map((rows) => rows.map((r) => RecommendPlaylist(
        id: r.remoteId,
        name: r.name,
        description: r.description,
        coverUrl: r.coverUrl,
        type: r.type,
        songCount: r.songCount,
        playCount: r.playCount,
        userName: r.ownerNickname.isEmpty ? null : r.ownerNickname,
        userAvatar: r.ownerAvatarUrl.isEmpty ? null : r.ownerAvatarUrl,
      )).toList());
});

/// 推荐歌单歌曲列表（本地 SQLite 流式，保留 pic_id/lyric_id 供列表/播放实时解析）
final recommendPlaylistSongsProvider =
    StreamProvider.family<List<Song>, int>((ref, playlistId) {
  final dao = ref.watch(recommendDaoProvider);
  return dao.watchSongs(playlistId).map((rows) => rows.map((s) => Song(
        id: s.songId,
        name: s.songName,
        artist: s.artist,
        album: s.album,
        source: s.source,
        coverUrl: (s.coverUrl?.isNotEmpty ?? false) ? s.coverUrl : null,
        picId: (s.picId?.isNotEmpty ?? false) ? s.picId : null,
        lyricId: (s.lyricId?.isNotEmpty ?? false) ? s.lyricId : null,
      )).toList());
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

// ── 自动更新 Provider ──

/// 当前应用信息（缓存 package_info_plus 版本号，供设置页/自动更新/设备上报共用）
final appInfoProvider = Provider<AppInfo>((ref) => AppInfo());

/// 当前版本号（设置页「版本」行、自动更新本地版本比较共用）
final currentVersionProvider = FutureProvider<String>((ref) async {
  return ref.read(appInfoProvider).version;
});

/// GitHub Release API 客户端
final githubReleaseClientProvider =
    Provider<GitHubReleaseClient>((ref) => GitHubReleaseClient());

/// 更新服务（检查更新 → 匹配 ABI → 下载 → 安装）
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    client: ref.watch(githubReleaseClientProvider),
    appInfo: ref.watch(appInfoProvider),
  );
});

/// 更新检查结果（设置页红点角标 + 检查按钮状态；null=本会话尚未检查）
final updateCheckStateProvider =
    StateProvider<UpdateCheckResult?>((ref) => null);
