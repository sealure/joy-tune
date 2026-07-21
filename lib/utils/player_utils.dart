import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';

/// 播放单曲：加入当前队列并跳转播放页
void playSong(BuildContext context, WidgetRef ref, Song song) {
  ref.read(audioServiceProvider).insertNext(song);
  context.push('/player', extra: song);
}
