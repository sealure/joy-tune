import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

const _favoritesKey = 'favorites';
const _userNicknameKey = 'user_nickname';
const _userUuidKey = 'user_uuid';

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
}
