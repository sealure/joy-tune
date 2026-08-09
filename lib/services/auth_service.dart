// 认证服务
// 封装与后端 API 的交互：Google 登录、Token 管理、用户信息获取

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

/// 认证服务
class AuthService {
  static const _tokenKey = 'auth_jwt_token';
  // 后端地址从 api_config.dart 中获取
  static const _baseUrl = apiBaseUrl;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// 认证失效（401）回调：由调用方注入，用于清空本地账号数据并置登录态为未登录
  Future<void> Function()? onAuthExpired;

  AuthService({Dio? dio, FlutterSecureStorage? storage, this.onAuthExpired})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)),
        _storage = storage ?? const FlutterSecureStorage();

  // ── Token 管理 ──

  /// 获取已存储的 JWT Token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// 保存 JWT Token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// 删除 JWT Token（退出登录）
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// 是否已登录
  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 获取带认证头的 Dio 实例
  Future<Dio> get authedDio async {
    final token = await getToken();
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));
    return dio;
  }

  // ── 认证 API ──

  /// Google OAuth 登录
  /// [idToken] 从 Google Sign-In 获取的 id_token
  /// 返回登录结果：token、用户信息、是否新用户
  Future<LoginResult> googleLogin(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        // 后端 proto 字段为 id_token（gRPC-gateway 使用 snake_case），不要用 camelCase
        data: {'id_token': idToken},
      );

      final data = response.data;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final isNewUser = data['isNewUser'] as bool? ?? false;

      // 存储 Token
      await _saveToken(token);

      // 登录成功后获取用户完整信息（包含 authProvider）
      User finalUser;
      try {
        finalUser = await getProfile();
      } catch (_) {
        // 获取 Profile 失败时使用登录返回的基础信息
        finalUser = user;
      }

      return LoginResult(
        token: token,
        user: finalUser,
        isNewUser: isNewUser,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? '登录失败';
      throw Exception(message);
    }
  }

  /// 刷新 Token
  Future<void> refreshToken() async {
    final oldToken = await getToken();
    if (oldToken == null) throw Exception('无有效的 Token');

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'token': oldToken},
      );
      final newToken = response.data['token'] as String;
      await _saveToken(newToken);
    } on DioException catch (e) {
      // Token 刷新失败，清除本地 Token
      await clearToken();
      final message = e.response?.data?['message'] ?? 'Token 刷新失败';
      throw Exception(message);
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      final authedDio = await this.authedDio;
      await authedDio.post('/auth/logout');
    } catch (_) {
      // 即使后端调用失败，也要清除本地 Token
    }
    await clearToken();
  }

  // ── 用户 API ──

  /// 获取当前用户信息
  Future<User> getProfile() async {
    final authedDio = await this.authedDio;
    try {
      final response = await authedDio.get('/user/profile');
      debugPrint('>>> [AUTH] getProfile 成功: ${response.statusCode} ${response.data}');
      return User.fromJson(response.data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('>>> [AUTH] getProfile DioException: status=${e.response?.statusCode}, data=${e.response?.data}, message=${e.message}');
      if (e.response?.statusCode == 401) {
        // token 失效：清 token → 触发全局登出清理（清本地账号数据 + 置未登录态）→ 仍抛错供调用方降级
        await clearToken();
        await onAuthExpired?.call();
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取用户信息失败: ${e.response?.statusCode} ${e.response?.data}');
    }
  }

  /// 更新用户资料
  Future<User> updateProfile({String? nickname, String? avatarUrl}) async {
    final authedDio = await this.authedDio;
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    // 后端 proto 字段为 avatar_url（gRPC-gateway 使用 snake_case），不要用 camelCase
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    try {
      final response = await authedDio.put('/user/profile', data: data);
      return User.fromJson(response.data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('更新用户资料失败');
    }
  }
}

/// 登录结果
class LoginResult {
  final String token;
  final User user;
  final bool isNewUser;

  const LoginResult({
    required this.token,
    required this.user,
    required this.isNewUser,
  });
}
