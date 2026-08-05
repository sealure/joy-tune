// GitHub Release API 客户端
// 查询最新 release 与下载 APK 产物；参考 backend_client.dart 的 dio 用法：
// DioException 捕获 + debugPrint + 失败静默返回

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'update_models.dart';

/// GitHub Release API 客户端
class GitHubReleaseClient {
  // 项目仓库（sealure/joy-tune），发布 workflow 打 v* tag 并上传按 ABI 拆分的 APK
  static const _repo = 'sealure/joy-tune';

  final Dio _dio;

  GitHubReleaseClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.github.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/vnd.github+json',
                // GitHub API 要求必须携带 User-Agent
                'User-Agent': 'joy-tune',
              },
            ));

  /// 查询版本号最高的正式 release；无 release 或网络失败返回 null
  ///
  /// 不用 `/releases/latest`（其按发布时间取 latest，并行发版时可能指向旧版本号），
  /// 改为拉取 release 列表后按版本号语义选出最高者（过滤 draft/prerelease）。
  Future<ReleaseInfo?> fetchLatestRelease() async {
    try {
      final resp = await _dio.get('/repos/$_repo/releases', queryParameters: {
        'per_page': 30,
      });
      final list = resp.data;
      if (list is! List) return null;
      // 过滤草稿/预发布，按版本号取最高（不依赖 /releases/latest 的发布时间语义）
      return pickLatestRelease(list);
    } on DioException catch (e) {
      // 404 = 仓库尚无 release（当前状态）；其它网络错误同样静默降级
      debugPrint('[Update] 查询最新版本失败: ${e.message}, status=${e.response?.statusCode}');
      return null;
    }
  }

  /// 下载文件到 savePath，成功返回路径、失败返回 null（返回路径供幂等判断）
  Future<String?> downloadAsset(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      return savePath;
    } on DioException catch (e) {
      // 下载失败静默返回 null（用户可重试；DioExceptionType.cancel 是主动取消）
      debugPrint('[Update] 下载 APK 失败: ${e.message}');
      return null;
    }
  }
}
