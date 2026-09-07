import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/models/media_item.dart';

class PlaybackService {
  late final Player _player;
  late final VideoController _videoController;

  final List<StreamSubscription> _subscriptions = [];

  Player get player => _player;
  VideoController get videoController => _videoController;

  PlaybackService() {
    _player = Player(
      configuration: const PlayerConfiguration(
        pitch: true,
        bufferSize: 32 * 1024 * 1024, // 32MB buffer for smooth playback
        logLevel: kDebugMode ? MPVLogLevel.warn : MPVLogLevel.error,
      ),
    );

    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
  }

  Future<void> playMedia(MediaItem item, {Duration? startPosition}) async {
    try {
      await _player.open(
        Media(item.path, start: startPosition),
        play: true,
      );
    } catch (e) {
      debugPrint('PlaybackService: Failed to open media: $e');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> playOrPause() async {
    await _player.playOrPause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekForward(int seconds) async {
    final target = _player.state.position + Duration(seconds: seconds);
    await _player.seek(target < _player.state.duration ? target : _player.state.duration);
  }

  Future<void> seekBackward(int seconds) async {
    final target = _player.state.position - Duration(seconds: seconds);
    await _player.seek(target > Duration.zero ? target : Duration.zero);
  }

  Future<void> setVolume(double volume) async {
    // volume is 0.0 to 1.0, media_kit expects 0.0 to 100.0
    await _player.setVolume((volume * 100.0).clamp(0.0, 100.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed.clamp(0.25, 4.0));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
  }
}
