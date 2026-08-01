// 歌曲封面解析工具（统一入口）
// 解析优先级：已带 coverUrl → 按 picId 懒加载
// ApiFavoriteRepository / SongResolver / 选择歌单弹层 / 搜索页 共用，避免逻辑重复

import '../api/gdmusic_client.dart';
import '../models/song.dart';

/// 解析歌曲封面 URL
/// - [song.coverUrl] 已有完整 URL 直接返回（如收藏页、歌单加入的歌）
/// - 否则按 [song.picId] 懒加载调用外部 API 解析
/// - 都缺失或解析失败返回 null（调用方降级为占位图）
Future<String?> resolveCoverUrl(GdMusicClient client, Song song) async {
  if (song.coverUrl != null && song.coverUrl!.isNotEmpty) {
    return song.coverUrl;
  }
  if (song.picId == null || song.picId!.isEmpty) return null;
  try {
    return await client.getCoverUrl(picId: song.picId!, source: song.source);
  } catch (_) {
    return null;
  }
}
