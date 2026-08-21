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
import '../db/daos/download_dao.dart';
import '../models/song.dart';
import '../models/music_source_config.dart';
import '../models/user.dart';
import '../repositories/drift_favorite_repository.dart';
import '../repositories/play_record_repository.dart';
import '../repositories/playlist_follow_repository.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/download_repository.dart';
import '../services/search_service.dart';
import '../services/favorite_service.dart';
import '../services/audio_service.dart';
import '../services/download_service.dart';
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

/// 启动一次性拉取的服务端配置快照（音源列表 + system_configs）
/// 由 main.dart 触发一次并缓存，运行期再次 read 不重复请求
class StartupConfig {
  /// 音源列表（music_sources 表；接口失败为 null，客户端回落内置列表）
  final MusicSourcesResult? musicSources;
  /// 系统配置（app_shutdown / recommend_top_n / comment_max_length 等，供全局读取）
  final Map<String, dynamic> systemConfigs;

  const StartupConfig({this.musicSources, this.systemConfigs = const {}});
}

/// 启动配置 provider：并发拉取一次音源列表 + 系统配置，FutureProvider 自动缓存
final startupConfigProvider = FutureProvider<StartupConfig>((ref) async {
  final client = ref.watch(backendClientProvider);
  // 音源列表与系统配置同时发起（原串行两连 await，慢网时超时叠加拖慢启动）
  final musicSourcesFuture = client.getMusicSources();
  final systemConfigsFuture = client.getConfigs();
  final musicSources = await musicSourcesFuture;
  final systemConfigs = await systemConfigsFuture;
  return StartupConfig(musicSources: musicSources, systemConfigs: systemConfigs);
});

/// 停服检查结果（null = 尚未检查或未停服；非空且 enabled 即停服）
/// 由后台启动初始化（见 main.dart 的 _runBackgroundStartup）异步写入，
/// ViaMusicApp 全局监控该值，停服时弹出全屏遮罩并定时退出，不再阻塞启动。
final shutdownResultProvider = StateProvider<ShutdownCheckResult?>((ref) => null);

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

/// 下载记录数据访问对象（local_downloads，纯本地不同步）
final downloadDaoProvider = Provider<DownloadDao>((ref) {
  return DownloadDao(ref.watch(databaseProvider));
});

/// 下载记录仓库（本地 SQLite 流式）
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(ref.watch(downloadDaoProvider));
});

/// 已下载歌曲列表（本地 SQLite 流式，纯本地不同步）
final downloadsProvider = StreamProvider<List<Song>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchAll();
});

/// 正在下载的歌曲集合（key = `${songId}_${source}`），驱动下载按钮三态
final downloadingKeysProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(downloadServiceProvider).downloadingStream;
});

/// 歌曲下载服务（解析→取URL→落盘到系统下载目录→写记录）
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    repository: ref.watch(downloadRepositoryProvider),
    // 复用播放/试听的统一解析链路（查缓存→解析地址 + 封面/歌词元数据）
    songResolver: ref.watch(songResolverProvider),
    gdMusicClient: ref.watch(gdMusicClientProvider),
    // 注入本地元数据缓存：封面/歌词优先读 local_song_meta / local_pic_covers
    songMetaDao: ref.watch(songMetaDaoProvider),
    picCoverDao: ref.watch(picCoverDaoProvider),
  );
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

/// 当前登录用户信息（全局缓存，避免每次进入页面重复拉取）
/// - 登录态由 [isLoggedInProvider] 驱动：登录/登出时该值变化会触发重新获取
/// - 未登录返回 null；接口失败静默降级为 null
/// 首次被 watch 时拉取一次 getProfile 并缓存，切页/切 Tab 不再重复请求
final currentUserProvider = FutureProvider<User?>((ref) async {
  final loggedIn = ref.watch(isLoggedInProvider);
  if (!loggedIn) return null;
  final auth = ref.watch(authServiceProvider);
  try {
    return await auth.getProfile();
  } catch (_) {
    return null;
  }
});

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
  final audio = AudioService(
    sessionDao: ref.watch(sessionDaoProvider),
    // 注入解析器与音乐客户端，供 playSong()（mini 播放器/播放页共用）解析播放地址
    songResolver: ref.watch(songResolverProvider),
    gdMusicClient: ref.watch(gdMusicClientProvider),
    // 注入下载记录，供 playSong() 已下载本地文件优先播放（离线可听）
    downloadRepository: ref.watch(downloadRepositoryProvider),
  );
  // 播放上报：无论登录与否先写本地播放记录（is_synced=0），
  // 登录后由 SyncService 定时（30s）同步上报到后端 play-records
  audio.onSongPlayed = (song) async {
    await ref.read(playRecordRepositoryProvider).addRecord(song);
  };
  return audio;
});

final songResolverProvider = Provider<SongResolver>((ref) => SongResolver(ref));

/// 认证服务 Provider（单例）
/// 401 过期回调由 syncServiceProvider 注入（见下，避免 provider 间循环依赖）
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
  final auth = ref.watch(authServiceProvider);
  final service = SyncService(
    client: ref.watch(backendClientProvider),
    auth: auth,
    favoriteDao: ref.watch(favoriteDaoProvider),
    playlistDao: ref.watch(playlistDaoProvider),
    playlistFollowDao: ref.watch(playlistFollowDaoProvider),
    playRecordDao: ref.watch(playRecordDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
    songMetaDao: ref.watch(songMetaDaoProvider),
    recommendDao: ref.watch(recommendDaoProvider),
  );
  // 登录失效（token 过期 401）：清空本地账号数据 + 置未登录态（「我的」等页随之刷新）
  // 用局部 service 引用自身，避免 provider 间循环依赖
  auth.onAuthExpired = () async {
    await service.clearLocalUserData();
    ref.read(isLoggedInProvider.notifier).state = false;
  };
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
        coverPicId: r.coverPicId,
        coverSource: r.coverSource,
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
