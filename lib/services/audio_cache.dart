import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// 音频文件本地缓存
class AudioCache {
  static AudioCache? _instance;
  late final Directory _cacheDir;
  final Dio _dio = Dio();
  bool _initialized = false;

  AudioCache._();

  static AudioCache get instance {
    _instance ??= AudioCache._();
    return _instance!;
  }

  /// 从歌曲名+歌手生成稳定的缓存 key
  static String cacheKey(String name, String artist) {
    final raw = '$name-$artist';
    return raw.replaceAll(RegExp(r'[^\w\u4e00-\u9fff\-]'), '_');
  }

  Future<void> init() async {
    if (_initialized) return;
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _initialized = true;
  }

  String _cachePath(String key) => '${_cacheDir.path}/$key.mp3';
  String _metaPath(String key) => '${_cacheDir.path}/$key.json';

  /// 检查歌曲是否已缓存
  Future<bool> has(String key) async {
    if (!_initialized) await init();
    return File(_cachePath(key)).exists();
  }

  /// 获取本地缓存路径（如果存在）
  Future<String?> getLocalPath(String key) async {
    if (!_initialized) await init();
    final path = _cachePath(key);
    if (await File(path).exists()) return path;
    return null;
  }

  /// 下载音频到本地缓存，返回缓存 key
  Future<String> download(String url, String key) async {
    if (!_initialized) await init();
    final path = _cachePath(key);
    await _dio.download(url, path);
    return path;
  }

  /// 保存歌曲元数据（封面 URL、歌词等）
  Future<void> saveMetadata(String key, Map<String, dynamic> metadata) async {
    if (!_initialized) await init();
    final file = File(_metaPath(key));
    await file.writeAsString(jsonEncode(metadata));
  }

  /// 读取缓存的元数据
  Future<Map<String, dynamic>?> loadMetadata(String key) async {
    if (!_initialized) await init();
    final file = File(_metaPath(key));
    if (await file.exists()) {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    }
    return null;
  }

  // 封面 URL / 歌词全文缓存已统一迁至 sqlite（local_song_meta），
  // 封面图片字节由 CachedNetworkImage 磁盘缓存，此处仅保留音频与播放会话元数据。

  /// 获取缓存大小
  Future<int> cacheSize() async {
    if (!_initialized) await init();
    int size = 0;
    await for (final file in _cacheDir.list()) {
      if (file is File) size += await file.length();
    }
    return size;
  }

  /// 清理全部缓存
  Future<void> clear() async {
    if (!_initialized) await init();
    if (await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create();
    }
  }
}
