// 自动更新数据模型：GitHub Release 信息 / 产物 / 更新内容 / 检查结果
import 'version_compare.dart';

/// 支持自动更新的产物平台标识（与产物命名里的平台段一致）
const String assetPlatformAndroid = 'android';
const String assetPlatformMacos = 'macos';
const String assetPlatformWindows = 'windows';

/// GitHub Release 最新版本信息
class ReleaseInfo {
  final String tagName; // 如 v0.0.2
  final String htmlUrl; // Release 页地址（桌面端手动下载跳转）
  final String body; // 更新内容原始文本
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.assets,
  });

  /// 去掉 v 前缀后的版本号（如 0.0.2）
  String get version => stripV(tagName);

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List? ?? [])
        .map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
        // 仅保留能解析出平台的产物（过滤旧命名等无关资产）
        .where((a) => a.platform.isNotEmpty)
        .toList();
    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: assets,
    );
  }
}

/// Release 中的下载资产（按平台+架构拆分的安装包）
class ReleaseAsset {
  /// 产物名，如 joy-tune_0.0.2_arm64-v8a.apk / joy-tune_0.0.11_macos_arm64.dmg
  final String name;

  final String browserDownloadUrl;
  final int size; // 字节

  /// 产物平台（android / macos / windows，见 assetPlatform* 常量）
  final String platform;

  /// 产物架构（Android 为 ABI 串如 arm64-v8a；桌面端为 arm64 / x64）
  final String arch;

  const ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.platform,
    required this.arch,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final info = parseAssetInfo(name);
    return ReleaseAsset(
      name: name,
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      platform: info?.$1 ?? '',
      arch: info?.$2 ?? '',
    );
  }
}

/// 从产物名解析 (平台, 架构)：
/// - Android: `joy-tune_<版本>_<abi>.apk`        → (android, abi)
/// - macOS:   `joy-tune_<版本>_macos_<arch>.dmg`  → (macos, arm64/x64)
/// - Windows: `joy-tune_<版本>_windows_<arch>.zip` → (windows, arm64/x64)
/// 旧命名 via_music_*.apk 等解析失败返回 null（安全过滤）
(String, String)? parseAssetInfo(String name) {
  // Android APK：无平台段，末段为 ABI
  final apk = RegExp(r'^joy-tune_[^_]+_(.+)\.apk$').firstMatch(name);
  if (apk != null) return (assetPlatformAndroid, apk.group(1)!);
  // macOS dmg：显式平台段
  final macos =
      RegExp(r'^joy-tune_[^_]+_macos_(arm64|x64)\.dmg$').firstMatch(name);
  if (macos != null) return (assetPlatformMacos, macos.group(1)!);
  // Windows zip：显式平台段
  final windows =
      RegExp(r'^joy-tune_[^_]+_windows_(arm64|x64)\.zip$').firstMatch(name);
  if (windows != null) return (assetPlatformWindows, windows.group(1)!);
  return null;
}

/// 从产物名解析 ABI（仅 Android APK 有效，桌面端产物返回 null）
String? parseAbiFromName(String name) {
  final info = parseAssetInfo(name);
  return info?.$1 == assetPlatformAndroid ? info?.$2 : null;
}

/// 更新内容条目类型（设计稿：新增=靛蓝 / 修复=红 / 优化=绿 / 其它=普通）
enum ChangelogType { feat, fix, opt, plain }

/// 更新内容条目（类型标签 + 文案）
class ChangelogItem {
  final ChangelogType type;
  final String text;

  const ChangelogItem({required this.type, required this.text});

  /// 按行解析 Release body：
  /// 行首 `[新增]`/`[修复]`/`[优化]`（可带 `-`/`•`/数字列表前缀）→ 打对应类型标签并剥离前缀；
  /// 其余非空行 → 普通文本。
  static List<ChangelogItem> parse(String body) {
    final items = <ChangelogItem>[];
    for (final raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      // 剥离常见的无序列表前缀：- / * / •
      final text = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
      ChangelogType type = ChangelogType.plain;
      String rest = text;
      for (final entry in const [
        ('[新增]', ChangelogType.feat),
        ('[修复]', ChangelogType.fix),
        ('[优化]', ChangelogType.opt),
      ]) {
        if (text.startsWith(entry.$1)) {
          type = entry.$2;
          rest = text.substring(entry.$1.length).trim();
          break;
        }
      }
      if (rest.isNotEmpty) {
        items.add(ChangelogItem(type: type, text: rest));
      }
    }
    return items;
  }
}

/// 从 release 列表 JSON 中选出版本号最高的正式 release（过滤 draft/prerelease）
///
/// 不依赖 GitHub `/releases/latest`（其按发布时间取 latest，并行发版可能指向旧版本号），
/// 按版本号语义选出最高者。列表为空或全部为草稿时返回 null。
ReleaseInfo? pickLatestRelease(List<dynamic> releases) {
  ReleaseInfo? best;
  for (final item in releases) {
    if (item is! Map<String, dynamic>) continue;
    if (item['draft'] == true || item['prerelease'] == true) continue;
    final info = ReleaseInfo.fromJson(item);
    if (info.tagName.isEmpty) continue;
    if (best == null || isNewer(info.version, best.version)) {
      best = info;
    }
  }
  return best;
}

/// 一次检查更新的结果
class UpdateCheckResult {
  /// 是否有新版本
  final bool hasUpdate;

  /// 有新版但无匹配 ABI 产物（桌面端 / 模拟器）
  final bool noAsset;

  /// 当前是否处于检查中（按钮 loading 态）
  final bool isChecking;

  final ReleaseInfo? release;

  /// 匹配当前 ABI 的资产（Android 且命中时非空）
  final ReleaseAsset? asset;

  final String? currentVersion;

  /// 网络失败等原因
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.noAsset = false,
    this.isChecking = false,
    this.release,
    this.asset,
    this.currentVersion,
    this.error,
  });

  /// 检查中状态
  factory UpdateCheckResult.checking() =>
      const UpdateCheckResult(hasUpdate: false, isChecking: true);

  /// 网络失败 / 无 release
  factory UpdateCheckResult.failure(String error, {String? currentVersion}) =>
      UpdateCheckResult(hasUpdate: false, currentVersion: currentVersion, error: error);

  /// 已是最新
  factory UpdateCheckResult.upToDate(String current) =>
      UpdateCheckResult(hasUpdate: false, currentVersion: current);

  /// 发现新版本且匹配到 ABI 产物（Android 可下载安装）
  factory UpdateCheckResult.available(
          ReleaseInfo release, ReleaseAsset asset, String current) =>
      UpdateCheckResult(
        hasUpdate: true,
        release: release,
        asset: asset,
        currentVersion: current,
      );

  /// 发现新版本但无匹配 ABI 产物（桌面端跳转 Release 页手动下载）
  factory UpdateCheckResult.noAsset(ReleaseInfo release, String current) =>
      UpdateCheckResult(
        hasUpdate: true,
        noAsset: true,
        release: release,
        currentVersion: current,
      );
}
