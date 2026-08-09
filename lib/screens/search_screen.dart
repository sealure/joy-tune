import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/gdmusic_client.dart';
import '../models/song.dart';
import '../services/providers.dart';
import '../utils/cover_resolver.dart';
import '../utils/player_utils.dart';
import '../widgets/song_tile.dart';
import '../widgets/playlist_picker_sheet.dart';

/// 单次请求每页条数（GD Music API 单页最大，翻页以此判断是否到底）
const _pageSize = 99;

/// 搜索结果分页状态
class _SearchState {
  /// 各音源搜索结果字典：source → 该音源已加载的所有页的结果
  final Map<String, List<Song>> sourceSongs;
  final bool isLoading;
  final bool hasMore;
  /// 已加载到的页码，0 表示尚未搜索
  final int page;
  /// 当前搜索关键词（非空表示已执行搜索）
  final String keyword;
  /// 是否为专辑搜索（source 加 _album 后缀）
  final bool albumSearch;

  const _SearchState({
    this.sourceSongs = const {},
    this.isLoading = false,
    this.hasMore = false,
    this.page = 0,
    this.keyword = '',
    this.albumSearch = false,
  });

  /// 按固定音源顺序展开的扁平结果列表（joox → tencent → netease → ...）
  /// 用于列表渲染，第 n 页加载后按相同顺序追加
  List<Song> get songs {
    final list = <Song>[];
    for (final source in GdMusicClient.sources) {
      list.addAll(sourceSongs[source] ?? const []);
    }
    return list;
  }

  _SearchState copyWith({
    Map<String, List<Song>>? sourceSongs,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? keyword,
    bool? albumSearch,
  }) {
    return _SearchState(
      sourceSongs: sourceSongs ?? this.sourceSongs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      keyword: keyword ?? this.keyword,
      albumSearch: albumSearch ?? this.albumSearch,
    );
  }
}

class _SearchNotifier extends StateNotifier<_SearchState> {
  final Ref _ref;

  _SearchNotifier(this._ref) : super(const _SearchState());

  /// 新搜索：多源并发搜索第 1 页，结果按音源分组存入字典
  Future<void> search(String keyword, {bool albumSearch = false}) async {
    if (keyword.trim().isEmpty) {
      state = const _SearchState();
      return;
    }
    // 保存搜索历史（本地 SQLite，纯本地）
    await _ref.read(searchHistoryDaoProvider).addKeyword(keyword.trim());
    state = state.copyWith(
      isLoading: true,
      sourceSongs: const {},
      page: 0,
      hasMore: false,
      keyword: keyword.trim(),
      albumSearch: albumSearch,
    );
    await _fetchPage(1);
  }

  /// 加载下一页：所有音源并发搜索同一页码，结果按音源追加到字典
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.keyword.isEmpty) return;
    state = state.copyWith(isLoading: true);
    await _fetchPage(state.page + 1);
  }

  /// 并发搜索所有启用音源的第 [page] 页，按音源分组追加到字典
  /// - 每页每个音源一个搜索请求，返回结果存进字典（source → songs）
  /// - 展示时按 `GdMusicClient.sources` 固定顺序展开，第一页、第 n 页均如此
  /// - 查询源取 `client.enabledSources`（服务端 music_sources 配置启用集合；未配置则为内置兜底 4 源）
  /// - 同源跨页按「歌名+歌手」去重，避免重复行
  Future<void> _fetchPage(int page) async {
    final client = _ref.read(gdMusicClientProvider);
    final requestKeyword = state.keyword;
    final keyword = requestKeyword.toLowerCase();
    final futures = client.enabledSources.map((source) async {
      try {
        final raw = await client.search(
          keyword: requestKeyword,
          source: source,
          count: _pageSize,
          page: page,
          albumSearch: state.albumSearch,
        );
        // joox 作为主源不过滤；其余音源按关键词精确过滤，减少无关结果
        final refined = source == 'joox'
            ? raw
            : raw
                .where((s) =>
                    s.name.toLowerCase().contains(keyword) ||
                    s.artist.toLowerCase().contains(keyword) ||
                    s.album.toLowerCase().contains(keyword))
                .toList();
        // 是否还有下一页用原始返回条数判断（过滤后可能被清空但源仍有后续页）
        return (source: source, songs: refined, fullPage: raw.length >= _pageSize);
      } catch (_) {
        // 单个音源失败不影响其他音源，返回空
        return (source: source, songs: <Song>[], fullPage: false);
      }
    });
    final entries = await Future.wait(futures);

    if (!mounted || state.keyword != requestKeyword) return;

    // 合并进字典：本页结果按音源追加，并判断是否还有下一页
    final next = Map<String, List<Song>>.from(state.sourceSongs);
    var anyFullPage = false; // 任意音源返回整页 → 该源可能还有下一页
    var addedAny = false;    // 本页是否有新增歌曲（防同一页被重复返回时无限加载）
    for (final entry in entries) {
      final source = entry.source;
      final results = entry.songs;
      final old = next[source] ?? const <Song>[];
      final seen = <String>{
        for (final s in old) '${s.name}_${s.artist}'.toLowerCase(),
      };
      final fresh = results
          .where((s) => seen.add('${s.name}_${s.artist}'.toLowerCase()))
          .toList();
      next[source] = [...old, ...fresh];
      if (fresh.isNotEmpty) addedAny = true;
      if (entry.fullPage) anyFullPage = true;
    }

    state = state.copyWith(
      sourceSongs: next,
      page: page,
      isLoading: false,
      hasMore: anyFullPage && addedAny,
    );
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
    // 从我的歌单详情"添加歌曲"进入时，extra 携带目标歌单本地 id
    final addToPlaylistId =
        (GoRouterState.of(context).extra as Map?)?['playlistId'] as String?;
    // 是否显示搜索历史：搜索框为空且无搜索结果时显示
    final showHistory = _controller.text.isEmpty && searchState.songs.isEmpty;
    // 搜索历史（本地 SQLite 流式）
    final history = ref.watch(searchHistoryProvider).valueOrNull ?? const <String>[];

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
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
  /// 从详情页"添加歌曲"进入时（路由 extra 带 playlistId 本地 UUID），直接加入该歌单；
  /// 否则弹出选择歌单弹层（可复用组件）
  Widget _addToPlaylistButton(Song song) {
    final extra = GoRouterState.of(context).extra as Map?;
    final playlistId = extra?['playlistId'] as String?;
    return IconButton(
      tooltip: playlistId == null ? '加入歌单' : '添加到当前歌单',
      icon: Icon(Icons.playlist_add_rounded, color: Theme.of(context).colorScheme.primary),
      onPressed: () async {
        if (playlistId != null) {
          // 本地写 is_synced=0，后台同步；封面 URL 解析后一并存储
          final coverUrl = await resolveCoverUrl(ref.read(gdMusicClientProvider), song);
          debugPrint('[Search] 加入歌单封面: $coverUrl');
          await ref.read(playlistRepositoryProvider).addSong(playlistId, song);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(content: Text('已加入歌单')));
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
                  await ref.read(searchHistoryDaoProvider).clearAll();
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
