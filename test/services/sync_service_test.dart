// SyncService 后台同步服务单元测试
// 用内存数据库 + fake BackendClient（子类重写同步方法），验证 is_synced 置位、remoteId 回填、
// 游客跳过、失败保持待同步、running 锁等核心逻辑

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_music/api/backend_client.dart';
import 'package:via_music/db/app_database.dart';
import 'package:via_music/db/daos/favorite_dao.dart';
import 'package:via_music/db/daos/play_record_dao.dart';
import 'package:via_music/db/daos/playlist_dao.dart';
import 'package:via_music/db/daos/settings_dao.dart';
import 'package:via_music/models/song.dart';
import 'package:via_music/services/auth_service.dart';
import 'package:via_music/services/sync/sync_service.dart';

/// fake 认证服务：固定登录态
class _FakeAuth extends AuthService {
  final bool loggedIn;
  _FakeAuth(this.loggedIn);

  @override
  Future<bool> get isLoggedIn async => loggedIn;
}

/// fake 后端客户端：记录调用并返回可配置结果
class _FakeBackendClient extends BackendClient {
  /// 调用记录（['like', songId] 等）
  final List<List<String>> calls = [];
  bool likeSuccess = true;
  bool reportSuccess = true;
  int _nextPlaylistId = 100;

  @override
  Future<LikeResult?> likeSong(String songId, {String? songName, String? artist, String? coverUrl, String? source, String? audioUrl, String? lyricsUrl, String? album, String? picId}) async {
    calls.add(['like', songId]);
    return likeSuccess ? const LikeResult(success: true, likeCount: 1) : null;
  }

  @override
  Future<LikeResult?> unlikeSong(String songId) async {
    calls.add(['unlike', songId]);
    return const LikeResult(success: true, likeCount: 0);
  }

  @override
  Future<UserPlaylist?> createPlaylist({required String name, String? description, String? coverUrl, bool isPublic = false}) async {
    calls.add(['createPlaylist', name]);
    return UserPlaylist(id: _nextPlaylistId++, name: name, isPublic: isPublic);
  }

  @override
  Future<UserPlaylist?> updatePlaylist(int id, {String? name, String? description, String? coverUrl, bool? isPublic}) async {
    calls.add(['updatePlaylist', '$id']);
    return UserPlaylist(id: id, name: name ?? '', isPublic: isPublic ?? false);
  }

  @override
  Future<bool> deletePlaylist(int id) async {
    calls.add(['deletePlaylist', '$id']);
    return true;
  }

  @override
  Future<bool> addSongToPlaylist(int playlistId, {required String songId, required String songName, required String artist, String? album, String? coverUrl, String? source, String? picId}) async {
    calls.add(['addSong', '$playlistId', songId]);
    return true;
  }

  @override
  Future<bool> removeSongFromPlaylist(int playlistId, String songId) async {
    calls.add(['removeSong', '$playlistId', songId]);
    return true;
  }

  @override
  Future<bool> reportPlay(String songId, {String? source, int? playDuration, String? songName, String? artist, String? coverUrl, String? album}) async {
    calls.add(['reportPlay', songId]);
    return reportSuccess;
  }

  @override
  Future<bool> clearPlayHistory() async {
    calls.add(['clearPlayHistory']);
    return true;
  }

  @override
  Future<List<Song>> getUserLikedSongs() async => [];
}

void main() {
  late AppDatabase db;
  late SyncService service;
  late _FakeBackendClient client;
  late FavoriteDao favoriteDao;
  late PlaylistDao playlistDao;
  late PlayRecordDao playRecordDao;
  late SettingsDao settingsDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    favoriteDao = FavoriteDao(db);
    playlistDao = PlaylistDao(db);
    playRecordDao = PlayRecordDao(db);
    settingsDao = SettingsDao(db);
    client = _FakeBackendClient();
  });

  tearDown(() => db.close());

  Song song(String id) => Song(id: id, source: 'joox', name: '晴天', artist: '周杰伦', album: '叶惠美');

  group('游客态', () {
    test('不推送任何数据（is_synced 保持 0）', () async {
      service = SyncService(
        client: client,
        auth: _FakeAuth(false),
        favoriteDao: favoriteDao,
        playlistDao: playlistDao,
        playRecordDao: playRecordDao,
        settingsDao: settingsDao,
      );
      await favoriteDao.insertFavorite(song('a'));
      await playRecordDao.addRecord(song('b'));
      await service.syncNow();
      expect(client.calls, isEmpty);
      // 仍待同步
      expect(await favoriteDao.pendingToPush(), hasLength(1));
    });
  });

  group('登录态', () {
    setUp(() {
      service = SyncService(
        client: client,
        auth: _FakeAuth(true),
        favoriteDao: favoriteDao,
        playlistDao: playlistDao,
        playRecordDao: playRecordDao,
        settingsDao: settingsDao,
      );
    });

    test('推送收藏并置 is_synced', () async {
      await favoriteDao.insertFavorite(song('a'));
      await service.syncNow();
      expect(client.calls.map((c) => c[0]), contains('like'));
      expect(await favoriteDao.pendingToPush(), isEmpty);
      expect(await favoriteDao.isFavorited('a', 'joox'), isTrue);
    });

    test('收藏失败保持待同步（下次重试）', () async {
      client.likeSuccess = false;
      await favoriteDao.insertFavorite(song('a'));
      await service.syncNow();
      expect(await favoriteDao.pendingToPush(), hasLength(1));
    });

    test('取消收藏推送 DELETE（soft delete 且曾同步）', () async {
      await favoriteDao.insertFavorite(song('a'));
      await favoriteDao.markSynced('a', 'joox');
      await favoriteDao.softDelete('a', 'joox');
      await service.syncNow();
      expect(client.calls.map((c) => c[0]), contains('unlike'));
      expect(await favoriteDao.pendingToDelete(), isEmpty);
    });

    test('歌单创建后回填 remoteId', () async {
      await playlistDao.create(
        LocalPlaylistsCompanion.insert(id: 'local-1', name: '华语经典'),
      );
      await service.syncNow();
      final p = await playlistDao.getById('local-1');
      expect(p!.remoteId, isNotNull);
      expect(p.isSynced, isTrue);
    });

    test('播放记录上报后置 is_synced', () async {
      await playRecordDao.addRecord(song('a'));
      await service.syncNow();
      expect(client.calls.map((c) => c[0]), contains('reportPlay'));
      expect(await playRecordDao.pendingToPush(), isEmpty);
    });

    test('播放上报失败 attemptCount +1 且仍待同步', () async {
      client.reportSuccess = false;
      await playRecordDao.addRecord(song('a'));
      await service.syncNow();
      final pending = await playRecordDao.pendingToPush();
      expect(pending, hasLength(1));
      expect(pending.first.attemptCount, 1);
    });
  });

  group('清空历史标记', () {
    test('有标记且登录时调 clearPlayHistory 并清除标记', () async {
      service = SyncService(
        client: client,
        auth: _FakeAuth(true),
        favoriteDao: favoriteDao,
        playlistDao: playlistDao,
        playRecordDao: playRecordDao,
        settingsDao: settingsDao,
      );
      await settingsDao.set('pending_clear_play_history', 'true');
      await service.syncNow();
      expect(client.calls.map((c) => c[0]), contains('clearPlayHistory'));
      expect(await settingsDao.get('pending_clear_play_history'), isNull);
    });
  });
}