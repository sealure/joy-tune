import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

const _favoritesKey = 'favorites';
const _userNicknameKey = 'user_nickname';
const _userUuidKey = 'user_uuid';
const _searchHistoryKey = 'search_history';
const _playSessionKey = 'play_session'; // 播放会话（队列+进度+模式）
const _maxSearchHistory = 20;

/// 数据库工具（SharedPreferences 实现，零代码生成）
class AppDatabase {
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── 收藏操作 ──

  static Future<List<Song>> getFavorites() async {
    final json = _prefs.getString(_favoritesKey);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveFavorites(List<Song> songs) async {
    final json = jsonEncode(songs.map((s) => s.toJson()).toList());
    await _prefs.setString(_favoritesKey, json);
  }

  // ── 用户操作 ──

  static String? get userUuid => _prefs.getString(_userUuidKey);
  static String? get userNickname => _prefs.getString(_userNicknameKey);

  static Future<void> setUser(String uuid, String nickname) async {
    await _prefs.setString(_userUuidKey, uuid);
    await _prefs.setString(_userNicknameKey, nickname);
  }

  static Future<void> setNickname(String nickname) async {
    await _prefs.setString(_userNicknameKey, nickname);
  }

  // ── 搜索历史操作 ──

  /// 获取搜索历史列表
  static List<String> getSearchHistory() {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }

  /// 添加搜索关键词到历史记录（去重，最新的排在最前面）
  static Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final history = getSearchHistory();
    history.remove(keyword.trim());
    history.insert(0, keyword.trim());
    // 超过上限时截断
    if (history.length > _maxSearchHistory) {
      history.removeRange(_maxSearchHistory, history.length);
    }
    await _prefs.setStringList(_searchHistoryKey, history);
  }

  /// 清空搜索历史
  static Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }

  // ── 播放会话持久化 ──

  /// 保存播放会话（队列、当前索引、播放进度、播放模式）
  static Future<void> savePlaySession({
    required List<Song> queue,
    required int currentIndex,
    required int positionMs,
    required String playMode,
  }) async {
    final data = {
      'queue': queue.map((s) => s.toJson()).toList(),
      'index': currentIndex,
      'position': positionMs,
      'mode': playMode,
    };
    await _prefs.setString(_playSessionKey, jsonEncode(data));
  }

  /// 读取播放会话，返回 null 表示无保存的会话
  static Future<Map<String, dynamic>?> getPlaySession() async {
    final json = _prefs.getString(_playSessionKey);
    if (json == null || json.isEmpty) return null;
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      // 反序列化歌曲列表
      final queue = (data['queue'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
      return {
        'queue': queue,
        'index': data['index'] as int? ?? 0,
        'position': data['position'] as int? ?? 0,
        'mode': data['mode'] as String? ?? 'loop',
      };
    } catch (_) {
      return null;
    }
  }

  /// 清除播放会话
  static Future<void> clearPlaySession() async {
    await _prefs.remove(_playSessionKey);
  }
}
