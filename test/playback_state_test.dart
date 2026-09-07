import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/core/models/media_item.dart';
import 'package:aura_player/core/models/playback_state.dart';

void main() {
  test('PlaybackState initial values and duration formatting', () {
    const state = PlaybackState(
      position: Duration(minutes: 3, seconds: 45),
      duration: Duration(hours: 1, minutes: 20, seconds: 0),
    );

    expect(state.isPlaying, isFalse);
    expect(state.isBuffering, isFalse);
    expect(state.formattedPosition, '3:45');
    expect(state.formattedDuration, '1:20:00');
    expect(state.formattedRemaining, '1:16:15');
    expect(state.playbackSpeed, 1.0);
    expect(state.aspectRatio, PlayerAspectRatio.fit);
    expect(state.isControlsVisible, isTrue);
    expect(state.isLocked, isFalse);
  });

  test('PlaybackState progress percentage calculation', () {
    const state = PlaybackState(
      position: Duration(seconds: 30),
      duration: Duration(seconds: 120),
    );

    expect(state.progressPercentage, 0.25);
  });

  test('PlaybackState copyWith creates new instance with updated properties', () {
    const initial = PlaybackState();
    const media = MediaItem(
      id: 5,
      path: '/path/to/movie.mp4',
      title: 'Movie Title',
      durationMs: 3600000,
      type: MediaType.video,
      sizeBytes: 500000000,
      dateAdded: 1700000000,
    );

    final updated = initial.copyWith(
      currentItem: media,
      isPlaying: true,
      playbackSpeed: 1.5,
      aspectRatio: PlayerAspectRatio.cover,
      isControlsVisible: false,
    );

    expect(updated.currentItem?.title, 'Movie Title');
    expect(updated.isPlaying, isTrue);
    expect(updated.playbackSpeed, 1.5);
    expect(updated.aspectRatio, PlayerAspectRatio.cover);
    expect(updated.isControlsVisible, isFalse);
  });
}
