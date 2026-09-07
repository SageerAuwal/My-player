import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/core/models/media_item.dart';
import 'package:aura_player/core/models/subtitle_item.dart';

void main() {
  test('MediaItem model serialization and formatting', () {
    const item = MediaItem(
      id: 1,
      path: '/storage/movies/sample.mp4',
      title: 'Sample Video',
      durationMs: 754000, // 12m 34s
      type: MediaType.video,
      sizeBytes: 104857600, // 100 MB
      dateAdded: 1690000000,
      lastPositionMs: 377000,
      isFavorite: true,
    );

    expect(item.isVideo, isTrue);
    expect(item.isAudio, isFalse);
    expect(item.formattedDuration, '12:34');
    expect(item.formattedSize, '100.0 MB');
    expect(item.progressPercentage, closeTo(0.5, 0.01));

    final map = item.toMap();
    final reconstructed = MediaItem.fromMap(map);

    expect(reconstructed.title, 'Sample Video');
    expect(reconstructed.type, MediaType.video);
    expect(reconstructed.isFavorite, isTrue);
    expect(reconstructed.lastPositionMs, 377000);
  });

  test('SubtitleItem model serialization', () {
    const subtitle = SubtitleItem(
      id: 42,
      mediaId: 1,
      path: '/storage/movies/sample_en.srt',
      language: 'en',
      isAiGenerated: true,
      createdAt: 1700000000,
    );

    final map = subtitle.toMap();
    expect(map['is_ai_generated'], 1);
    expect(map['language'], 'en');
    expect(map['format'], 'srt');

    final reconstructed = SubtitleItem.fromMap(map);
    expect(reconstructed.id, 42);
    expect(reconstructed.mediaId, 1);
    expect(reconstructed.isAiGenerated, isTrue);
    expect(reconstructed.language, 'en');
  });

  test('MediaItem copyWith method modifies fields correctly', () {
    const original = MediaItem(
      id: 1,
      path: '/path/to/file.mp3',
      title: 'Original Title',
      durationMs: 120000,
      type: MediaType.audio,
      sizeBytes: 4000000,
      dateAdded: 1700000000,
    );

    final updated = original.copyWith(
      isFavorite: true,
      lastPositionMs: 60000,
      title: 'Updated Title',
    );

    expect(updated.id, 1);
    expect(updated.path, '/path/to/file.mp3');
    expect(updated.title, 'Updated Title');
    expect(updated.isFavorite, isTrue);
    expect(updated.lastPositionMs, 60000);
  });
}
