// GitHub Release API 客户端
// 查询最新 release 与下载 APK 产物；参考 backend_client.dart 的 dio 用法：
// DioException 捕获 + debugPrint + 失败静默返回。
// 直连失败时统一走网页镜像降级（见 download_mirrors.dart），
// 检查更新与下载共用 _tryCandidates 降级执行器，避免重复逻辑。

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'download_mirrors.dart';
import 'update_models.dart';

/// GitHub Release API 客户端
class GitHubReleaseClient {
  // 项目仓库（sealure/joy-tune），发布 workflow 打 v* tag 并上传按 ABI 拆分的 APK
  static const _repo = 'sealure/joy-tune';

  final Dio _dio;

  GitHubReleaseClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // 所有请求都携带完整 URL（直连或镜像），因此不再配置 baseUrl
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/vnd.github+json',
                // GitHub API 要求必须携带 User-Agent
                'User-Agent': 'joy-tune',
              },
            ));

  /// 依次尝试候选 URL，直到某个请求成功；全部失败返回 null
  ///
  /// 降级语义：
  /// - `fetch` 抛出 `DioException`（网络/代理不可用）→ 落到下一候选源；
  /// - 用户主动取消（`CancelToken`）→ 立即终止，不再降级；
  /// - `fetch` 正常返回（含业务空结果 null）→ 视为成功，结束降级。
  Future<T?> _tryCandidates<T>(
    List<String> candidates,
    Future<T?> Function(String url) fetch, {
    CancelToken? cancelToken,
  }) async {
    for (final base in candidates) {
      try {
        return await fetch(base);
      } on DioException catch (e) {
        if (cancelToken?.isCancelled ?? false) {
          debugPrint('[Update] 已取消 GitHub 访问');
          return null;
        }
        debugPrint('[Update] GitHub 源失败（$base）: ${e.message}');
      }
    }
    debugPrint('[Update] 所有 GitHub 源均失败: ${candidates.first}');
    return null;
  }

  /// 查询版本号最高的正式 release；无 release 或网络失败返回 null
  ///
  /// 不用 `/releases/latest`（其按发布时间取 latest，并行发版时可能指向旧版本号），
  /// 改为拉取 release 列表后按版本号语义选出最高者（过滤 draft/prerelease）。
  /// API 直连失败时走 apiMirrors 降级（部分镜像仅代理文件、不代理 API）。
  Future<ReleaseInfo?> fetchLatestRelease() async {
    final candidates = candidatesFor(
      'https://api.github.com/repos/$_repo/releases?per_page=30',
      mirrors: apiMirrors,
    );
    return _tryCandidates(candidates, (base) async {
      final resp = await _dio.get(base);
      final list = resp.data;
      if (list is! List) return null;
      // 过滤草稿/预发布，按版本号取最高（不依赖 /releases/latest 的发布时间语义）
      return pickLatestRelease(list);
    });
  }

  /// 下载文件到 savePath，成功返回路径、失败返回 null（返回路径供幂等判断）
  ///
  /// 降级链：直连 github.com 失败后，自动依次切换到网页代理镜像
  /// （见 download_mirrors.dart 的 candidatesFor）；用户主动取消立即停止。
  Future<String?> downloadAsset(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return _tryCandidates(
      candidatesFor(url),
      (base) async {
        await _dio.download(
          base,
          savePath,
          onReceiveProgress: onProgress,
          cancelToken: cancelToken,
        );
        return savePath;
      },
      cancelToken: cancelToken,
    );
  }
}