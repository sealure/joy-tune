import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

/// 音频播放服务
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // ── 可观察状态 ──
  final StreamController<PlayState> _stateController =
      StreamController<PlayState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  Stream<PlayState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlayState _state = PlayState.stopped;
  PlayState get state => _state;

  Duration? get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  AudioService() {
    // 监听播放完成
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _updateState(PlayState.stopped);
      }
    });

    // 监听位置更新
    _player.positionStream.listen((pos) {
      _positionController.add(pos);
    });
  }

  /// 播放 URL
  Future<void> play(String url) async {
    _updateState(PlayState.loading);
    try {
      await _player.setUrl(url);
      _player.play();
      _updateState(PlayState.playing);
    } catch (e) {
      _updateState(PlayState.stopped);
      rethrow;
    }
  }

  /// 暂停
  void pause() {
    _player.pause();
    _updateState(PlayState.paused);
  }

  /// 恢复
  void resume() {
    _player.play();
    _updateState(PlayState.playing);
  }

  /// 停止
  void stop() {
    _player.stop();
    _updateState(PlayState.stopped);
  }

  /// 跳转
  void seek(Duration position) => _player.seek(position);

  /// 设置音量
  void setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  void _updateState(PlayState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
    _positionController.close();
  }
}
