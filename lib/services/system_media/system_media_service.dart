import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isPipModeProvider = StateProvider<bool>((ref) => false);

final systemMediaServiceProvider = Provider<SystemMediaService>((ref) {
  final service = SystemMediaService.instance;
  service.initialize(ref);
  return service;
});

class SystemMediaService {
  static final SystemMediaService instance = SystemMediaService._internal();
  SystemMediaService._internal();

  static const MethodChannel _channel = MethodChannel('com.auraplayer/media_controls');

  Ref? _ref;
  final StreamController<String> _mediaActionController = StreamController<String>.broadcast();
  Stream<String> get onMediaAction => _mediaActionController.stream;

  bool _isInitialized = false;

  void initialize(Ref ref) {
    _ref = ref;
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipModeChanged':
          final isPip = call.arguments as bool? ?? false;
          _ref?.read(isPipModeProvider.notifier).state = isPip;
          break;
        case 'onMediaAction':
          final action = call.arguments as String? ?? '';
          _mediaActionController.add(action);
          break;
      }
    });

    requestNotificationPermission();
  }

  Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (_) {
      // Non-Android fallback
    }
  }

  Future<bool> enterPiP() async {
    try {
      final success = await _channel.invokeMethod<bool>('enterPiP');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setVideoActive(bool isActive) async {
    try {
      await _channel.invokeMethod('setVideoActive', {'isActive': isActive});
    } catch (_) {
      // Non-Android fallback
    }
  }

  Future<void> updateNotification({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('updateNotification', {
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      });
    } catch (_) {
      // Non-Android fallback
    }
  }

  Future<void> hideNotification() async {
    try {
      await _channel.invokeMethod('hideNotification');
    } catch (_) {
      // Non-Android fallback
    }
  }

  void dispose() {
    _mediaActionController.close();
  }
}
