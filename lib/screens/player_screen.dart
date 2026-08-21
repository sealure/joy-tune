import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../services/providers.dart';
import '../theme/player_colors.dart';
import '../utils/download_path.dart';
import '../utils/lyric_utils.dart';
import '../widgets/cover_image.dart';
import '../widgets/player_seek_bar.dart';
import '../widgets/favorite_button.dart';
import '../widgets/playlist_picker_sheet.dart';
import 'playlist_queue_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  PlayState _playState = PlayState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  String? _coverUrl;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  bool _showLyrics = false;
  final ScrollController _lyricScrollCtrl = ScrollController();

  bool _isRestoringSession = false; // 是否正在恢复播放会话

  late AnimationController _rotationCtrl;
  late AnimationController _favCtrl;

  StreamSubscription<PlayState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<Song>? _nextSub;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _favCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _nextSub?.cancel();
    _lyricScrollCtrl.dispose();
    _rotationCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  void _initPlayer() {
    if (!mounted) return;
    final audio = ref.read(audioServiceProvider);
    _initSubscriptions();

    final routeSong = GoRouterState.of(context).extra as Song?;
    print('[Player] _initPlayer: routeSong=${routeSong?.name}, '
        'currentSongId=${audio.currentSongId}, queueLen=${audio.queue.length}');

    // 清除 stop() 设置的标志，允许 stream 事件正常触发
    audio.clearStopped();

    // 设置 nextSongStream 监听器
    // 播放已由 AudioService._applyAndPlay 内部直接完成（不依赖本页面），
    // 这里只同步展示（封面/歌词/收藏），避免重复调用 playSong。核心见 _syncUi。
    _nextSub?.cancel();
    _nextSub = audio.nextSongStream.listen((song) {
      _syncUi(song);
    });

    // 判断当前是否真正加载了可播放媒体（duration>0 表示已 open 媒体）。
    // 重启应用后 restoreSession 仅恢复队列/歌曲元数据，player 并未加载媒体（duration=0），
    // 此时进入播放页必须走 _onQueueAdvance 真正解析播放，不能误判为「已在播放」
    final hasMedia = (audio.duration?.inMilliseconds ?? 0) > 0;
    print('[Player] _initPlayer: hasMedia=$hasMedia');

    // 情况1：有恢复的会话且当前歌曲匹配，且确实已加载媒体 → 只加载元数据（不播放）
    if (audio.currentSongId != null && routeSong != null &&
        audio.currentSongId == routeSong.id && hasMedia) {
      print('[Player] 跳过: 已在播放');
      _loadSongMetadata(routeSong);
      _checkFavorite(routeSong);
      return;
    }

    // 情况2：有恢复的会话且已加载媒体，但用户打开了不同歌曲，使用当前会话的歌曲
    if (audio.currentSong != null && audio.queue.isNotEmpty &&
        routeSong == null && hasMedia) {
      final song = audio.currentSong!;
      print('[Player] 使用恢复的歌曲: ${song.name}');
      _loadSongMetadata(song);
      _checkFavorite(song);
      return;
    }

    // 情况3：无恢复会话或打开了新歌曲，开始播放
    final song = routeSong ?? audio.currentSong;
    if (song == null) return;
    // 如果有恢复的会话，标记需要恢复播放位置
    if (audio.queue.isNotEmpty && routeSong != null &&
        audio.currentSongId != routeSong.id) {
      _isRestoringSession = true;
    }
    print('[Player] 调用 _onQueueAdvance: ${song.name}');
    _onQueueAdvance(song);
  }

  void _initSubscriptions() {
    if (!mounted) return;
    final audio = ref.read(audioServiceProvider);
    _stateSub = audio.stateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playState = s);
      if (s == PlayState.playing) {
        _rotationCtrl.repeat();
      } else {
        _rotationCtrl.stop();
      }
    });
    _posSub = audio.positionStream.listen((p) {
      _position = p;
      _updateCurrentLyric(p);
      if (mounted) setState(() {});
    });
    _durSub = audio.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
    _playState = audio.state;
    if (audio.isPlaying) _rotationCtrl.repeat();
    _position = audio.position ?? Duration.zero;
    _duration = audio.duration ?? Duration.zero;
  }

  // ── 播放流程 ──

  /// 切歌时的 UI 同步：仅刷新当前播放歌曲的展示（封面/歌词/收藏），不重复发起播放。
  /// 播放已由 AudioService 在 _applyAndPlay 内完成（服务自身 playSong，不依赖本页面），
  /// 因此退出播放页进入 mini 播放器后，自动切下一首仍能正常续播（见 audio_service 修复）。
  Future<void> _syncUi(Song song) async {
    print('[Player] _syncUi(切歌仅刷新UI): ${song.name}');
    if (!mounted) return;
    await _loadSongMetadata(song);
    _checkFavorite(song);
  }

  Future<void> _onQueueAdvance(Song song) async {
    print('[Player] _onQueueAdvance: ${song.name}');
    final audio = ref.read(audioServiceProvider);

    // 先加载歌曲元数据（封面占位/清空歌词），真实解析结果在播放成功后更新
    _loadSongMetadata(song);
    _checkFavorite(song);
    if (!mounted) return;

    // 统一走 AudioService.playSong：查缓存→命中本地播放 / 未命中解析播放；失败自动切下一首
    final result = await audio.playSong(
      song,
      restorePosition: _isRestoringSession, // 会话恢复场景 seek 到上次位置
    );
    _isRestoringSession = false;
    if (!mounted) return;

    // 用解析/缓存到的封面与歌词更新展示，并回填歌词到本地 db（离线可看）
    if (result != null) {
      setState(() {
        if (result.coverUrl != null) _coverUrl = result.coverUrl;
        if (result.lyricsText != null) _lyrics = parseLrc(result.lyricsText!);
      });
      if (result.lyricsText != null) {
        unawaited(_backfillLyrics(result.playable, result.lyricsText!));
      }
    }
    print('[Player] 播放流程完成: ${song.name}');
  }

  void _onPlayToggle(Song song) {
    final audio = ref.read(audioServiceProvider);
    if (_playState == PlayState.playing) {
      audio.pause();
    } else if (_playState == PlayState.paused) {
      audio.resume();
    } else {
      _onQueueAdvance(song);
    }
  }

  // ── 收藏（本地 + 后端同步）──

  Future<void> _checkFavorite(Song song) async {
    // 收藏状态由 favorite_button 依据本地 SQLite 实时跟踪，无需在此维护字段
  }

  // ── 元数据加载 ──

  Future<void> _loadSongMetadata(Song song) async {
    setState(() {
      // 优先立即显示已带封面（如收藏/歌单的歌），缺失时 _loadCover 再异步解析
      _coverUrl = song.coverUrl;
      _lyrics = [];
      _currentLyricIndex = -1;
      _showLyrics = false;
    });
    await Future.wait([
      _loadCover(song),
      _loadLyrics(song),
    ]);
  }

  Future<void> _loadCover(Song song) async {
    // 统一封面解析：优先已带 coverUrl，否则按 picId，最后按歌名搜索兜底
    final resolver = ref.read(songResolverProvider);
    final url = await resolver.searchCoverUrl(song);
    if (mounted && url != null && url.isNotEmpty) {
      setState(() => _coverUrl = url);
    }
  }

  Future<void> _loadLyrics(Song song) async {
    // 歌词：优先读本地 sqlite 缓存（local_song_meta，播放过即回填）；未命中则解析并回填
    final songMetaDao = ref.read(songMetaDaoProvider);
    try {
      final cached = await songMetaDao.getLyrics(song.id, song.source);
      if (cached != null) {
        if (mounted) setState(() => _lyrics = parseLrc(cached));
        // 即使命中缓存，也确保 lyric_id 回填到本地播放/收藏/歌单（歌曲自带时），供同步服务端
        if (song.lyricId != null && song.lyricId!.isNotEmpty) {
          unawaited(_backfillLyricId(song.id, song.source, song.lyricId!));
        }
        return;
      }
    } catch (_) {
      // 缓存不可达时忽略，走解析
    }

    // 无缓存：优先 song.lyricId，缺失（历史数据）时按歌名搜索兜底；并拿回实际 lyric_id
    final resolver = ref.read(songResolverProvider);
    final info = await resolver.searchLyricsInfo(song);
    if (mounted && info != null && info.text.isNotEmpty) {
      setState(() => _lyrics = parseLrc(info.text));
      // 回填到本地歌曲元数据缓存（歌词 + 元数据 + lyric_id）
      final effectiveLyricId = info.lyricId ?? song.lyricId;
      try {
        await songMetaDao.upsert(
          songId: song.id,
          source: song.source,
          name: song.name,
          artist: song.artist,
          album: song.album,
          picId: song.picId,
          lyricId: effectiveLyricId,
          lyrics: info.text,
        );
      } catch (_) {}
      // lyric_id 回填到本地播放记录/收藏/歌单（为空才补），供同步服务端
      if (effectiveLyricId != null && effectiveLyricId.isNotEmpty) {
        unawaited(_backfillLyricId(song.id, song.source, effectiveLyricId));
      }
    }
  }

  /// 把 lyric_id 回填到本地播放记录 / 收藏 / 歌单歌曲对应行（为空才补，不覆盖），
  /// 并标记待同步，使下次 likeSong / addSongToPlaylist / reportPlay 能补传 lyric_id 到服务端
  Future<void> _backfillLyricId(String songId, String source, String lyricId) async {
    print('[Player] 回填 lyric_id: song=$songId source=$source lyric=$lyricId');
    try {
      await ref.read(playRecordDaoProvider).backfillLyricId(songId, source, lyricId);
      await ref.read(favoriteDaoProvider).backfillLyricId(songId, source, lyricId);
      await ref.read(playlistDaoProvider).backfillSongLyricId(songId, source, lyricId);
    } catch (_) {
      // 回填失败不影响播放
    }
  }

  /// 回填歌曲元数据到本地缓存（resolveDirectly 解析到歌词后调用；保留已有 lyric_id 防覆盖）
  Future<void> _backfillLyrics(Song song, String text) async {
    try {
      final dao = ref.read(songMetaDaoProvider);
      final existing = await dao.get(song.id, song.source);
      await dao.upsert(
        songId: song.id,
        source: song.source,
        name: song.name,
        artist: song.artist,
        album: song.album,
        picId: song.picId ?? existing?.picId,
        lyricId: song.lyricId ?? existing?.lyricId,
        lyrics: text,
      );
    } catch (_) {}
  }

  // ── 歌词同步 ──

  void _updateCurrentLyric(Duration position) {
    if (_lyrics.isEmpty) return;
    int idx = _lyrics.length - 1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time > position) {
        idx = i - 1;
        break;
      }
    }
    if (idx != _currentLyricIndex) {
      _currentLyricIndex = idx;
      _scrollToCurrentLyric();
    }
  }

  void _scrollToCurrentLyric() {
    if (_currentLyricIndex < 0 || _lyricScrollCtrl.hasClients == false) return;
    final offset = (_currentLyricIndex * 48.0) - 120;
    _lyricScrollCtrl.animateTo(
      offset.clamp(0.0, _lyricScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── 播放模式 ──

  void _cyclePlayMode() {
    final audio = ref.read(audioServiceProvider);
    final next = switch (audio.playMode) {
      PlayMode.loop => PlayMode.sequential,
      PlayMode.sequential => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.loop,
    };
    audio.playMode = next;
    setState(() {});
  }

  IconData _playModeIcon(PlayMode mode) => switch (mode) {
    PlayMode.loop => Icons.repeat_rounded,
    PlayMode.sequential => Icons.repeat_one_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
  };

  // ── UI 构建 ──

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioServiceProvider);
    final song = audio.currentSong ?? GoRouterState.of(context).extra as Song?;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('无播放内容')));
    }

    final isDesktop = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              SafeArea(
                child: isDesktop
                    ? Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                          ),
                          child: _buildPlayerColumn(song),
                        ),
                      )
                    : _buildPlayerColumn(song),
              ),
            ],
          ),
    );
  }

  Widget _buildPlayerColumn(Song song) {
    return Column(
      children: [
        _buildTopBar(song),
        Expanded(child: _buildMainContent()),
        // 进度条
        PlayerSeekBar(
          position: _position,
          duration: _duration,
          onSeek: (pos) => ref.read(audioServiceProvider).seek(pos),
        ),
        const SizedBox(height: 8),
        // 名称-作者（居中）
        _buildSongInfoRow(song),
        const SizedBox(height: 4),
        // 底部控制栏：收藏、评论、播放控制、循环模式、播放列表
        _buildBottomControls(song),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PlayerColors.backgroundTop,
                PlayerColors.backgroundMid,
                PlayerColors.backgroundBottom,
              ],
            ),
          ),
        ),
        if (_coverUrl != null)
          // 本地封面（已下载歌曲图片.jpg）铺满背景；否则网络图
          _fullBleedCover(_coverUrl!),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
                Colors.black,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Song song) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          _topBarBtn(Icons.keyboard_arrow_down_rounded, () => context.pop()),
          Expanded(
            child: Text(
              song.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0x99FFFFFF),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _topBarBtn(Icons.more_horiz_rounded, () => _showMoreMenu(song)),
        ],
      ),
    );
  }

  /// ⋮ 更多菜单：加入歌单 / 定时关闭 / 歌曲信息
  void _showMoreMenu(Song song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('更多', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: _moreMenuIcon(Icons.queue_music_rounded),
              title: const Text('加入歌单'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                showPlaylistPickerSheet(context, ref, song: song);
              },
            ),
            ListTile(
              leading: _moreMenuIcon(Icons.download_rounded),
              title: const Text('下载'),
              trailing: Icon(Icons.download_done_rounded,
                  color: Colors.grey.withValues(alpha: 0.4), size: 20),
              onTap: () {
                Navigator.pop(context);
                _startDownload(song);
              },
            ),
            ListTile(
              leading: _moreMenuIcon(Icons.bedtime_outlined),
              title: const Text('定时关闭'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('定时关闭功能暂未支持'), duration: Duration(seconds: 2)),
                );
              },
            ),
            ListTile(
              leading: _moreMenuIcon(Icons.info_outline_rounded),
              title: const Text('歌曲信息'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${song.name} · ${song.artist}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 更多菜单项图标（浅靛蓝圆角底）
  Widget _moreMenuIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
    );
  }

  /// 下载当前歌曲（写入系统下载目录 下载/JoyTune/<歌名>-<歌手>/，离线可播）
  Future<void> _startDownload(Song song) async {
    // Android 写公共 Download 目录需存储权限：下载前检查并引导授权
    if (!await hasDownloadWritePermission()) {
      await requestDownloadWritePermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('首次下载需授予存储权限')),
      );
      return;
    }
    final ok = await ref.read(downloadServiceProvider).download(song);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(ok != null ? '已开始下载：${song.name}' : '下载失败，请重试'),
      ));
  }

  Widget _topBarBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 36, height: 36,
      child: IconButton(
        icon: Icon(icon, color: const Color(0x99FFFFFF), size: 24),
        onPressed: onTap,
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMainContent() {
    // 封面页需要根据可用空间动态计算尺寸，避免窗口缩小时溢出
    return LayoutBuilder(
      builder: (context, constraints) {
        // 封面页：封面 + 上下间距(各20) + 提示文字(约20)
        final maxCoverSize = (constraints.maxHeight - 60).clamp(120.0, 280.0);
        return GestureDetector(
          onTap: () {
            if (_lyrics.isNotEmpty) {
              setState(() => _showLyrics = !_showLyrics);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showLyrics
                ? _buildLyricsPage()
                : _buildCoverPage(coverSize: maxCoverSize),
          ),
        );
      },
    );
  }

  Widget _buildCoverPage({required double coverSize}) {
    final borderRadius = coverSize / 2;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _rotationCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotationCtrl.value * 2 * math.pi,
              child: child,
            ),
            child: Container(
              width: coverSize, height: coverSize,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: _coverUrl != null
                    ? _coverArtwork(
                        url: _coverUrl!,
                        size: coverSize,
                        placeholder: () => _coverPlaceholder(),
                        errorWidget: () => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_lyrics.isNotEmpty)
            Text(
              '轻点显示歌词',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PlayerColors.placeholderTop,
            PlayerColors.placeholderMid,
            PlayerColors.placeholderBottom,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  /// 播放页背景封面（铺满）：本地封面（已下载图片.jpg）用 Image.file，否则网络图
  Widget _fullBleedCover(String url) {
    if (isLocalCoverUrl(url)) {
      final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  /// 播放页圆形封面：本地封面（已下载图片.jpg）用 Image.file，否则网络图
  Widget _coverArtwork({
    required String url,
    required double size,
    required Widget Function() placeholder,
    required Widget Function() errorWidget,
  }) {
    if (isLocalCoverUrl(url)) {
      final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => errorWidget(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder(),
      errorWidget: (_, __, ___) => errorWidget(),
    );
  }

  Widget _buildLyricsPage() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
        stops: const [0.0, 0.1, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _lyricScrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        itemCount: _lyrics.length,
        itemExtent: 48,
        itemBuilder: (_, i) {
          final isCurrent = i == _currentLyricIndex;
          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: isCurrent ? 17 : 14,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.3),
              height: 1.3,
            ),
            child: Text(
              _lyrics[i].text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  // ── 名称-作者行（居中）──

  Widget _buildSongInfoRow(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            song.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            song.artist,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 底部控制栏：收藏 | 评论 | 播放控制 | 循环模式 | 播放列表 ──

  Widget _buildBottomControls(Song song) {
    final audio = ref.watch(audioServiceProvider);
    final hasPrev = audio.currentQueueIndex > 0;
    final hasNext = audio.currentQueueIndex < audio.queue.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 收藏
          FavoriteButton(song: song),
          // 评论
          _bottomIcon(Icons.chat_bubble_outline_rounded, null, () => context.push('/comments', extra: song)),
          // 播放控制（上一步 / 播放暂停 / 下一步）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ctrlBtn(Icons.skip_previous_rounded, 26, hasPrev ? () => audio.playPrevious() : null),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _onPlayToggle(song),
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 4))],
                  ),
                  child: Icon(
                    _playState == PlayState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ctrlBtn(Icons.skip_next_rounded, 26, hasNext ? () => audio.playNext() : null),
            ],
          ),
          // 循环模式
          _bottomIcon(_playModeIcon(audio.playMode), null, _cyclePlayMode),
          // 播放列表
          _bottomIcon(Icons.playlist_play_rounded, null, () => PlaylistQueueSheet.show(context)),
        ],
      ),
    );
  }

  // ── 通用按钮 ──

  Widget _ctrlBtn(IconData icon, double size, VoidCallback? onTap) {
    return SizedBox(
      width: 36, height: 36,
      child: IconButton(
        icon: Icon(icon, color: onTap != null ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2), size: size),
        onPressed: onTap,
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _bottomIcon(IconData icon, Color? color, VoidCallback onTap) {
    return SizedBox(
      width: 44, height: 44,
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.6), size: 24),
        onPressed: onTap,
        splashRadius: 22,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
