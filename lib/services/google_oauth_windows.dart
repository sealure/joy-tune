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

/// Google OAuth 回调端口（固定值；Desktop app 类型客户端走 loopback，无需在
/// Google Cloud 注册该端口，只要指向 localhost 即可）
const int kGoogleOAuthPort = 9092;

/// Windows 专用 Google OAuth 登录
/// google_sign_in 插件无 Windows 实现，Windows 上通过「浏览器 OAuth + PKCE(loopback 重定向)」
/// 拿 Google id_token/access_token，再交给 firebase_auth.signInWithCredential 复用。
///
/// OAuth 凭据优先级（公开仓库不存明文，本地开发也无需每次敲 --dart-define）：
///   1. --dart-define=GOOGLE_OAUTH_CLIENT_ID / GOOGLE_OAUTH_CLIENT_SECRET
///      （CI 由 GitHub Actions Secret 注入，见 build-windows.yml）
///   2. 项目根目录 .oauth_local.json（已 .gitignore，不入库；打包版可放在 exe 同目录）
///      格式: `{"clientId": "<client_id>", "clientSecret": "<client_secret>"}`
/// 原因：Google 的 Desktop/Web 类型 client 换 token 时需要 client_secret
/// （否则 HTTP 400 client_secret is missing）；iOS/Android 不受影响。
const String _googleClientIdFromEnv =
    String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
const String _googleClientSecretFromEnv =
    String.fromEnvironment('GOOGLE_OAUTH_CLIENT_SECRET');

const String _kLocalOAuthFile = '.oauth_local.json';
String? _localOAuthJson;

/// Google OAuth 客户端 ID：--dart-define 优先，否则读本地 .oauth_local.json。
String get googleDesktopClientId => _googleClientIdFromEnv.isNotEmpty
    ? _googleClientIdFromEnv
    : _localCred('clientId');

/// Google OAuth 客户端密钥：--dart-define 优先，否则读本地 .oauth_local.json。
String get googleDesktopClientSecret => _googleClientSecretFromEnv.isNotEmpty
    ? _googleClientSecretFromEnv
    : _localCred('clientSecret');

String _localCred(String key) {
  try {
    _localOAuthJson ??= _readLocalOAuthJson();
    if (_localOAuthJson == null || _localOAuthJson!.isEmpty) return '';
    final map = jsonDecode(_localOAuthJson!) as Map<String, dynamic>;
    final value = map[key] as String? ?? '';
    if (value.isNotEmpty) {
      debugPrint('[GoogleOAuth] 已从 .oauth_local.json 读取 $key');
    }
    return value;
  } catch (e) {
    debugPrint('[GoogleOAuth] 读取本地凭据 .oauth_local.json 失败: $e');
    return '';
  }
}

String? _readLocalOAuthJson() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final candidates = <String>[
    // flutter run -d windows：当前工作目录即项目根
    _kLocalOAuthFile,
    // 打包发布的 exe：凭据文件放在 exe 同目录
    '$exeDir${Platform.pathSeparator}$_kLocalOAuthFile',
  ];
  for (final path in candidates) {
    try {
      final f = File(path);
      if (f.existsSync()) return f.readAsStringSync();
    } catch (e) {
      debugPrint('[GoogleOAuth] 检查本地凭据 $path 失败: $e');
    }
  }
  return null;
}

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
    // ????????:??????????,??? client_id ?? Google
    if (googleDesktopClientId.isEmpty || googleDesktopClientSecret.isEmpty) {
      debugPrint('[GoogleOAuth] ??? GOOGLE_OAUTH_CLIENT_ID / '
          'GOOGLE_OAUTH_CLIENT_SECRET,??? --dart-define ?????');
      return null;
    }

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': googleDesktopClientId,
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
  ///
  /// 同时监听 IPv4 与 IPv6 loopback：Windows 上浏览器访问 localhost 可能
  /// 解析为 ::1(IPv6),若只监听 127.0.0.1 会连不上 → 回调页白屏且收不到 code
  Future<String?> _listenForCode() async {
    final completer = Completer<String?>();
    final servers = <HttpServer>[];

    for (final addr in [
      InternetAddress.loopbackIPv4,
      InternetAddress.loopbackIPv6,
    ]) {
      try {
        final server = await HttpServer.bind(
          addr,
          kGoogleOAuthPort,
          // IPv6 独立绑定,避免 v6Only=false 与 IPv4 冲突
          v6Only: addr.type == InternetAddressType.IPv6,
        );
        server.listen((request) {
          final query = request.uri.queryParameters;
          final code = query['code'];
          final error = query['error'];
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(
                '<html><body style="font-family:system-ui;text-align:center">'
                '<h3>${error != null ? "授权失败: $error" : "授权成功，可关闭此窗口，返回应用"}</h3>'
                '</body></html>');
          request.response.close();
          if (!completer.isCompleted) {
            completer.complete(error != null ? null : code);
          }
          // 单个回调成功后关掉所有监听(IPv4+IPv6)
          for (final s in servers) {
            s.close(force: true);
          }
        });
        servers.add(server);
      } catch (e) {
        debugPrint('[GoogleOAuth] 监听 $addr:$kGoogleOAuthPort 失败: $e');
      }
    }
    if (servers.isEmpty) return null;
    return completer.future;
  }

  /// 用 authorization code + PKCE verifier 换取 token
  Future<GoogleOAuthResult?> _exchangeCode(
      String code, String verifier, String redirectUri) async {
    try {
      final data = <String, dynamic>{
        'code': code,
        'client_id': googleDesktopClientId,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      };
      // Desktop/Web 客户端换 token 需要 client_secret；公开客户端(Android/iOS)
      // 不需要。为空时不发送，避免干扰。
      if (googleDesktopClientSecret.isNotEmpty) {
        data['client_secret'] = googleDesktopClientSecret;
      }
      final resp = await _dio.post(
        'https://oauth2.googleapis.com/token',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final respData = resp.data as Map<String, dynamic>;
      final idToken = respData['id_token'] as String?;
      final accessToken = respData['access_token'] as String?;
      if (idToken == null) {
        debugPrint('[GoogleOAuth] token 响应缺少 id_token: $respData');
        return null;
      }
      return GoogleOAuthResult(
          idToken: idToken, accessToken: accessToken ?? '');
    } on DioException catch (e) {
      final response = e.response;
      if (response != null) {
        debugPrint(
            '[GoogleOAuth] 换取 token 失败: HTTP ${response.statusCode}, 响应: ${response.data}');
      } else {
        debugPrint('[GoogleOAuth] 换取 token 失败(网络): ${e.message}');
      }
      return null;
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
