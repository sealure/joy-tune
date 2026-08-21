import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../services/song_resolver.dart';

/// 播放单曲：停止当前播放，加入队列并跳转播放页
void playSong(BuildContext context, WidgetRef ref, Song song) {
  print('[playSong] ${song.name} id=${song.id}');
  final audio = ref.read(audioServiceProvider);
  audio.stop();
  print('[playSong] stop完成, currentSongId=${audio.currentSongId}');
  audio.insertNext(song);
  print('[playSong] insertNext完成, queueLen=${audio.queue.length}');
  context.push('/player', extra: song);
}

/// 试听单曲：停止当前播放，加入队列并原地播放，不跳转播放页
/// 与 [playSong] 的区别仅在最后一步不执行 context.push('/player')，
/// 效果是搜索页等列表页点「播放」图标即可在当前页试听，底部迷你播放栏联动。
/// 复用 AudioService.playSong 统一链路（查缓存→解析→播放→自动预缓存下一首）。
/// 返回解析/缓存到的元数据供调用方更新 UI（可为空）。
Future<SongResolveResult?> previewSong(WidgetRef ref, Song song) async {
  print('[previewSong] ${song.name} id=${song.id}');
  final audio = ref.read(audioServiceProvider);
  audio.stop();
  print('[previewSong] stop完成, currentSongId=${audio.currentSongId}');
  audio.insertNext(song);
  print('[previewSong] insertNext完成, queueLen=${audio.queue.length}');
  final result = await audio.playSong(song);
  print('[previewSong] playSong完成, result=${result != null ? "OK" : "NULL"}');
  return result;
}
