import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/local_favorite_repository.dart';
import '../repositories/favorite_repository.dart';

part 'providers.g.dart';

// ── 单例 Provider ──

/// GD Music API 客户端
@riverpod
GdMusicClient gdMusicClient(GdMusicClientRef ref) => GdMusicClient();

/// 收藏仓库（当前为本地 Isar 实现）
/// 以后加后端时，把 LocalFavoriteRepository 换成 ApiFavoriteRepository 即可
@riverpod
FavoriteRepository favoriteRepository(FavoriteRepositoryRef ref) =>
    LocalFavoriteRepository();

/// 搜索服务
@riverpod
SearchService searchService(SearchServiceRef ref) =>
    SearchService(ref.watch(gdMusicClientProvider));
