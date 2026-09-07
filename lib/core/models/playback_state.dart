import '../../core/models/media_item.dart';

enum PlayerAspectRatio {
  fit,
  fill,
  cover,
  ratio16x9,
  ratio4x3,
}

enum RepeatMode {
  off,
  all,
  one,
}

class PlaybackState {
  final MediaItem? currentItem;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume; // 0.0 to 1.0
  final double brightness; // 0.0 to 1.0
  final double playbackSpeed; // 0.5 to 2.0
  final PlayerAspectRatio aspectRatio;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final bool isControlsVisible;
  final bool isLocked;

  const PlaybackState({
    this.currentItem,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.brightness = 0.5,
    this.playbackSpeed = 1.0,
    this.aspectRatio = PlayerAspectRatio.fit,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.isControlsVisible = true,
    this.isLocked = false,
  });

  double get progressPercentage {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get formattedPosition => _formatDuration(position);
  String get formattedDuration => _formatDuration(duration);
  String get formattedRemaining => _formatDuration(duration - position);

  static String _formatDuration(Duration d) {
    if (d.isNegative) return '0:00';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  PlaybackState copyWith({
    MediaItem? currentItem,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? brightness,
    double? playbackSpeed,
    PlayerAspectRatio? aspectRatio,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    bool? isControlsVisible,
    bool? isLocked,
  }) {
    return PlaybackState(
      currentItem: currentItem ?? this.currentItem,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      brightness: brightness ?? this.brightness,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isControlsVisible: isControlsVisible ?? this.isControlsVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
