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

  /// 从歌曲名+歌手生成稳定的缓存 key（无 ID 的 mock 歌曲也能用）
  static String cacheKey(String name, String artist, {String? songId}) {
    if (songId != null && songId.isNotEmpty) return songId;
    // 使用名称作为 key，只保留字母数字中文和下划线
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
