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

  Future<void> init() async {
    if (_initialized) return;
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _initialized = true;
  }

  String _cachePath(String songId) => '${_cacheDir.path}/$songId.mp3';

  /// 检查歌曲是否已缓存
  Future<bool> has(String songId) async {
    if (!_initialized) await init();
    return File(_cachePath(songId)).exists();
  }

  /// 获取本地缓存路径（如果存在）
  Future<String?> getLocalPath(String songId) async {
    if (!_initialized) await init();
    final path = _cachePath(songId);
    if (await File(path).exists()) return path;
    return null;
  }

  /// 下载音频到本地缓存
  Future<String> download(String url, String songId) async {
    if (!_initialized) await init();
    final path = _cachePath(songId);
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
