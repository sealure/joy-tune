import '../models/song.dart';
import '../api/gdmusic_client.dart';
import '../services/song_resolver.dart';
import 'audio_cache.dart';

/// 音频预缓存服务
/// 在当前歌曲播放时，后台预缓存下一首歌的音频和元数据，实现无感切歌
class PrefetchService {
  static final PrefetchService instance = PrefetchService._();
  PrefetchService._();

  /// 取消标志：调用 cancel() 后置 true，跳过后续步骤
  bool _cancelled = false;

  /// 预缓存队列中下一首歌的音频和元数据
  Future<void> prefetchNext({
    required SongResolver resolver,
    required GdMusicClient client,
    required List<Song> queue,
    required int currentIndex,
    required PlayMode playMode,
  }) async {
    // 取消之前的预缓存任务
    _cancelled = true;
    _cancelled = false;

    if (queue.isEmpty || currentIndex < 0) return;

    final nextIdx = playMode.nextIndex(currentIndex, queue.length);
    if (nextIdx == currentIndex) return; // 只有一首歌，无需预缓存

    final song = queue[nextIdx];
    final cacheKey = AudioCache.cacheKey(song.name, song.artist);
    final cache = AudioCache.instance;

    // 已缓存则跳过
    if (await cache.has(cacheKey)) {
      print('[Prefetch] 已缓存，跳过: ${song.name}');
      return;
    }

    if (_cancelled) return;

    try {
      // 使用 resolveDirectly 解析（有 ID，不重新搜索）
      final result = await resolver.resolveDirectly(song);
      if (result == null || _cancelled) {
        print('[Prefetch] 解析失败或已取消: ${song.name}');
        return;
      }

      if (_cancelled) return;

      // 获取播放 URL
      final playUrl = await client.getPlayUrl(
        songId: result.playable.id,
        source: result.playable.source,
      );

      if (_cancelled) return;

      // 并发：下载音频 + 保存元数据
      await Future.wait([
        cache.download(playUrl.url, cacheKey),
        cache.saveMetadata(cacheKey, {
          'coverUrl': result.coverUrl,
          'lyrics': result.lyricsText,
        }),
      ]);

      print('[Prefetch] 预缓存完成: ${song.name}');
    } catch (e) {
      // 预缓存失败静默处理，不影响正常播放
      print('[Prefetch] 预缓存失败: ${song.name} - $e');
    }
  }

  /// 取消当前预缓存任务
  void cancel() {
    _cancelled = true;
  }
}
