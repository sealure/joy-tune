import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/gdmusic_client.dart';
import '../db/app_database.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../widgets/song_tile.dart';
import '../widgets/playlist_picker_sheet.dart';
import '../utils/player_utils.dart';

/// 搜索结果分页状态
class _SearchState {
  final List<Song> songs;
  final bool isLoading;
  final bool hasMore;
  final int page;
  /// 当前搜索关键词（非空表示已执行搜索）
  final String keyword;
  /// 是否为专辑搜索（source 加 _album 后缀）
  final bool albumSearch;
  /// joox 页面是否已全部翻完（< 20 条表示到底）
  final bool jooxComplete;
  /// 其他音源是否已加载过
  final bool otherSourcesLoaded;

  const _SearchState({
    this.songs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.keyword = '',
    this.albumSearch = false,
    this.jooxComplete = false,
    this.otherSourcesLoaded = false,
  });

  _SearchState copyWith({
    List<Song>? songs,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? keyword,
    bool? albumSearch,
    bool? jooxComplete,
    bool? otherSourcesLoaded,
  }) {
    return _SearchState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      keyword: keyword ?? this.keyword,
      albumSearch: albumSearch ?? this.albumSearch,
      jooxComplete: jooxComplete ?? this.jooxComplete,
      otherSourcesLoaded: otherSourcesLoaded ?? this.otherSourcesLoaded,
    );
  }
}

class _SearchNotifier extends StateNotifier<_SearchState> {
  final Ref _ref;

  _SearchNotifier(this._ref) : super(const _SearchState());

  /// 新搜索（先搜 joox，joox 翻到底后才加载其他音源）
  Future<void> search(String keyword, {bool albumSearch = false}) async {
    if (keyword.trim().isEmpty) {
      state = const _SearchState();
      return;
    }
    // 保存搜索历史
    await AppDatabase.addSearchHistory(keyword.trim());
    state = state.copyWith(
      isLoading: true, songs: [], page: 0, hasMore: true,
      keyword: keyword.trim(), albumSearch: albumSearch,
      jooxComplete: false, otherSourcesLoaded: false,
    );
    await _fetchAllSourceResults();
  }

  /// 加载下一页（使用主源分页，避免超出 API 频率限制）
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.keyword.isEmpty) return;
    state = state.copyWith(isLoading: true);
    await _fetchPage(state.page + 1);
  }

  /// 首次搜索：先搜 joox，joox 没结果则立即加载其他音源
  Future<void> _fetchAllSourceResults() async {
    try {
      final client = _ref.read(gdMusicClientProvider);
      // 1. 先搜 joox（主源）
      final jooxResults = await client.search(
        keyword: state.keyword,
        source: 'joox',
        count: 99,
        albumSearch: state.albumSearch,
      );

      final jooxComplete = jooxResults.length < 99;
      List<Song> songs = jooxResults;
      bool otherSourcesLoaded = false;

      // 2. 如果 joox 没结果，立即加载其他音源
      if (jooxResults.isEmpty) {
        songs = await _fetchOtherSourcesSync();
        otherSourcesLoaded = true;
      }

      if (!mounted) return;
      state = state.copyWith(
        songs: songs,
        isLoading: false,
        // joox 还有更多页，或者还没加载其他音源 → 可以继续加载
        hasMore: !jooxComplete || !otherSourcesLoaded,
        page: 1,
        jooxComplete: jooxComplete,
        otherSourcesLoaded: otherSourcesLoaded,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// 分页加载：joox 没翻完就继续翻 joox，翻完则加载其他音源
  Future<void> _fetchPage(int page) async {
    try {
      final client = _ref.read(gdMusicClientProvider);

      if (!state.jooxComplete) {
        // ── 继续翻 joox 分页 ──
        final results = await client.search(
          keyword: state.keyword,
          source: 'joox',
          count: 99,
          page: page,
          albumSearch: state.albumSearch,
        );
        if (!mounted) return;

        final jooxComplete = results.length < 99;
        // 跳过已存在的歌曲
        final seen = <String>{
          for (final s in state.songs) '${s.name}_${s.artist}'.toLowerCase(),
        };
        final fresh = results
            .where((s) => !seen.contains('${s.name}_${s.artist}'.toLowerCase()))
            .toList();

        var songs = [...state.songs, ...fresh];
        var otherSourcesLoaded = state.otherSourcesLoaded;

        // joox 翻完了，接着加载其他音源
        if (jooxComplete && !otherSourcesLoaded) {
          final otherResults = await _fetchOtherSourcesSync();
          songs = [...songs, ...otherResults];
          otherSourcesLoaded = true;
        }

        if (!mounted) return;
        state = state.copyWith(
          songs: songs,
          isLoading: false,
          hasMore: !jooxComplete || !otherSourcesLoaded,
          page: page,
          jooxComplete: jooxComplete,
          otherSourcesLoaded: otherSourcesLoaded,
        );
      } else if (!state.otherSourcesLoaded) {
        // ── joox 已翻完，加载其他音源 ──
        final otherResults = await _fetchOtherSourcesSync();
        if (!mounted) return;
        state = state.copyWith(
          songs: [...state.songs, ...otherResults],
          isLoading: false,
          hasMore: false,
          otherSourcesLoaded: true,
        );
      } else {
        // ── 全部加载完 ──
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  /// 并发搜索非 joox 的所有音源，汇总去重并返回
  Future<List<Song>> _fetchOtherSourcesSync() async {
    final client = _ref.read(gdMusicClientProvider);
    final keyword = state.keyword.toLowerCase();
    final futures = GdMusicClient.sources
        .where((s) => s != 'joox')
        .map((source) async {
      try {
        final results = await client.search(
          keyword: state.keyword,
          source: source,
          count: 99,
          albumSearch: state.albumSearch,
        );
        // 非主源的结果做精确过滤
        return results.where((s) {
          return s.name.toLowerCase().contains(keyword) ||
              s.artist.toLowerCase().contains(keyword) ||
              s.album.toLowerCase().contains(keyword);
        }).toList();
      } catch (_) {
        return <Song>[];
      }
    });
    final allResults = await Future.wait(futures);
    // 汇总所有结果
    final allSongs = allResults.expand((list) => list).toList();
    // 去重（歌名+歌手相同视为同一首歌，保留第一个）
    final seen = <String>{};
    final unique = <Song>[];
    for (final song in allSongs) {
      final key = '${song.name}_${song.artist}'.toLowerCase();
      if (seen.add(key)) unique.add(song);
    }
    return unique;
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
  bool _albumSearch = false; // 默认普通搜索，勾选后变为专辑搜索

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
    ref.read(_searchProvider.notifier).search(keyword, albumSearch: _albumSearch);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(_searchProvider);
    // 从我的歌单详情"添加歌曲"进入时，extra 携带目标歌单 id
    final addToPlaylistId =
        (GoRouterState.of(context).extra as Map?)?['playlistId'] as int?;
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
          // 搜索类型切换：默认 / 专辑
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                _SearchTypeChip(
                  label: '默认',
                  selected: !_albumSearch,
                  onTap: () {
                    if (_albumSearch) {
                      setState(() => _albumSearch = false);
                      if (_controller.text.isNotEmpty) _doSearch(_controller.text);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _SearchTypeChip(
                  label: '专辑',
                  selected: _albumSearch,
                  onTap: () {
                    if (!_albumSearch) {
                      setState(() => _albumSearch = true);
                      if (_controller.text.isNotEmpty) _doSearch(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
          // 从详情页"添加歌曲"进入时提示选择歌曲
          if (addToPlaylistId != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '点击右侧 ＋ 将歌曲加入该歌单',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
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
                        // joox 已翻完且正在加载其他音源时显示提示文字
                        final isJooxDone = searchState.jooxComplete && !searchState.otherSourcesLoaded;
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            if (isJooxDone)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  '正在加载其他音源...',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        );
                      }
                      return SongTile(
                        song: searchState.songs[i],
                        onTap: () => playSong(context, ref, searchState.songs[i]),
                        trailing: _addToPlaylistButton(searchState.songs[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 搜索结果行"加入歌单"按钮
  /// 从详情页"添加歌曲"进入时（路由 extra 带 playlistId），直接加入该歌单；
  /// 否则弹出选择歌单弹层（可复用组件）
  Widget _addToPlaylistButton(Song song) {
    final extra = GoRouterState.of(context).extra as Map?;
    final playlistId = extra?['playlistId'] as int?;
    return IconButton(
      tooltip: playlistId == null ? '加入歌单' : '添加到当前歌单',
      icon: Icon(Icons.playlist_add_rounded, color: Theme.of(context).colorScheme.primary),
      onPressed: () async {
        if (playlistId != null) {
          // 解析封面 URL：搜索结果通常只有 pic_id，解析后才能展示封面
          var coverUrl = song.coverUrl;
          if ((coverUrl == null || coverUrl.isEmpty) && song.picId != null && song.picId!.isNotEmpty) {
            try {
              coverUrl = await ref
                  .read(gdMusicClientProvider)
                  .getCoverUrl(picId: song.picId!, source: song.source);
              debugPrint('[Search] 封面解析成功: $coverUrl');
            } catch (e) {
              debugPrint('[Search] 封面解析失败: $e');
            }
          }
          final ok = await ref.read(backendClientProvider).addSongToPlaylist(
                playlistId,
                songId: song.id,
                songName: song.name,
                artist: song.artist,
                album: song.album.isNotEmpty ? song.album : null,
                coverUrl: coverUrl,
                source: song.source,
              );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(ok ? '已加入歌单' : '加入失败，请重试')));
          if (ok) {
            ref.invalidate(myPlaylistDetailProvider(playlistId));
            ref.invalidate(myPlaylistsProvider);
          }
        } else {
          await showPlaylistPickerSheet(context, ref, song: song);
        }
      },
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

/// 搜索类型切换标签
class _SearchTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SearchTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
