import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/core/models/media_item.dart';

void main() {
  group('Playlist Navigation Logic Tests', () {
    const item1 = MediaItem(
      id: 1,
      path: '/media/song1.mp3',
      title: 'Song 1',
      durationMs: 180000,
      type: MediaType.audio,
      sizeBytes: 1000,
      dateAdded: 1,
    );
    const item2 = MediaItem(
      id: 2,
      path: '/media/song2.mp3',
      title: 'Song 2',
      durationMs: 200000,
      type: MediaType.audio,
      sizeBytes: 1000,
      dateAdded: 2,
    );
    const item3 = MediaItem(
      id: 3,
      path: '/media/song3.mp3',
      title: 'Song 3',
      durationMs: 220000,
      type: MediaType.audio,
      sizeBytes: 1000,
      dateAdded: 3,
    );

    final queue = [item1, item2, item3];

    test('finds initial index correctly', () {
      final index = queue.indexWhere((i) => i.path == item2.path);
      expect(index, 1);
    });

    test('advances to next track in queue', () {
      var currentIndex = 0;
      if (currentIndex < queue.length - 1) {
        currentIndex++;
      }
      expect(currentIndex, 1);
      expect(queue[currentIndex].title, 'Song 2');
    });

    test('loops from last track to first track on next', () {
      var currentIndex = 2;
      if (currentIndex < queue.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }
      expect(currentIndex, 0);
      expect(queue[currentIndex].title, 'Song 1');
    });

    test('goes to previous track in queue', () {
      var currentIndex = 1;
      if (currentIndex > 0) {
        currentIndex--;
      }
      expect(currentIndex, 0);
      expect(queue[currentIndex].title, 'Song 1');
    });
  });
}
