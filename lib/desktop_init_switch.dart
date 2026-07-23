// 条件导入：桌面端使用真实实现，其他平台使用 stub
export 'desktop_init_stub.dart'
    if (dart.library.io) 'desktop_init.dart';
