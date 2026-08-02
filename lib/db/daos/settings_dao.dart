import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

/// 设置数据访问对象（纯本地表：local_settings，key-value）
@DriftAccessor(tables: [LocalSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  /// 读取配置值，不存在返回 null
  Future<String?> get(String key) async {
    final row = await (select(localSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// 写入配置值
  Future<void> set(String key, String value) async {
    await into(localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(key: key, value: value),
    );
  }

  /// 删除配置项
  Future<void> remove(String key) async {
    await (delete(localSettings)..where((t) => t.key.equals(key))).go();
  }
}
