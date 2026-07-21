import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../widgets/song_tile.dart';
import '../utils/player_utils.dart';

/// 搜索结果分页状态
class _SearchState {
  final List<Song> songs;
  final bool isLoading;
  final bool hasMore;
  final int page;

  const _SearchState({
    this.songs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
  });

  _SearchState copyWith({
    List<Song>? songs,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return _SearchState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class _SearchNotifier extends StateNotifier<_SearchState> {
  final Ref _ref;
  String _keyword = '';

  _SearchNotifier(this._ref) : super(const _SearchState());

  /// 新搜索（重置分页）
  Future<void> search(String keyword) async {
    _keyword = keyword;
    if (keyword.trim().isEmpty) {
      state = const _SearchState();
      return;
    }
    state = state.copyWith(isLoading: true, songs: [], page: 0, hasMore: true);
    await _fetchPage(1);
  }

  /// 加载下一页
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _keyword.trim().isEmpty) return;
    state = state.copyWith(isLoading: true);
    await _fetchPage(state.page + 1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final client = _ref.read(gdMusicClientProvider);
      final results = await client.search(
        keyword: _keyword,
        source: 'netease',
        count: 20,
        page: page,
      );
      if (!mounted) return;
      state = state.copyWith(
        songs: [...state.songs, ...results],
        isLoading: false,
        hasMore: results.length >= 20,
        page: page,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }
}

final _searchProvider = StateNotifierProvider<_SearchNotifier, _SearchState>(
  (ref) => _SearchNotifier(ref),
);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(_searchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(_searchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '搜索歌曲、歌手、专辑',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref.read(_searchProvider.notifier).search('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() {}),
              onSubmitted: (v) => ref.read(_searchProvider.notifier).search(v),
              textInputAction: TextInputAction.search,
            ),
          ),

          // 结果列表
          Expanded(
            child: searchState.songs.isEmpty && !searchState.isLoading
                ? Center(
                    child: Text(
                      _controller.text.isEmpty ? '输入关键词开始搜索' : '未找到结果',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: searchState.songs.length + (searchState.isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      // 加载指示器
                      if (i == searchState.songs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return SongTile(
                        song: searchState.songs[i],
                        onTap: () => playSong(context, ref, searchState.songs[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
