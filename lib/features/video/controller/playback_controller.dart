import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/playback_state.dart';
import '../../../services/database/app_database.dart';
import '../../../services/player/playback_service.dart';
import '../../../services/system_media/system_media_service.dart';
import '../../home/controller/media_providers.dart';

final playbackServiceProvider = Provider<PlaybackService>((ref) {
  final service = PlaybackService();
  ref.onDispose(() => service.dispose());
  return service;
});

class PlaybackController extends StateNotifier<PlaybackState> {
  final PlaybackService _service;
  final AppDatabase _db;
  final SystemMediaService _systemMedia;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _controlsTimer;

  List<MediaItem> _queue = [];
  int _queueIndex = 0;

  PlaybackController(this._service, this._db, this._systemMedia) : super(const PlaybackState()) {
    _initStreams();
    _initSystemMediaActions();
  }

  void _initStreams() {
    _subscriptions.add(
      _service.player.stream.playing.listen((isPlaying) {
        state = state.copyWith(isPlaying: isPlaying);
        if (isPlaying) {
          _resetControlsTimer();
        }
        _syncSystemNotification(isPlaying: isPlaying);
      }),
    );

    _subscriptions.add(
      _service.player.stream.buffering.listen((isBuffering) {
        state = state.copyWith(isBuffering: isBuffering);
      }),
    );

    _subscriptions.add(
      _service.player.stream.position.listen((position) {
        state = state.copyWith(position: position);
        final item = state.currentItem;
        if (item?.id != null && position.inSeconds > 0 && position.inSeconds % 5 == 0) {
          _db.updateLastPosition(item!.id!, position.inMilliseconds);
        }
      }),
    );

    _subscriptions.add(
      _service.player.stream.duration.listen((duration) {
        state = state.copyWith(duration: duration);
      }),
    );

    _subscriptions.add(
      _service.player.stream.rate.listen((rate) {
        state = state.copyWith(playbackSpeed: rate);
      }),
    );

    _subscriptions.add(
      _service.player.stream.completed.listen((completed) {
        if (completed) {
          state = state.copyWith(isPlaying: false);
          final item = state.currentItem;
          if (item?.id != null) {
            _db.updateLastPosition(item!.id!, 0);
          }
          // Auto play next in queue
          if (_queue.isNotEmpty && _queueIndex < _queue.length - 1) {
            playNext();
          } else {
            _syncSystemNotification(isPlaying: false);
          }
        }
      }),
    );
  }

  void _initSystemMediaActions() {
    _subscriptions.add(
      _systemMedia.onMediaAction.listen((action) {
        switch (action) {
          case 'playPause':
            togglePlayPause();
            break;
          case 'next':
            playNext();
            break;
          case 'previous':
            playPrevious();
            break;
          case 'stop':
            stop();
            break;
        }
      }),
    );
  }

  void _syncSystemNotification({required bool isPlaying}) {
    final item = state.currentItem;
    if (item != null) {
      _systemMedia.updateNotification(
        title: item.title,
        artist: item.artist ?? item.album ?? (item.isVideo ? 'Video Playback' : 'Aura Music'),
        isPlaying: isPlaying,
      );
    } else {
      _systemMedia.hideNotification();
    }
  }

  Future<void> playMedia(MediaItem item, {List<MediaItem>? playlist}) async {
    if (playlist != null && playlist.isNotEmpty) {
      _queue = playlist;
      _queueIndex = _queue.indexWhere((i) => i.path == item.path);
      if (_queueIndex == -1) _queueIndex = 0;
    } else if (!_queue.any((i) => i.path == item.path)) {
      _queue = [item];
      _queueIndex = 0;
    } else {
      _queueIndex = _queue.indexWhere((i) => i.path == item.path);
    }

    state = state.copyWith(
      currentItem: item,
      position: Duration(milliseconds: item.lastPositionMs),
      isControlsVisible: true,
    );

    final startPos = item.lastPositionMs > 0
        ? Duration(milliseconds: item.lastPositionMs)
        : null;

    if (item.isVideo) {
      await _systemMedia.setVideoActive(true);
      await _systemMedia.hideNotification();
    } else {
      await _systemMedia.setVideoActive(false);
      _syncSystemNotification(isPlaying: true);
    }

    await _service.playMedia(item, startPosition: startPos);
    _resetControlsTimer();
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      await playMedia(_queue[_queueIndex]);
    } else {
      // Loop to beginning
      _queueIndex = 0;
      await playMedia(_queue[_queueIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    if (state.position.inSeconds > 3) {
      // If played more than 3s, seek to start of current track
      await seekTo(Duration.zero);
      return;
    }
    if (_queueIndex > 0) {
      _queueIndex--;
      await playMedia(_queue[_queueIndex]);
    } else {
      _queueIndex = _queue.length - 1;
      await playMedia(_queue[_queueIndex]);
    }
  }

  Future<void> togglePlayPause() async {
    await _service.playOrPause();
    _resetControlsTimer();
  }

  Future<void> stop() async {
    await _service.pause();
    await _systemMedia.hideNotification();
    await _systemMedia.setVideoActive(false);
    state = state.copyWith(isPlaying: false);
  }

  Future<void> seekTo(Duration position) async {
    await _service.seek(position);
    final item = state.currentItem;
    if (item?.id != null) {
      await _db.updateLastPosition(item!.id!, position.inMilliseconds);
    }
    _resetControlsTimer();
  }

  Future<void> seekRelative(int seconds) async {
    if (seconds > 0) {
      await _service.seekForward(seconds);
    } else {
      await _service.seekBackward(seconds.abs());
    }
    _resetControlsTimer();
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await _service.setVolume(clamped);
  }

  void setBrightness(double brightness) {
    state = state.copyWith(brightness: brightness.clamp(0.0, 1.0));
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _service.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
    _resetControlsTimer();
  }

  void setAspectRatio(PlayerAspectRatio ratio) {
    state = state.copyWith(aspectRatio: ratio);
  }

  void toggleControls() {
    if (state.isLocked) return;
    final next = !state.isControlsVisible;
    state = state.copyWith(isControlsVisible: next);
    if (next) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void toggleLock() {
    state = state.copyWith(
      isLocked: !state.isLocked,
      isControlsVisible: !state.isLocked ? false : true,
    );
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (state.isPlaying && !state.isLocked) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          state = state.copyWith(isControlsVisible: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

final playbackControllerProvider = StateNotifierProvider<PlaybackController, PlaybackState>((ref) {
  final service = ref.watch(playbackServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  final systemMedia = ref.watch(systemMediaServiceProvider);
  return PlaybackController(service, db, systemMedia);
});
