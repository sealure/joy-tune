import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gdmusic_client.dart';
import '../db/app_database.dart';
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
  /// 当前搜索关键词（非空表示已执行搜索）
  final String keyword;

  const _SearchState({
    this.songs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.keyword = '',
  });

  _SearchState copyWith({
    List<Song>? songs,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? keyword,
  }) {
    return _SearchState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      keyword: keyword ?? this.keyword,
    );
  }
}

class _SearchNotifier extends StateNotifier<_SearchState> {
  final Ref _ref;

  _SearchNotifier(this._ref) : super(const _SearchState());

  /// 新搜索（重置分页，首次并发所有源）
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      state = const _SearchState();
      return;
    }
    // 保存搜索历史
    await AppDatabase.addSearchHistory(keyword.trim());
    state = state.copyWith(isLoading: true, songs: [], page: 0, hasMore: true, keyword: keyword.trim());
    await _fetchAllSourceResults();
  }

  /// 加载下一页（使用主源分页，避免超出 API 频率限制）
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.keyword.isEmpty) return;
    state = state.copyWith(isLoading: true);
    await _fetchPage(state.page + 1);
  }

  /// 首次搜索：并发搜索所有音源，汇总去重
  Future<void> _fetchAllSourceResults() async {
    try {
      final client = _ref.read(gdMusicClientProvider);
      // 并发搜索所有源
      final futures = GdMusicClient.sources.map((source) async {
        try {
          return await client.search(
            keyword: state.keyword,
            source: source,
            count: 20,
          );
        } catch (_) {
          return <Song>[];
        }
      });
      final results = await Future.wait(futures);
      // 汇总所有结果
      final allSongs = results.expand((list) => list).toList();
      // 去重（歌名+歌手相同视为同一首歌，保留第一个出现的）
      final seen = <String>{};
      final unique = <Song>[];
      for (final song in allSongs) {
        final key = '${song.name}_${song.artist}'.toLowerCase();
        if (seen.add(key)) unique.add(song);
      }
      if (!mounted) return;
      state = state.copyWith(
        songs: unique,
        isLoading: false,
        hasMore: false, // 多源搜索已获取全部结果，无需分页
        page: 1,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// 分页加载（单源，用于后续翻页）
  Future<void> _fetchPage(int page) async {
    try {
      final client = _ref.read(gdMusicClientProvider);
      final results = await client.search(
        keyword: state.keyword,
        source: 'joox',
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
    // widget 创建时恢复搜索框文字（provider 状态在 tab 切换时保留）
    final keyword = ref.read(_searchProvider).keyword;
    if (keyword.isNotEmpty) {
      // 同步设置 controller 文字，TextField 会自动显示
      _controller.text = keyword;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: keyword.length),
      );
    }
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

  /// 执行搜索
  void _doSearch(String keyword) {
    ref.read(_searchProvider.notifier).search(keyword);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(_searchProvider);
    // 是否显示搜索历史：搜索框为空且无搜索结果时显示
    final showHistory = _controller.text.isEmpty && searchState.songs.isEmpty;
    // 每次 build 时直接读取最新历史记录
    final history = AppDatabase.getSearchHistory();

    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          // 搜索栏（固定）
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
              onSubmitted: (v) => _doSearch(v),
              textInputAction: TextInputAction.search,
            ),
          ),

          // 搜索历史（固定，搜索框为空且无搜索结果时显示）
          if (showHistory && history.isNotEmpty)
            _buildHistorySection(history),

          // 结果列表（可滚动，填充剩余空间）
          Expanded(
            child: searchState.songs.isEmpty && !searchState.isLoading
                ? Center(
                    child: Text(
                      searchState.keyword.isEmpty ? '输入关键词开始搜索' : '未找到结果',
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

  /// 构建搜索历史区域
  Widget _buildHistorySection(List<String> history) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：历史搜索 + 清空按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('历史搜索', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () async {
                  await AppDatabase.clearSearchHistory();
                  setState(() {});
                },
                child: Text('清空', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 历史关键词标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((keyword) {
              return GestureDetector(
                onTap: () {
                  _controller.text = keyword;
                  _doSearch(keyword);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(keyword, style: theme.textTheme.bodySmall),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
