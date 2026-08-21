// 下载服务：把歌曲（音频+封面+歌词）下载到用户可见的系统下载目录
//   Android: /storage/emulated/0/Download/JoyTune/<歌名>-<歌手>/
//   桌面端:   ~/Downloads/JoyTune/<歌名>-<歌手>/
// 与缓存（AudioCache / local_song_meta）独立：下载不在缓存目录、不随缓存清理删除。
// 单曲下载完成后写 local_downloads 记录；UI 三态（未下载/下载中/已下载）由
// downloadingKeys 流驱动。播放联动见 AudioService.playSong（已下载本地优先）。

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../api/gdmusic_client.dart';
import '../db/daos/pic_cover_dao.dart';
import '../db/daos/song_meta_dao.dart';
import '../models/song.dart';
import '../repositories/download_repository.dart';
import '../utils/cover_resolver.dart';
import '../utils/download_path.dart';
import 'audio_cache.dart';
import 'song_resolver.dart';

/// 下载产物的本地路径集合
class DownloadedSong {
  /// 落盘点歌曲元数据（可能有音源转换的 playable）
  final Song song;
  /// 子文件夹绝对路径（下载/JoyTune/<歌名>-<歌手>）
  final String folderPath;
  /// 音频本地路径（文件夹内 <歌名>-<歌手>.mp3）
  final String audioPath;
  /// 封面本地路径（文件夹内 <歌名>-<歌手>.jpg，下载成功才非空）
  final String? coverPath;
  /// 歌词本地路径（文件夹内 <歌名>-<歌手>.lrc，下载成功才非空）
  final String? lyricsPath;

  const DownloadedSong({
    required this.song,
    required this.folderPath,
    required this.audioPath,
    this.coverPath,
    this.lyricsPath,
  });

  /// 下载记录的展示 Song（含封面 URL 供已下载页解析本地/网络封面）
  Song toSong() => song;
}

/// 歌曲下载服务（复用 [SongResolver.resolveDirectly] + getPlayUrl 统一解析链路）
class DownloadService {
  final DownloadRepository _repository;
  final SongResolver? _songResolver;
  final GdMusicClient? _gdMusicClient;
  /// 歌曲元数据缓存（local_song_meta：coverUrl/lyrics），播放/列表已回填，下载复用
  final SongMetaDao? _songMetaDao;
  /// 封面解析结果缓存（local_pic_covers：picId → coverUrl），按 picId 复用
  final PicCoverDao? _picCoverDao;
  final Dio _dio = Dio();

  /// 正在下载的歌曲集合（key = `${songId}_${source}`）
  final StreamController<Set<String>> _downloadingController =
      StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get downloadingStream => _downloadingController.stream;
  final Set<String> _downloading = {};
  void _setDownloading(String key, bool value) {
    if (value) {
      _downloading.add(key);
    } else {
      _downloading.remove(key);
    }
    _downloadingController.add(Set.unmodifiable(_downloading));
  }

  DownloadService({
    required DownloadRepository repository,
    SongResolver? songResolver,
    GdMusicClient? gdMusicClient,
    SongMetaDao? songMetaDao,
    PicCoverDao? picCoverDao,
  })  : _repository = repository,
        _songResolver = songResolver,
        _gdMusicClient = gdMusicClient,
        _songMetaDao = songMetaDao,
        _picCoverDao = picCoverDao;

  /// 是否正在下载
  bool isDownloading(Song song) =>
      _downloading.contains('${song.id}_${song.source}');

  /// 下载单曲。成功返回产物路径集合；失败返回 null。
  ///
  /// 流程：优先复用 AudioCache 缓存音频文件（收藏里已缓存过的歌离线也能下载）→
  /// 未缓存且联网解析 → 建目录 → 并发下载 <歌名>-<歌手>.mp3/.jpg/.lrc → 写记录。
  /// 封面/歌词下载失败不阻断（文件可选），音频失败则整体失败。
  /// 文件名：基础名 = 子文件夹名（sanitizeFolderName 的安全版歌名-歌手），
  /// 三个文件同名不同扩展名 → 外部播放器（如 Windows 媒体播放器）打开 .mp3
  /// 会自动按同名关联 .jpg 封面与 .lrc 歌词。
  ///
  /// 下载流程：
  /// 1. 音频：优先复用 AudioCache 已缓存文件（播放/试听自动缓存过，见
  ///    AudioService.playSong 缓存分支）；未缓存才走 SongResolver.resolveDirectly
  ///    解析 + getPlayUrl 联网下载。
  /// 2. 封面/歌词：优先读本地磁盘元数据缓存 —— local_song_meta（播放/列表已
  ///    回填 coverUrl + lyrics）、local_pic_covers（picId→coverUrl），都未命中
  ///    才走 searchCoverUrl / searchLyricsText 网络兜底。这一步与音频来源解耦，
  ///    保证即使从"已缓存歌"下载也能拿到封面歌词。
  /// 3. 落盘三文件同名真实名 + 写 local_downloads 记录。
  Future<DownloadedSong?> download(Song song) async {
    final key = '${song.id}_${song.source}';
    if (_downloading.contains(key)) return null; // 幂等：已在下载中
    _setDownloading(key, true);
    try {
      final result = await _downloadInner(song);
      return result;
    } catch (e) {
      print('[Download] 下载失败: ${song.name} - $e');
      return null;
    } finally {
      _setDownloading(key, false);
    }
  }

  Future<DownloadedSong?> _downloadInner(Song song) async {
    final resolver = _songResolver;
    final client = _gdMusicClient;

    // 0. 转 HTTP(S) 校验：AudioCache 使用"歌名-歌手"作 key（与播放链路一致），
    //    已缓存过（播放/试听自动缓存）→ 直接复用缓存音频文件，无需联网。
    final cache = AudioCache.instance;
    final cacheKey = AudioCache.cacheKey(song.name, song.artist);
    String? playLocal;
    String? playUrl;
    String? coverUrl;
    String? lyricsText;

    // 优先复用 AudioCache 缓存音频文件（"收藏"里已缓存过的歌，离线也能下载）
    playLocal = await cache.getLocalPath(cacheKey);
    if (playLocal == null) {
      print('[Download] 无缓存，联网解析: ${song.name}');
      if (resolver == null || client == null) return null;
      final result = await resolver.resolveDirectly(song);
      if (result != null) {
        final playable = result.playable;
        coverUrl = result.coverUrl;
        lyricsText = result.lyricsText;
        final url = await client.getPlayUrl(
          songId: playable.id,
          source: playable.source,
        );
        if (url.url.isEmpty) return null;
        playUrl = url.url;
        // 缓存元数据（封面/歌词）一并写入 AudioCache 的 json，下次播放命中
        if (coverUrl != null || lyricsText != null) {
          unawaited(cache.saveMetadata(cacheKey, {
            'coverUrl': coverUrl,
            'lyrics': lyricsText,
          }).catchError((_) {}));
        }
      }
    }

    // 1. 建目录 下载/JoyTune/<歌名>-<歌手>/
    final root = await getDownloadsRoot();
    final folderName = sanitizeFolderName(song.name, song.artist);
    final folder = Directory('${root.path}/JoyTune/$folderName');
    if (!await folder.exists()) await folder.create(recursive: true);

    // 2. 落音频/封面/歌词：三个文件用真实基础名（歌名-歌手），扩展名区分。
    //    基础名与文件夹同名 → 其它播放器打开 .mp3 会按同名自动关联 .jpg/.lrc。
    final audioPath = '${folder.path}/$folderName.mp3';
    final coverPath = '${folder.path}/$folderName.jpg';
    final lyricsPath = '${folder.path}/$folderName.lrc';

    if (playLocal != null && await File(playLocal).exists()) {
      // 从缓存目录复制到下载目录（跨目录拷贝，保留缓存原文件）
      await File(playLocal).copy(audioPath);
    } else if (playUrl != null) {
      await _dio.download(playUrl, audioPath);
    }
    if (!await File(audioPath).exists()) {
      print('[Download] 音频未生成: ${song.name}');
      return null;
    }

    // 3. 封面/歌词：优先读本地元数据缓存（local_song_meta 已由播放/列表回填
    //    coverUrl + lyrics；local_pic_covers 已由 lazy 解析回填 picId→URL），
    //    只有缓存也没有才走网络解析兜底。写盘尽力而为。
    final metaDao = _songMetaDao;
    coverUrl = coverUrl?.isNotEmpty == true
        ? coverUrl
        : song.coverUrl?.isNotEmpty == true
            ? song.coverUrl
            : await _readCachedCoverUrl(metaDao, song);
    if (coverUrl == null || coverUrl.isEmpty) {
      coverUrl = await resolver?.searchCoverUrl(song) ?? null;
    }

    lyricsText = lyricsText?.isNotEmpty == true
        ? lyricsText
        : await _readCachedLyrics(metaDao, song);
    if (lyricsText == null || lyricsText.isEmpty) {
      lyricsText = await resolver?.searchLyricsText(song) ?? null;
    }
    String? savedCover;
    String? savedLyrics;
    await Future.wait([
      _downloadCover(coverUrl, coverPath),
      _downloadLyrics(lyricsText, lyricsPath),
    ]);
    if (await File(coverPath).exists()) savedCover = coverPath;
    if (await File(lyricsPath).exists()) savedLyrics = lyricsPath;

    // 4. 写下载记录（数据库），保留源歌曲元数据以便离线列表展示
    final downloaded = DownloadedSong(
      song: song,
      folderPath: folder.path,
      audioPath: audioPath,
      coverPath: savedCover,
      lyricsPath: savedLyrics,
    );
    await _repository.recordDownload(
      song: song,
      folderPath: downloaded.folderPath,
      audioPath: downloaded.audioPath,
      coverPath: downloaded.coverPath,
      lyricsPath: downloaded.lyricsPath,
    );
    print('[Download] 完成: ${song.name} → $audioPath');
    return downloaded;
  }

  /// 下载封面（可选文件；无 URL / 失败静默）
  Future<void> _downloadCover(String? coverUrl, String path) async {
    if (coverUrl == null || coverUrl.isEmpty) return;
    try {
      await _dio.download(coverUrl, path);
    } catch (e) {
      print('[Download] 封面下载失败（忽略）: $e');
    }
  }

  /// 下载歌词（可选文件；无歌词文本 / 失败静默）
  Future<void> _downloadLyrics(String? lyricsText, String path) async {
    if (lyricsText == null || lyricsText.isEmpty) return;
    try {
      await File(path).writeAsString(lyricsText);
    } catch (e) {
      print('[Download] 歌词写盘失败（忽略）: $e');
    }
  }

  /// 从本地元数据缓存读封面 URL：优先 local_song_meta（playback/列表已回填），
  /// 其次按 picId 从 local_pic_covers 读（无则返回 null，交由调用方网络兜底）。
  Future<String?> _readCachedCoverUrl(SongMetaDao? metaDao, Song song) async {
    if (metaDao == null) return null;
    try {
      // 1) local_song_meta：按 (song_id, source) 缓存了解析后的封面 URL
      final cached = await metaDao.getCoverUrl(song.id, song.source);
      if (cached != null && cached.isNotEmpty) return cached;
      // 2) local_pic_covers：按 (pic_id, source) 缓存了 picId → coverUrl
      if (song.picId != null && song.picId!.isNotEmpty) {
        final byPic = await _picCoverDao?.getCoverUrl(song.picId!, song.source);
        if (byPic != null && byPic.isNotEmpty) return byPic;
        // 3) 缓存没有但 picId 在 → 走统一懒解析（写回 local_pic_covers，不触发全量搜索）
        final client = _gdMusicClient;
        if (client != null) {
          return resolveCoverByPic(
            client: client,
            picDao: _picCoverDao,
            picId: song.picId!,
            source: song.source,
          );
        }
      }
    } catch (e) {
      print('[Download] 读封面缓存失败（忽略）: $e');
    }
    return null;
  }

  /// 从本地元数据缓存读歌词全文（local_song_meta，播放后已回填）
  Future<String?> _readCachedLyrics(SongMetaDao? metaDao, Song song) async {
    if (metaDao == null) return null;
    try {
      final cached = await metaDao.getLyrics(song.id, song.source);
      return (cached == null || cached.isEmpty) ? null : cached;
    } catch (e) {
      print('[Download] 读歌词缓存失败（忽略）: $e');
      return null;
    }
  }

  /// 删除下载：删本地文件夹（歌曲/图片/歌词）+ 数据库记录
  Future<void> remove(Song song) async {
    try {
      final record = await _repository.getByKey(song.id, song.source);
      if (record != null) {
        final folder = Directory(record.folderPath);
        if (await folder.exists()) {
          await folder.delete(recursive: true);
        }
      }
    } catch (e) {
      print('[Download] 删除本地文件失败: $e');
    }
    await _repository.removeRecord(song.id, song.source);
  }

  /// 关闭资源（应用退出时）
  void dispose() {
    _downloadingController.close();
  }
}