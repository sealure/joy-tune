import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gdmusic_client.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../widgets/song_tile.dart';
import '../utils/player_utils.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _sourceProvider = StateProvider<String>((ref) => 'netease');
final _resultsProvider = StateProvider<List<Song>>((ref) => []);

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyword = ref.watch(_searchProvider);
    final source = ref.watch(_sourceProvider);
    final results = ref.watch(_resultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索歌曲、歌手、专辑',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => ref.read(_searchProvider.notifier).state = '',
                            )
                          : null,
                    ),
                    onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
                    onSubmitted: (v) => _search(ref, v, source),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                // 音源选择
                DropdownButton<String>(
                  value: source,
                  underline: const SizedBox(),
                  items: GdMusicClient.sources.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(_sourceProvider.notifier).state = v;
                      if (keyword.isNotEmpty) _search(ref, keyword, v);
                    }
                  },
                ),
              ],
            ),
          ),

          // 结果列表
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      keyword.isEmpty ? '输入关键词开始搜索' : '未找到结果',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (_, i) => SongTile(
                      song: results[i],
                      onTap: () => playSong(context, ref, results[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _search(WidgetRef ref, String keyword, String source) async {
    if (keyword.trim().isEmpty) return;
    final client = ref.read(gdMusicClientProvider);
    try {
      final results = await client.search(keyword: keyword, source: source);
      ref.read(_resultsProvider.notifier).state = results;
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
  }
}
