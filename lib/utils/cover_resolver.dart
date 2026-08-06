// 封面解析工具（统一入口）
// 提供两种解析：
// - resolveCoverUrl：按歌曲对象解析（已带 coverUrl → 直接返回；否则按 picId 懒加载）
// - resolveCoverByPic：按 (pic_id, source) 懒加载解析封面 URL，供歌曲封面与歌单封面共用
//
// 解析优先级：内存缓存 → sqlite（local_pic_covers，重启免 API）→ 外部 API → 写回内存+磁盘。
// 缓存 key 用 `${source}_${picId}`，与 SongCover / PlaylistCover 一致，跨组件共享同一份结果。

import '../api/gdmusic_client.dart';
import '../db/daos/pic_cover_dao.dart';
import '../models/song.dart';

/// 封面 URL 内存缓存：缓存键 `${source}_${picId}` → 封面 URL
/// 歌曲封面、歌单封面、首页卡片共用，避免重复请求
final Map<String, String?> coverUrlCache = {};

/// 封面 URL 请求中集合：防止并发重复发起解析请求
final Set<String> coverUrlInFlight = {};

/// 解析歌曲封面 URL
/// - [song.coverUrl] 已有完整 URL 直接返回（如收藏页、歌单加入的歌）
/// - 否则按 [song.picId] 懒加载调用外部 API 解析
/// - 都缺失或解析失败返回 null（调用方降级为占位图）
Future<String?> resolveCoverUrl(GdMusicClient client, Song song) async {
  if (song.coverUrl != null && song.coverUrl!.isNotEmpty) {
    return song.coverUrl;
  }
  if (song.picId == null || song.picId!.isEmpty) return null;
  return resolveCoverByPic(
    client: client,
    picDao: null,
    picId: song.picId!,
    source: song.source,
  );
}

/// 按 (pic_id, source) 懒加载解析封面 URL（歌曲封面与歌单封面共用）
///
/// 解析流程：命中内存缓存 `${source}_${picId}` → 命中 sqlite local_pic_covers →
/// 调外部 API 解析 → 写内存 + 写 sqlite 落库（重启免网络）。
/// [picDao] 可空：为空时跳过磁盘缓存（仅内存），用于无 DB 上下文的调用方。
Future<String?> resolveCoverByPic({
  required GdMusicClient client,
  PicCoverDao? picDao,
  required String picId,
  required String source,
}) async {
  final key = '${source}_$picId';

  // 命中内存缓存直接返回
  if (coverUrlCache.containsKey(key)) return coverUrlCache[key];

  // 请求进行中则跳过，避免同一封面并发重复请求
  if (coverUrlInFlight.contains(key)) return null;
  coverUrlInFlight.add(key);

  try {
    String? url;
    // 优先读本地 sqlite 缓存（local_pic_covers，key = pic_id + source）
    if (picDao != null) {
      try {
        url = await picDao.getCoverUrl(picId, source);
      } catch (_) {
        // 缓存不可达时忽略，走实时解析
      }
    }
    if (url == null || url.isEmpty) {
      final resolved = await client.getCoverUrl(picId: picId, source: source);
      if (resolved.isNotEmpty) {
        url = resolved;
        if (picDao != null) {
          try {
            await picDao.upsert(picId: picId, source: source, coverUrl: resolved);
          } catch (_) {
            // 持久化失败不影响本次显示
          }
        }
      }
    }
    coverUrlCache[key] = url;
    return url;
  } catch (_) {
    // 解析失败：保持 null，不写入缓存以便下次重试
    return null;
  } finally {
    coverUrlInFlight.remove(key);
  }
}