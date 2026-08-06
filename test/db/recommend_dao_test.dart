// 推荐歌单缓存 DAO 层单元测试（drift 内存数据库，纯 Dart VM）

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/db/app_database.dart';
import 'package:joy_tune/db/daos/recommend_dao.dart';

void main() {
  late AppDatabase db;
  late RecommendDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = RecommendDao(db);
  });

  tearDown(() => db.close());

  /// 构造推荐歌单插入行（保留服务端返回顺序）
  LocalRecommendPlaylistsCompanion playlistRow(int id, String name, {int order = 0}) {
    return LocalRecommendPlaylistsCompanion.insert(
      remoteId: drift.Value(id),
      name: name,
      description: drift.Value('描述$id'),
      coverUrl: drift.Value(''),
      type: drift.Value(id == 1 ? 'system' : 'user'),
      songCount: drift.Value(3),
      playCount: drift.Value(0),
      ownerNickname: drift.Value(id == 2 ? '分享者' : ''),
      ownerAvatarUrl: drift.Value(''),
      orderIndex: drift.Value(order),
    );
  }

  /// 构造歌单歌曲插入行（保留歌单内顺序）
  LocalRecommendPlaylistSongsCompanion songRow(int playlistId, String songId, {int order = 0}) {
    return LocalRecommendPlaylistSongsCompanion.insert(
      playlistRemoteId: playlistId,
      songId: songId,
      source: drift.Value('joox'),
      songName: '歌曲$songId',
      artist: drift.Value('歌手'),
      album: drift.Value(''),
      coverUrl: drift.Value(null),
      picId: drift.Value('p$songId'),
      lyricId: drift.Value('l$songId'),
      sortOrder: drift.Value(order),
    );
  }

  group('推荐歌单列表 DAO', () {
    test('replacePlaylists 整体覆盖，getPlaylists 按 orderIndex 排序', () async {
      await dao.replacePlaylists(playlists: [playlistRow(2, '分享歌单', order: 1), playlistRow(1, '推荐', order: 0)]);
      final all = await dao.getPlaylists();
      expect(all.length, 2);
      // 服务端返回顺序：推荐(order 0) 在前
      expect(all.first.name, '推荐');
      expect(all.first.type, 'system');
      expect(all.last.ownerNickname, '分享者');

      // 再次整体覆盖：旧数据被清空
      await dao.replacePlaylists(playlists: [playlistRow(9, '新推荐')]);
      final after = await dao.getPlaylists();
      expect(after.length, 1);
      expect(after.first.name, '新推荐');
    });

    test('watchPlaylists 流式反映 replace 变化', () async {
      final emissions = <List<LocalRecommendPlaylist>>[];
      final sub = dao.watchPlaylists().listen(emissions.add);

      await dao.replacePlaylists(playlists: [playlistRow(1, '推荐')]);
      await dao.replacePlaylists(playlists: [playlistRow(1, '推荐'), playlistRow(2, '分享歌单', order: 1)]);
      // 等待流式事件送达
      await pumpEventQueue();
      await sub.cancel();

      // 最终事件应包含两次覆盖后的最新结果（期间可能合并中间态）
      expect(emissions.last.length, 2);
      expect(emissions.last.first.name, '推荐');
    });

    test('hasPlaylistCache 初始为空，写入后为 true', () async {
      expect(await dao.hasPlaylistCache(), isFalse);
      await dao.replacePlaylists(playlists: [playlistRow(1, '推荐')]);
      expect(await dao.hasPlaylistCache(), isTrue);
    });
  });

  group('推荐歌单歌曲 DAO', () {
    test('replaceSongs 覆盖单个歌单，getSongs 按 sortOrder 排序', () async {
      await dao.replaceSongs(playlistId: 1, songs: [songRow(1, 'b', order: 1), songRow(1, 'a', order: 0)]);
      final songs = await dao.getSongs(1);
      expect(songs.length, 2);
      expect(songs.first.songId, 'a'); // sortOrder 0 在前
      expect(songs.first.picId, 'pa');
      expect(songs.first.lyricId, 'la');

      // 再次覆盖：仅剩新内容，且不污染其他歌单
      await dao.replaceSongs(playlistId: 1, songs: [songRow(1, 'c')]);
      expect((await dao.getSongs(1)).length, 1);
      expect((await dao.getSongs(1)).first.songId, 'c');
    });

    test('不同歌单歌曲互不影响', () async {
      await dao.replaceSongs(playlistId: 1, songs: [songRow(1, 'a')]);
      await dao.replaceSongs(playlistId: 2, songs: [songRow(2, 'x')]);
      expect((await dao.getSongs(1)).single.songId, 'a');
      expect((await dao.getSongs(2)).single.songId, 'x');
    });

    test('watchSongs 流式反映 replace 变化', () async {
      final emissions = <List<LocalRecommendPlaylistSong>>[];
      final sub = dao.watchSongs(1).listen(emissions.add);

      await dao.replaceSongs(playlistId: 1, songs: [songRow(1, 'a')]);
      await dao.replaceSongs(playlistId: 1, songs: [songRow(1, 'a'), songRow(1, 'b', order: 1)]);
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.last.length, 2);
    });
  });

  group('同步时间戳 DAO', () {
    test('未同步返回 null，setSyncedAt 后可读', () async {
      expect(await dao.lastSyncedAt(), isNull);

      final t = DateTime(2026, 8, 5, 12, 0, 0);
      await dao.setSyncedAt(t);
      expect(await dao.lastSyncedAt(), t);

      // 覆盖写入
      final t2 = t.add(const Duration(hours: 1));
      await dao.setSyncedAt(t2);
      expect(await dao.lastSyncedAt(), t2);
    });
  });
}
