import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'search_history_dao.g.dart';

/// 搜索历史上限
const _maxSearchHistory = 20;

/// 搜索历史数据访问对象（纯本地表：local_search_history）
@DriftAccessor(tables: [LocalSearchHistory])
class SearchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.attachedDatabase);

  /// 添加搜索关键词（去重置顶，超过上限截断最旧的）
  Future<void> addKeyword(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    // 若已存在则删除（保持唯一 + 置顶）
    await (delete(localSearchHistory)..where((t) => t.keyword.equals(kw))).go();
    await into(localSearchHistory).insert(LocalSearchHistoryCompanion.insert(keyword: kw));
    // 超出上限删除最旧一条
    final countExpr = countAll();
    final count = await (selectOnly(localSearchHistory)..addColumns([countExpr])).getSingle();
    final totalCount = count.read(countExpr) ?? 0;
    if (totalCount > _maxSearchHistory) {
      final toDelete = await (select(localSearchHistory)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(totalCount - _maxSearchHistory))
          .get();
      for (final row in toDelete) {
        await (delete(localSearchHistory)..where((t) => t.id.equals(row.id))).go();
      }
    }
  }

  /// 流式监听全部搜索历史（按时间倒序，时间相同时新插入（id 大）在前，保证置顶）
  Stream<List<LocalSearchHistoryData>> watchAll() {
    return (select(localSearchHistory)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// 一次性读取全部关键词（按时间倒序，新插入在前）
  Future<List<String>> getKeywords() async {
    final rows = await (select(localSearchHistory)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    return rows.map((r) => r.keyword).toList();
  }

  /// 清空搜索历史
  Future<void> clearAll() async {
    await (delete(localSearchHistory)).go();
  }
}
