// Windows 专用 Google OAuth 登录
// google_sign_in 插件无 Windows 实现，Windows 上通过「浏览器 OAuth + PKCE(loopback 重定向)」
// 拿 Google id_token/access_token，再交给 firebase_auth.signInWithCredential 复用。

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google OAuth 回调端口（固定值，需在 Google Cloud 该 Web client 的 redirect 白名单配置）
const int kGoogleOAuthPort = 9092;

/// firebase 项目《via-music-d4c27》的 Web OAuth client_id
/// 从 Google Cloud Console → 凭据 → OAuth 2.0 客户端 ID 页面【顶部】复制，格式 xxx.apps.googleusercontent.com
const String googleWebClientId = '705656192509-vs0nj9dqtc11k8acnjl7s81h9tmcp54b.apps.googleusercontent.com';

/// Google OAuth 成功返回的凭据
class GoogleOAuthResult {
  final String idToken;
  final String accessToken;

  const GoogleOAuthResult({required this.idToken, required this.accessToken});
}

/// Windows 浏览器 OAuth 登录（loopback 重定向 + PKCE）
class GoogleOAuthWindows {
  final Dio _dio;

  GoogleOAuthWindows({Dio? dio}) : _dio = dio ?? Dio();

  /// 发起浏览器 OAuth，用户授权后返回 Google 凭据；取消/失败返回 null
  Future<GoogleOAuthResult?> signIn() async {
    // 1. PKCE：生成 verifier 与 S256 challenge
    final verifier = _randomBase64Url(64);
    final challenge =
        _base64UrlNoPad(sha256.convert(utf8.encode(verifier)).bytes);

    // 2. 先启动本地 loopback 回调服务（浏览器授权后回调到这里）
    final codeFuture = _listenForCode();

    // 3. 打开默认浏览器到 Google 授权页
    final redirectUri = 'http://localhost:$kGoogleOAuthPort';
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': googleWebClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    debugPrint('[GoogleOAuth] 打开浏览器授权: $authUrl');
    final opened =
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('[GoogleOAuth] 打开浏览器失败');
      return null;
    }

    // 4. 等待授权回调返回 authorization code
    final code = await codeFuture;
    if (code == null) {
      debugPrint('[GoogleOAuth] 用户取消或回调失败');
      return null;
    }

    // 5. 用 code + verifier 换 id_token / access_token
    return _exchangeCode(code, verifier, redirectUri);
  }

  /// 监听 loopback 回调，解析 authorization code；用户取消或失败返回 null
  Future<String?> _listenForCode() async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, kGoogleOAuthPort);
    } catch (e) {
      debugPrint('[GoogleOAuth] 端口 $kGoogleOAuthPort 被占用: $e');
      return null;
    }
    final completer = Completer<String?>();
    server.listen((request) {
      final query = request.uri.queryParameters;
      final code = query['code'];
      final error = query['error'];
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('<html><body><h3>'
            '${error != null ? '授权失败: $error' : '授权成功，可关闭此窗口'}'
            '</h3></body></html>');
      request.response.close();
      if (!completer.isCompleted) {
        completer.complete(error != null ? null : code);
      }
      server?.close(force: true);
    });
    return completer.future;
  }

  /// 用 authorization code + PKCE verifier 换取 token
  Future<GoogleOAuthResult?> _exchangeCode(
      String code, String verifier, String redirectUri) async {
    try {
      final resp = await _dio.post(
        'https://oauth2.googleapis.com/token',
        data: {
          'code': code,
          'client_id': googleWebClientId,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
          'code_verifier': verifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = resp.data as Map<String, dynamic>;
      final idToken = data['id_token'] as String?;
      final accessToken = data['access_token'] as String?;
      if (idToken == null) {
        debugPrint('[GoogleOAuth] token 响应缺少 id_token');
        return null;
      }
      return GoogleOAuthResult(idToken: idToken, accessToken: accessToken ?? '');
    } catch (e) {
      debugPrint('[GoogleOAuth] 换取 token 失败: $e');
      return null;
    }
  }

  /// 生成 base64url（去 padding）随机字符串，用于 PKCE verifier
  String _randomBase64Url(int byteLength) {
    final rand = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rand.nextInt(256));
    return _base64UrlNoPad(bytes);
  }

  String _base64UrlNoPad(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
