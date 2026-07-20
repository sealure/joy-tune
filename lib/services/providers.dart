import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gdmusic_client.dart';
import '../repositories/local_favorite_repository.dart';
import '../repositories/favorite_repository.dart';
import '../services/search_service.dart';
import '../services/favorite_service.dart';
import '../services/audio_service.dart';

// ── 单例 Provider ──

final gdMusicClientProvider = Provider<GdMusicClient>((ref) => GdMusicClient());

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) => LocalFavoriteRepository());

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(gdMusicClientProvider));
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(favoriteRepositoryProvider));
});

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
