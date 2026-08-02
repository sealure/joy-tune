import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../db/daos/favorite_dao.dart';
import '../../db/daos/search_history_dao.dart';
import '../../db/daos/session_dao.dart';
import '../../db/daos/settings_dao.dart';
import '../../db/legacy_prefs.dart';
import '../../models/song.dart';

/// 旧 SharedPreferences 数据 → SQLite 迁移器
///
/// 启动时读取一次旧存储（收藏/搜索历史/播放会话），写入 SQLite 后置
/// `prefs_migrated=true` 标记，幂等（已迁移则跳过）。收藏迁移后 is_synced=0，
/// 待 SyncService 登录后同步到服务端。
class LegacyPrefsMigrator {
  final FavoriteDao _favoriteDao;
  final SearchHistoryDao _searchHistoryDao;
  final SessionDao _sessionDao;
  final SettingsDao _settingsDao;

  LegacyPrefsMigrator({
    required FavoriteDao favoriteDao,
    required SearchHistoryDao searchHistoryDao,
    required SessionDao sessionDao,
    required SettingsDao settingsDao,
  })  : _favoriteDao = favoriteDao,
        _searchHistoryDao = searchHistoryDao,
        _sessionDao = sessionDao,
        _settingsDao = settingsDao;

  /// 是否已迁移
  Future<bool> get migrated async =>
      await _settingsDao.get(_migratedKey) == 'true';

  /// 执行迁移（需先调用 LegacyPrefs.initialize()）
  Future<void> run() async {
    if (await migrated) return;
    debugPrint('[LegacyPrefsMigrator] 开始迁移旧数据');

    // 收藏：写入 SQLite（is_synced=0，待登录后同步）
    final favorites = await LegacyPrefs.getFavorites();
    for (final song in favorites) {
      await _favoriteDao.insertFavorite(song);
    }

    // 搜索历史
    final history = LegacyPrefs.getSearchHistory();
    for (final keyword in history) {
      await _searchHistoryDao.addKeyword(keyword);
    }

    // 播放会话（沿用现有 JSON 队列模型）
    final session = await LegacyPrefs.getPlaySession();
    if (session != null) {
      final queue = session['queue'] as List<Song>? ?? const <Song>[];
      await _sessionDao.saveSession(
        queueJson: jsonEncode(queue.map((s) => s.toJson()).toList()),
        currentIndex: session['index'] as int? ?? 0,
        positionMs: session['position'] as int? ?? 0,
        playMode: session['mode'] as String? ?? 'loop',
      );
    }

    await _settingsDao.set(_migratedKey, 'true');
    debugPrint('[LegacyPrefsMigrator] 迁移完成: 收藏 ${favorites.length}，历史 ${history.length}');
  }

  static const _migratedKey = 'prefs_migrated';
}
