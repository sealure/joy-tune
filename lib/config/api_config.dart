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
  defaultValue: 'http://127.0.0.1:8080/api/v1',
);
