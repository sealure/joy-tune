// 应用信息统一入口：缓存 package_info_plus 的当前版本，替代各处硬编码版本号
import 'package:package_info_plus/package_info_plus.dart';

/// 当前应用信息（设置页「版本」行、自动更新版本比较、设备上报共用）
///
/// 用普通类 + Riverpod provider 注册单例（而非 static instance），
/// 以便单元测试通过 [versionOverride] 注入固定版本号。
class AppInfo {
  AppInfo({this.versionOverride});

  /// 单测注入的版本号；非 null 时优先返回，跳过原生 PackageInfo
  final String? versionOverride;

  String? _version;

  /// 当前版本号（versionName，不含 buildNumber）；取不到回退 '0.0.1'
  Future<String> get version async {
    if (versionOverride != null) return versionOverride!;
    if (_version != null) return _version!;
    try {
      // PackageInfo.fromPlatform().version 返回 versionName，
      // 与 GitHub Release tag（去 v 前缀）语义一致，可直接比较
      _version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // PackageInfo 异常回退，不影响启动/上报
      _version = '0.0.1';
    }
    return _version!;
  }
}
