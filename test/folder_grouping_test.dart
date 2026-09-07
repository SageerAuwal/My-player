import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/core/models/media_item.dart';
import 'package:aura_player/core/models/media_folder.dart';

void main() {
  group('MediaFolder Grouping Tests', () {
    test('groups empty list into empty folders list', () {
      final result = MediaFolder.groupByFolder([]);
      expect(result, isEmpty);
    });

    test('groups media items correctly by their directory path', () {
      final items = [
        const MediaItem(
          id: 1,
          path: '/storage/emulated/0/DCIM/Camera/VID_20260101.mp4',
          title: 'VID_20260101',
          durationMs: 120000,
          type: MediaType.video,
          sizeBytes: 10485760, // 10MB
          dateAdded: 1700000000,
        ),
        const MediaItem(
          id: 2,
          path: '/storage/emulated/0/DCIM/Camera/VID_20260102.mp4',
          title: 'VID_20260102',
          durationMs: 60000,
          type: MediaType.video,
          sizeBytes: 5242880, // 5MB
          dateAdded: 1700000010,
        ),
        const MediaItem(
          id: 3,
          path: '/storage/emulated/0/Download/movie.mkv',
          title: 'movie',
          durationMs: 7200000,
          type: MediaType.video,
          sizeBytes: 1073741824, // 1GB
          dateAdded: 1700000020,
        ),
        const MediaItem(
          id: 4,
          path: 'C:\\Users\\User\\Videos\\WhatsApp Video\\video1.mp4',
          title: 'video1',
          durationMs: 30000,
          type: MediaType.video,
          sizeBytes: 2097152, // 2MB
          dateAdded: 1700000030,
        ),
      ];

      final folders = MediaFolder.groupByFolder(items);

      expect(folders.length, 3);
      // Alphabetical sorting: Camera, Download, WhatsApp Video
      expect(folders[0].name, 'Camera');
      expect(folders[0].count, 2);
      expect(folders[0].formattedCount, '2 videos');
      expect(folders[0].totalSizeBytes, 15728640);
      expect(folders[0].formattedSize, '15.0 MB');

      expect(folders[1].name, 'Download');
      expect(folders[1].count, 1);
      expect(folders[1].formattedCount, '1 video');
      expect(folders[1].formattedSize, '1.00 GB');

      expect(folders[2].name, 'WhatsApp Video');
      expect(folders[2].count, 1);
      expect(folders[2].formattedCount, '1 video');
      expect(folders[2].formattedSize, '2.0 MB');
    });

    test('handles root or malformed paths gracefully', () {
      final items = [
        const MediaItem(
          id: 1,
          path: 'file.mp4',
          title: 'file',
          durationMs: 1000,
          type: MediaType.video,
          sizeBytes: 500,
          dateAdded: 1000,
        ),
      ];

      final folders = MediaFolder.groupByFolder(items);
      expect(folders.length, 1);
      expect(folders.first.name, 'Internal Storage');
      expect(folders.first.count, 1);
    });
  });
}
