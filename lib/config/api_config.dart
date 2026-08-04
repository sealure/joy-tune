// API 配置
// 集中管理所有后端 API 地址，修改时只需改此一处

/// 后端 API 基础地址
///
/// 通过编译期参数注入正式环境地址，本地调试默认使用局域网 dev 地址：
///   - 本地开发（dev）：flutter run（不传参，走下方默认值）
///   - 正式发布（prod）：flutter build apk --release \
///       --dart-define=API_BASE_URL=https://va.1hub.ccwu.cc/api/v1
///
/// GitHub Actions 发布 workflow 已在构建时注入正式域名，见 .github/workflows/build-apk.yml
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.5:8080/api/v1',
);

/// 客户端版本号（设备上报用）
/// 与 pubspec.yaml 的 version 字段保持一致，升级版本时同步修改
const String appVersion = '0.0.1';
