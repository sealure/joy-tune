// 封面解析结果缓存数据访问对象（纯本地表：local_pic_covers）
// 按 (pic_id, source) 缓存"封面图 ID → 解析后的封面 URL"，
// 歌曲封面与歌单封面共用：解析结果落库后重启应用不再请求外部 API。

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'pic_cover_dao.g.dart';

/// 封面解析结果缓存 DAO
@DriftAccessor(tables: [LocalPicCovers])
class PicCoverDao extends DatabaseAccessor<AppDatabase> with _$PicCoverDaoMixin {
  PicCoverDao(super.attachedDatabase);

  /// 读取缓存的封面 URL，无则 null
  Future<String?> getCoverUrl(String picId, String source) async {
    final row = await (select(localPicCovers)
          ..where((t) => t.picId.equals(picId) & t.source.equals(source)))
        .getSingleOrNull();
    final url = row?.coverUrl;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// 回填/更新封面解析结果（按 (pic_id, source) upsert，仅非空覆盖）
  Future<void> upsert({
    required String picId,
    required String source,
    required String coverUrl,
  }) async {
    await into(localPicCovers).insertOnConflictUpdate(
      LocalPicCoversCompanion.insert(
        picId: picId,
        source: source,
        coverUrl: coverUrl,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 清空封面解析结果缓存
  Future<void> clearAll() async {
    await (delete(localPicCovers)).go();
  }
}