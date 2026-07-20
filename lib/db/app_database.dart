import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';

// ── 本地收藏模型 ──

@collection
class FavoriteSongDb {
  Id id = Isar.autoIncrement;
  late String songId;
  late String source;
  late String name;
  late String artist;
  late String album;
  String? coverUrl;
  String? lyricId;
  late DateTime addedAt;

  /// 转成业务层 Song 模型
  Song toSong() => Song(
        id: songId,
        source: source,
        name: name,
        artist: artist,
        album: album,
        picId: coverUrl,
        lyricId: lyricId,
      );
}

// ── 本地用户模型 ──

@collection
class LocalUserDb {
  Id id = Isar.autoIncrement;
  late String uuid;
  late String nickname;
  late int avatarIndex;
  late DateTime createdAt;
}

// ── 数据库初始化 ──

class AppDatabase {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) return _isar!;
    await initialize();
    return _isar!;
  }

  static Future<void> initialize() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [FavoriteSongDbSchema, LocalUserDbSchema],
      directory: dir.path,
      name: 'via_music',
    );
  }
}
