// API 配置
// 集中管理所有后端 API 地址，修改时只需改此一处

/// 后端 API 基础地址
/// 开发阶段使用 Mac 局域网 IP，生产环境改为服务器域名
const String apiBaseUrl = 'http://192.168.1.5:8080/api/v1';

/// 客户端版本号（设备上报用）
/// 与 pubspec.yaml 的 version 字段保持一致，升级版本时同步修改
const String appVersion = '0.0.1';
