import 'package:drift/drift.dart';

/// 本地收藏表（需同步）：主键 (song_id, source)，镜像 Song 全字段
/// 删除用 soft delete（deleted=1），重新收藏=deleted 置 0；
/// is_synced=0 待同步；syncedEver 记录"是否曾成功同步到服务端"，用于删除同步判定
class LocalFavorites extends Table {
  /// 歌曲 ID（原始音源 ID）
  TextColumn get songId => text()();
  /// 音源标识（netease/qqmusic/joox 等）
  TextColumn get source => text()();
  /// 歌曲名
  TextColumn get name => text()();
  /// 歌手
  TextColumn get artist => text()();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 封面图 pic_id（按需懒加载）
  TextColumn get picId => text().nullable()();
  /// 歌词 ID
  TextColumn get lyricId => text().nullable()();
  /// 播放地址
  TextColumn get audioUrl => text().nullable()();
  /// 封面 URL
  TextColumn get coverUrl => text().nullable()();
  /// 歌词 LRC 地址
  TextColumn get lyricsUrl => text().nullable()();
  /// soft delete 标记（1=已取消收藏待同步删除）
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// 是否已同步到服务端（0=待同步）
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  /// 是否曾成功同步过（用于删除同步：曾同步的删除需调 DELETE，未同步的直接物理删）
  BoolColumn get syncedEver => boolean().withDefault(const Constant(false))();
  /// 收藏时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId, source};
}

/// 本地歌单表（需同步）：主键 id=本地 UUID
/// 两段式主键：本地创建无远端 id，同步成功后回填 remoteId，后续更新/删除/分享依赖 remoteId
class LocalPlaylists extends Table {
  /// 本地歌单 ID（UUID，客户端生成）
  TextColumn get id => text()();
  /// 服务端歌单 ID（POST /playlists 创建成功后回填，null 表示尚未同步）
  IntColumn get remoteId => integer().nullable()();
  /// 歌单名称
  TextColumn get name => text()();
  /// 歌单描述
  TextColumn get description => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().withDefault(const Constant(''))();
  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  TextColumn get coverPicId => text().nullable()();
  /// 封面来源歌曲音源标识
  TextColumn get coverSource => text().nullable()();
  /// 是否公开可见
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  /// soft delete 标记
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// 是否已同步到服务端
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  /// 是否曾成功同步过
  BoolColumn get syncedEver => boolean().withDefault(const Constant(false))();
  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 本地歌单歌曲关联表（需同步）：本地行自增主键
/// sortOrder 为本地顺序（MVP 只同步增删、不保证远端顺序）；
/// remoteId 回填远端 playlist_songs 记录 id（reorder 增强用）
class LocalPlaylistSongs extends Table {
  /// 本地行主键（自增）
  IntColumn get id => integer().autoIncrement()();
  /// 所属本地歌单 ID（FK → local_playlists.id）
  TextColumn get playlistId => text().references(LocalPlaylists, #id)();
  /// 歌曲 ID
  TextColumn get songId => text()();
  /// 音源
  TextColumn get source => text()();
  /// 歌曲名
  TextColumn get songName => text()();
  /// 歌手
  TextColumn get artist => text()();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().nullable()();
  /// 封面图 pic_id
  TextColumn get picId => text().nullable()();
  /// 歌词 ID（音源原始歌词 ID，实时解析歌词）
  TextColumn get lyricId => text().nullable()();
  /// 本地排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  /// 远端 playlist_songs 记录 id（同步后回填，reorder 增强用）
  IntColumn get remoteId => integer().nullable()();
  /// soft delete 标记
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// 是否已同步到服务端
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  /// 是否曾成功同步过
  BoolColumn get syncedEver => boolean().withDefault(const Constant(false))();
  /// 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, songId, source},
      ];
}

/// 本地播放记录表（需同步）：每条 = 一次开始播放
/// 只上报 is_synced=0 的记录（按 id 升序），attemptCount 超过上限暂停避免重复计数
class LocalPlayRecords extends Table {
  /// 本地行主键（自增）
  IntColumn get id => integer().autoIncrement()();
  /// 歌曲 ID
  TextColumn get songId => text()();
  /// 音源
  TextColumn get source => text().withDefault(const Constant(''))();
  /// 歌曲名
  TextColumn get songName => text().withDefault(const Constant(''))();
  /// 歌手
  TextColumn get artist => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().nullable()();
  /// 封面图 pic_id（音源原始封面 ID，实时解析封面）
  TextColumn get picId => text().nullable()();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 歌词 ID（音源原始歌词 ID，实时解析歌词）
  TextColumn get lyricId => text().nullable()();
  /// 播放时间（本地记录时刻）
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
  /// 是否已同步到服务端
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  /// 同步尝试次数（超过上限暂停，避免断网重试重复计数）
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
}

/// 本地搜索历史表（纯本地，无 is_synced）
class LocalSearchHistory extends Table {
  /// 本地行主键（自增）
  IntColumn get id => integer().autoIncrement()();
  /// 搜索关键词（唯一，去重置顶）
  TextColumn get keyword => text().unique()();
  /// 搜索时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 本地播放会话表（纯本地，单行 id=1，存储队列+进度+模式）
class LocalPlaySessions extends Table {
  /// 单行固定 id=1
  IntColumn get id => integer()();
  /// 播放队列（歌曲 JSON 序列化，沿用现有队列模型）
  TextColumn get queueJson => text().nullable()();
  /// 当前播放索引
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();
  /// 播放进度（毫秒）
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  /// 播放模式（sequential/loop/shuffle）
  TextColumn get playMode => text().withDefault(const Constant('loop'))();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 本地设置表（纯本地，key-value）
/// 承载 device_id、桌面窗口宽高、prefs_migrated、pending_clear_play_history、
/// favorites_pulled_<userId> 等
class LocalSettings extends Table {
  /// 配置键名
  TextColumn get key => text()();
  /// 配置值
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 本地歌词缓存表（纯本地，不同步）
/// 播放过的歌解析到歌词后回填，下次播放直接读，避免重复请求；清理缓存时一并清除
/// ⚠️ 已并入 LocalSongMeta（统一歌曲元数据缓存），此表废弃保留声明以兼容旧库迁移
class LocalLyricsCache extends Table {
  /// 歌曲 ID
  TextColumn get songId => text()();
  /// 音源
  TextColumn get source => text()();
  /// LRC 歌词文本
  TextColumn get lyrics => text()();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId, source};
}

/// 本地歌曲元数据缓存表（纯本地，不同步）
/// 统一缓存歌曲解析结果：封面 URL / 歌词 ID / 歌词全文（key = song_id + source）。
/// 封面/歌词读取统一走此表；播放解析出的 lyric_id 回填此表并经业务表同步服务端。
class LocalSongMeta extends Table {
  /// 歌曲 ID（原始音源 ID）
  TextColumn get songId => text()();
  /// 音源标识
  TextColumn get source => text()();
  /// 歌曲名
  TextColumn get name => text().withDefault(const Constant(''))();
  /// 歌手
  TextColumn get artist => text().withDefault(const Constant(''))();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 封面图 ID（音源原始图片 ID）
  TextColumn get picId => text().nullable()();
  /// 歌词 ID（音源原始歌词 ID）
  TextColumn get lyricId => text().nullable()();
  /// 封面 URL（解析结果）
  TextColumn get coverUrl => text().nullable()();
  /// LRC 歌词全文（播放后回填）
  TextColumn get lyrics => text().nullable()();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId, source};
}

/// 本地收藏歌单表（需同步）：主键 = 服务端歌单 id（引用/订阅，非副本）
/// 收藏的是对源歌单的引用：收藏动作先写本地（is_synced=0），
/// SyncService 登录后推送 POST /playlists/{id}/follow，取消走 DELETE /playlists/{id}/follow。
/// 列表元信息（创建者/歌曲数）在同步拉取 /playlists/followed 时补全，跟随创建者更新。
class LocalPlaylistFollows extends Table {
  /// 服务端歌单 ID（唯一，收藏的源歌单）
  IntColumn get playlistId => integer()();
  /// 歌单名称
  TextColumn get name => text().withDefault(const Constant(''))();
  /// 歌单描述
  TextColumn get description => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().withDefault(const Constant(''))();
  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  TextColumn get coverPicId => text().nullable()();
  /// 封面来源歌曲音源标识
  TextColumn get coverSource => text().nullable()();
  /// 创建者昵称（同步拉取后补全）
  TextColumn get ownerNickname => text().withDefault(const Constant(''))();
  /// 创建者头像 URL（同步拉取后补全）
  TextColumn get ownerAvatarUrl => text().withDefault(const Constant(''))();
  /// 歌曲数（收藏时快照，同步拉取后刷新）
  IntColumn get songCount => integer().withDefault(const Constant(0))();
  /// soft delete 标记（取消收藏=1 待同步删除）
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// 是否已同步到服务端（0=待同步）
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  /// 是否曾成功同步过（用于取消收藏的删除同步判定）
  BoolColumn get syncedEver => boolean().withDefault(const Constant(false))();
  /// 收藏时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {playlistId};
}

/// 本地推荐歌单缓存表（只读下行缓存，无 is_synced，不做上行同步）
/// 镜像服务端推荐歌单列表（系统「推荐」+ 用户公开分享歌单），
/// 由 SyncService 后台异步从后端拉取后整体覆盖；首页优先读本地（即时/离线可用）。
class LocalRecommendPlaylists extends Table {
  /// 服务端歌单 ID（唯一）
  IntColumn get remoteId => integer()();
  /// 歌单名称
  TextColumn get name => text()();
  /// 歌单描述
  TextColumn get description => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().withDefault(const Constant(''))();
  /// 封面来源歌曲 pic_id（为空时按 coverUrl 或占位图；非空则客户端实时解析封面）
  TextColumn get coverPicId => text().nullable()();
  /// 封面来源歌曲音源标识
  TextColumn get coverSource => text().nullable()();
  /// 歌单类型：system / user（首页分区用）
  TextColumn get type => text().withDefault(const Constant('system'))();
  /// 歌曲数（服务端快照，拉取时刷新）
  IntColumn get songCount => integer().withDefault(const Constant(0))();
  /// 播放量
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  /// 创建者昵称（用户公开歌单显示）
  TextColumn get ownerNickname => text().withDefault(const Constant(''))();
  /// 创建者头像 URL
  TextColumn get ownerAvatarUrl => text().withDefault(const Constant(''))();
  /// 服务端返回顺序（系统在前、公开在后，原样保留展示顺序）
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {remoteId};
}

/// 本地推荐歌单歌曲缓存表（只读下行缓存，无 is_synced）
/// 镜像推荐歌单内歌曲列表，由 SyncService 拉取歌单详情后整体覆盖。
class LocalRecommendPlaylistSongs extends Table {
  /// 所属推荐歌单服务端 ID
  IntColumn get playlistRemoteId => integer()();
  /// 歌曲 ID（原始音源 ID）
  TextColumn get songId => text()();
  /// 音源标识
  TextColumn get source => text().withDefault(const Constant(''))();
  /// 歌曲名
  TextColumn get songName => text()();
  /// 歌手
  TextColumn get artist => text().withDefault(const Constant(''))();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 封面 URL
  TextColumn get coverUrl => text().nullable()();
  /// 封面图 pic_id（音源原始图片 ID）
  TextColumn get picId => text().nullable()();
  /// 歌词 ID（音源原始歌词 ID）
  TextColumn get lyricId => text().nullable()();
  /// 歌单内排序序号
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {playlistRemoteId, songId, source};
}

/// 本地封面解析结果缓存表（纯本地，不同步）
/// 按 (pic_id, source) 缓存"封面图 ID → 解析后的封面 URL"，
/// 歌曲封面与歌单封面共用：key 与内存缓存 `${source}_${picId}` 对齐，
/// 解析结果落库后重启应用/换列表页不再请求外部 API。设置页"清除缓存"一并清除。
class LocalPicCovers extends Table {
  /// 封面图 ID（音源原始图片 ID）
  TextColumn get picId => text()();
  /// 音源标识
  TextColumn get source => text()();
  /// 封面 URL（解析结果）
  TextColumn get coverUrl => text()();
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {picId, source};
}

/// 本地下载记录表（纯本地，不同步）
/// 用户显式下载到系统下载目录 (`下载/JoyTune/<歌名>-<歌手>/`) 的歌曲，
/// 与应用缓存（AudioCache / local_song_meta）完全独立：清理缓存不触碰下载文件。
/// 主键 (song_id, source)：同一首歌不同音源各自独立下载。
class LocalDownloads extends Table {
  /// 歌曲 ID（原始音源 ID）
  TextColumn get songId => text()();
  /// 音源标识（netease/qqmusic/joox 等）
  TextColumn get source => text()();
  /// 歌曲名
  TextColumn get name => text()();
  /// 歌手
  TextColumn get artist => text()();
  /// 专辑
  TextColumn get album => text().withDefault(const Constant(''))();
  /// 封面图 pic_id（音源原始图片 ID，便于重取封面）
  TextColumn get picId => text().nullable()();
  /// 歌词 ID
  TextColumn get lyricId => text().nullable()();
  /// 封面 URL（解析结果）
  TextColumn get coverUrl => text().nullable()();
  /// 歌曲本地子文件夹绝对路径（如 /storage/emulated/0/Download/JoyTune/晴天-周杰伦）
  TextColumn get folderPath => text()();
  /// 音频本地路径（folderPath/<歌名>-<歌手>.mp3）
  TextColumn get audioPath => text()();
  /// 封面本地路径（folderPath/<歌名>-<歌手>.jpg，下载失败可空）
  TextColumn get coverPath => text().nullable()();
  /// 歌词本地路径（folderPath/<歌名>-<歌手>.lrc，下载失败可空）
  TextColumn get lyricsPath => text().nullable()();
  /// 下载时间
  DateTimeColumn get downloadedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId, source};
}
