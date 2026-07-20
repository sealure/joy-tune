import 'dart:async';
import 'package:media_kit/media_kit.dart';
import '../models/song.dart';

/// 音频播放服务（基于 media_kit）
class AudioService {
  final Player _player = Player();

  // ── 可观察状态 ──
  final StreamController<PlayState> _stateController =
      StreamController<PlayState>.broadcast();

  Stream<PlayState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _player.streams.position;
  Stream<Duration?> get durationStream => _player.streams.duration;

  PlayState _state = PlayState.stopped;
  PlayState get state => _state;

  Duration? get position => _player.state.position;
  Duration? get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;

  AudioService() {
    // 错误处理
    _player.streams.error.listen((error) {
      _updateState(PlayState.stopped);
    });

    // 缓冲中 → loading
    _player.streams.buffering.listen((buffering) {
      if (buffering && !_player.state.playing) {
        _updateState(PlayState.loading);
      }
    });

    // 播放状态变化
    _player.streams.playing.listen((playing) {
      if (playing) {
        _updateState(PlayState.playing);
      } else if (_state == PlayState.playing || _state == PlayState.loading) {
        _updateState(PlayState.paused);
      }
    });

    // 播放完成
    _player.streams.completed.listen((completed) {
      if (completed) {
        _updateState(PlayState.stopped);
      }
    });
  }

  /// 播放 URL
  Future<void> play(String url) async {
    _updateState(PlayState.loading);
    try {
      await _player.open(Media(url));
      await _player.play();
    } catch (e) {
      _updateState(PlayState.stopped);
      rethrow;
    }
  }

  /// 暂停
  void pause() {
    _player.pause();
  }

  /// 恢复
  void resume() {
    _player.play();
  }

  /// 停止
  void stop() {
    _player.stop();
  }

  /// 跳转
  Future<void> seek(Duration position) => _player.seek(position);

  /// 设置音量
  void setVolume(double volume) {
    _player.setVolume(volume.clamp(0.0, 1.0));
  }

  void _updateState(PlayState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
  }
}
