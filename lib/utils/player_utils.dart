import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';

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
