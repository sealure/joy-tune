// GitHub 访问镜像列表与 URL 重写
// 客户端更新需要访问 GitHub：查询 Release（api.github.com）与下载 APK（github.com），
// 部分地区/网络环境直连失败，通过第三方网页代理（gh-proxy 系）做降级：
// 直连失败后自动切换到镜像，两个域名共用同一套候选生成。
//
// 安全约定：仅重写可代理的 GitHub 域名（github.com / api.github.com），
// 其它域名不经过镜像，避免把第三方资源泄露给代理站点。

/// 第三方 GitHub 访问代理镜像（按优先级排序，直连失败后依次尝试）
///
/// 代理站点能力边界不同（实测）：gh-proxy.com 同时代理文件与 API；
/// ghproxy.net 仅代理文件，对 api.github.com 返回 403，故 API 与下载使用
/// 各自独立的镜像列表，避免检查更新白白请求注定失败的源。
const List<String> downloadMirrors = [
  'https://gh-proxy.com',
  'https://ghproxy.net',
];

/// 检查更新（api.github.com）可用的代理镜像，直连失败后依次尝试
const List<String> apiMirrors = [
  'https://gh-proxy.com',
];

/// 可被镜像代理的 GitHub 域名前缀（gh-proxy 同时代理网页/下载与 API）
const List<String> _proxiableHosts = [
  'https://github.com/',
  'https://api.github.com/',
];

/// 是否为可代理的 GitHub 直链（github.com / api.github.com）
bool isProxiableUrl(String url) =>
    _proxiableHosts.any(url.startsWith);

/// 把可代理直链重写为走指定镜像；不可代理返回 null
String? rewriteToMirror(String url, String mirror) {
  if (!isProxiableUrl(url)) return null;
  // 去掉镜像尾部斜杠，避免出现双斜杠
  final base = mirror.endsWith('/')
      ? mirror.substring(0, mirror.length - 1)
      : mirror;
  return '$base/$url';
}

/// 候选列表：直连原 URL 在前，指定镜像依次在后
///
/// [mirrors] 默认取下载镜像 [downloadMirrors]；API 检查请显式传 [apiMirrors]。
List<String> candidatesFor(
  String url, {
  List<String> mirrors = downloadMirrors,
}) {
  final list = <String>[url];
  for (final mirror in mirrors) {
    final rewritten = rewriteToMirror(url, mirror);
    if (rewritten != null) list.add(rewritten);
  }
  return list;
}
