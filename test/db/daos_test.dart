// 数据库 DAO 层单元测试（drift 内存数据库，纯 Dart VM）

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tune/db/app_database.dart';
import 'package:joy_tune/db/daos/favorite_dao.dart';
import 'package:joy_tune/db/daos/play_record_dao.dart';
import 'package:joy_tune/db/daos/playlist_dao.dart';
import 'package:joy_tune/db/daos/search_history_dao.dart';
import 'package:joy_tune/db/daos/session_dao.dart';
import 'package:joy_tune/db/daos/settings_dao.dart';
import 'package:joy_tune/db/daos/song_meta_dao.dart';
import 'package:joy_tune/db/daos/download_dao.dart';
import 'package:joy_tune/models/song.dart';

void main() {
  late AppDatabase db;
  late FavoriteDao favoriteDao;
  late PlaylistDao playlistDao;
  late PlayRecordDao playRecordDao;
  late SearchHistoryDao searchHistoryDao;
  late SessionDao sessionDao;
  late SettingsDao settingsDao;
  late SongMetaDao songMetaDao;
  late DownloadDao downloadDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    favoriteDao = FavoriteDao(db);
    playlistDao = PlaylistDao(db);
    playRecordDao = PlayRecordDao(db);
    searchHistoryDao = SearchHistoryDao(db);
    sessionDao = SessionDao(db);
    settingsDao = SettingsDao(db);
    songMetaDao = SongMetaDao(db);
    downloadDao = DownloadDao(db);
  });

  tearDown(() => db.close());

  Song song(String id) => Song(
        id: id,
        source: 'joox',
        name: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
      );

  group('收藏 DAO', () {
    test('插入后 watchAll 可见，重复插入幂等', () async {
      await favoriteDao.insertFavorite(song('1'));
      await favoriteDao.insertFavorite(song('1'));
      final all = await favoriteDao.getAll();
      expect(all.length, 1);
      expect(all.first.name, '晴天');
    });

    test('未同步时取消收藏直接物理删除', () async {
      await favoriteDao.insertFavorite(song('1'));
      await favoriteDao.softDelete('1', 'joox');
      expect(await favoriteDao.getAll(), isEmpty);
      expect(await favoriteDao.pendingToDelete(), isEmpty);
    });

    test('已同步后取消收藏为 soft delete，pendingToDelete 可查', () async {
      await favoriteDao.insertFavorite(song('1'));
      await favoriteDao.markSynced('1', 'joox');
      await favoriteDao.softDelete('1', 'joox');
      final pending = await favoriteDao.pendingToDelete();
      expect(pending.length, 1);
      expect(pending.first.deleted, isTrue);
      // watchAll 不显示已删除
      expect(await favoriteDao.getAll(), isEmpty);
      // removeRow 物理删除
      await favoriteDao.removeRow('1', 'joox');
      expect(await favoriteDao.pendingToDelete(), isEmpty);
    });

    test('soft delete 后重新收藏恢复', () async {
      await favoriteDao.insertFavorite(song('1'));
      await favoriteDao.markSynced('1', 'joox');
      await favoriteDao.softDelete('1', 'joox');
      await favoriteDao.insertFavorite(song('1'));
      expect(await favoriteDao.getAll(), hasLength(1));
      expect(await favoriteDao.isFavorited('1', 'joox'), isTrue);
      // 恢复后需重新同步
      expect(await favoriteDao.pendingToPush(), hasLength(1));
    });

    test('isFavorited / count', () async {
      expect(await favoriteDao.count(), 0);
      await favoriteDao.insertFavorite(song('1'));
      expect(await favoriteDao.isFavorited('1', 'joox'), isTrue);
      expect(await favoriteDao.count(), 1);
    });
  });

  group('歌单 DAO', () {
    test('创建歌单并回填 remoteId', () async {
      await playlistDao.create(
        LocalPlaylistsCompanion.insert(id: 'local-1', name: '华语经典'),
      );
      final p = await playlistDao.getById('local-1');
      expect(p!.name, '华语经典');
      expect(p.remoteId, isNull);
      await playlistDao.markSynced('local-1', remoteId: 42);
      final synced = await playlistDao.getById('local-1');
      expect(synced!.remoteId, 42);
      expect(synced.isSynced, isTrue);
    });

    test('添加歌曲并按 sortOrder 排序', () async {
      await playlistDao.create(
        LocalPlaylistsCompanion.insert(id: 'local-1', name: '华语经典'),
      );
      await playlistDao.addSong(
        playlistId: 'local-1', songId: 'a', source: 'joox',
        songName: '晴天', artist: '周杰伦',
      );
      await playlistDao.addSong(
        playlistId: 'local-1', songId: 'b', source: 'joox',
        songName: '七里香', artist: '周杰伦',
      );
      final songs = await playlistDao.getSongs('local-1');
      expect(songs.length, 2);
      expect(songs.first.songId, 'a');
      // 重复添加幂等
      await playlistDao.addSong(
        playlistId: 'local-1', songId: 'a', source: 'joox',
        songName: '晴天', artist: '周杰伦',
      );
      expect(await playlistDao.getSongs('local-1'), hasLength(2));
    });

    test('软删除歌单（已同步）pending 可查，removeRow 级联删歌曲', () async {
      await playlistDao.create(
        LocalPlaylistsCompanion.insert(id: 'local-1', name: '华语经典'),
      );
      await playlistDao.addSong(
        playlistId: 'local-1', songId: 'a', source: 'joox',
        songName: '晴天', artist: '周杰伦',
      );
      await playlistDao.markSynced('local-1', remoteId: 1);
      await playlistDao.softDelete('local-1');
      expect(await playlistDao.pendingDeletePlaylists(), hasLength(1));
      await playlistDao.removeRow('local-1');
      expect(await playlistDao.getById('local-1'), isNull);
      expect(await playlistDao.getSongs('local-1'), isEmpty);
    });

    test('带歌曲数的列表', () async {
      await playlistDao.create(
        LocalPlaylistsCompanion.insert(id: 'local-1', name: '华语经典'),
      );
      await playlistDao.addSong(
        playlistId: 'local-1', songId: 'a', source: 'joox',
        songName: '晴天', artist: '周杰伦',
      );
      final list = await playlistDao.watchAllWithCount().first;
      expect(list.length, 1);
      expect(list.first.songCount, 1);
    });
  });

  group('播放记录 DAO', () {
    test('pendingToPush 按 id 升序，markSynced 后不再推送', () async {
      await playRecordDao.addRecord(song('a'));
      await playRecordDao.addRecord(song('b'));
      final pending = await playRecordDao.pendingToPush();
      expect(pending.length, 2);
      expect(pending.first.songId, 'a');
      await playRecordDao.markSynced(pending.first.id);
      expect(await playRecordDao.pendingToPush(), hasLength(1));
    });

    test('attemptCount 超过 10 后不再推送', () async {
      await playRecordDao.addRecord(song('a'));
      final row = (await playRecordDao.pendingToPush()).first;
      for (var i = 0; i < 10; i++) {
        await playRecordDao.incrementAttempt(row.id);
      }
      expect(await playRecordDao.pendingToPush(), isEmpty);
    });

    test('clearAll 清空', () async {
      await playRecordDao.addRecord(song('a'));
      await playRecordDao.clearAll();
      expect(await playRecordDao.getAll(), isEmpty);
    });
  });

  group('搜索历史 DAO', () {
    test('去重置顶', () async {
      await searchHistoryDao.addKeyword('晴天');
      await searchHistoryDao.addKeyword('七里香');
      await searchHistoryDao.addKeyword('晴天');
      final keywords = await searchHistoryDao.getKeywords();
      expect(keywords, ['晴天', '七里香']);
    });

    test('清空', () async {
      await searchHistoryDao.addKeyword('晴天');
      await searchHistoryDao.clearAll();
      expect(await searchHistoryDao.getKeywords(), isEmpty);
    });
  });

  group('播放会话 DAO', () {
    test('save/load/clear 单行', () async {
      await sessionDao.saveSession(queueJson: '[]', currentIndex: 2, positionMs: 1000);
      final s = await sessionDao.loadSession();
      expect(s!.currentIndex, 2);
      expect(s.positionMs, 1000);
      await sessionDao.saveSession(queueJson: '[]', currentIndex: 0, positionMs: 0);
      final s2 = await sessionDao.loadSession();
      expect(s2!.currentIndex, 0);
      await sessionDao.clearSession();
      expect(await sessionDao.loadSession(), isNull);
    });
  });

  group('设置 DAO', () {
    test('set/get/remove', () async {
      await settingsDao.set('device_id', 'abc');
      expect(await settingsDao.get('device_id'), 'abc');
      await settingsDao.remove('device_id');
      expect(await settingsDao.get('device_id'), isNull);
    });
  });

  group('歌曲元数据缓存 DAO (song_meta)', () {
    test('upsert 后按 song_id+source 读取歌词/封面', () async {
      await songMetaDao.upsert(
        songId: 'abc123',
        source: 'joox',
        name: '晴天',
        artist: '周杰伦',
        picId: 'pic-1',
        lyricId: 'lyric-1',
        coverUrl: 'https://cover/x.jpg',
        lyrics: '[00:00.00]晴天',
      );
      expect(await songMetaDao.getLyrics('abc123', 'joox'), '[00:00.00]晴天');
      expect(await songMetaDao.getCoverUrl('abc123', 'joox'), 'https://cover/x.jpg');
      final row = await songMetaDao.get('abc123', 'joox');
      expect(row!.lyricId, 'lyric-1');
      expect(row.picId, 'pic-1');
    });

    test('不同音源同 song_id 独立缓存', () async {
      await songMetaDao.upsert(songId: '1', source: 'joox', lyrics: 'joox歌词');
      await songMetaDao.upsert(songId: '1', source: 'netease', lyrics: 'netease歌词');
      expect(await songMetaDao.getLyrics('1', 'joox'), 'joox歌词');
      expect(await songMetaDao.getLyrics('1', 'netease'), 'netease歌词');
    });

    test('clearAll 清空', () async {
      await songMetaDao.upsert(songId: '1', source: 'joox', lyrics: 'x');
      await songMetaDao.clearAll();
      expect(await songMetaDao.getLyrics('1', 'joox'), isNull);
    });
  });

  group('下载记录 DAO', () {
    test('插入后 getByKey / watchAll 可见，重复插入幂等', () async {
      await downloadDao.upsert(
        song: song('1'),
        folderPath: '/Download/JoyTune/晴天-周杰伦',
        audioPath: '/Download/JoyTune/晴天-周杰伦/歌曲.mp3',
        coverPath: '/Download/JoyTune/晴天-周杰伦/图片.jpg',
      );
      await downloadDao.upsert(
        song: song('1'),
        folderPath: '/Download/JoyTune/晴天-周杰伦',
        audioPath: '/Download/JoyTune/晴天-周杰伦/歌曲.mp3',
      );
      final row = await downloadDao.getByKey('1', 'joox');
      expect(row!.name, '晴天');
      expect(row.folderPath, '/Download/JoyTune/晴天-周杰伦');
      expect(await downloadDao.getAll(), hasLength(1));
    });

    test('不同音源同 song_id 独立下载记录', () async {
      await downloadDao.upsert(
        song: song('1'),
        folderPath: '/Download/JoyTune/晴天-周杰伦',
        audioPath: '/Download/JoyTune/晴天-周杰伦/歌曲.mp3',
      );
      await downloadDao.upsert(
        song: Song(id: '1', source: 'netease', name: '晴天', artist: '周杰伦', album: ''),
        folderPath: '/Download/JoyTune/晴天-周杰伦',
        audioPath: '/Download/JoyTune/晴天-周杰伦/歌曲.mp3',
      );
      expect(await downloadDao.getAll(), hasLength(2));
    });

    test('remove 后记录删除', () async {
      await downloadDao.upsert(
        song: song('1'),
        folderPath: '/Download/JoyTune/晴天-周杰伦',
        audioPath: '/Download/JoyTune/晴天-周杰伦/歌曲.mp3',
      );
      await downloadDao.remove('1', 'joox');
      expect(await downloadDao.getAll(), isEmpty);
    });
  });
}
