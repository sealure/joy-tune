import '../api/gdmusic_client.dart';
import '../models/song.dart';

/// 搜索服务
class SearchService {
  final GdMusicClient _client;

  SearchService(this._client);

  Future<List<Song>> search({
    required String keyword,
    String source = 'netease',
    bool albumSearch = false,
  }) async {
    if (keyword.trim().isEmpty) return [];
    return _client.search(keyword: keyword, source: source, albumSearch: albumSearch);
  }
}
