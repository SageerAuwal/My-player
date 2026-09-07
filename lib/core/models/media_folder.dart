import 'media_item.dart';

class MediaFolder {
  final String path;
  final String name;
  final List<MediaItem> items;
  final int totalSizeBytes;
  final MediaItem? previewItem;

  const MediaFolder({
    required this.path,
    required this.name,
    required this.items,
    required this.totalSizeBytes,
    this.previewItem,
  });

  int get count => items.length;

  String get formattedCount => '$count ${count == 1 ? 'video' : 'videos'}';

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    final kb = totalSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  static List<MediaFolder> groupByFolder(List<MediaItem> items) {
    if (items.isEmpty) return [];

    final Map<String, List<MediaItem>> folderMap = {};

    for (final item in items) {
      final folderPath = _extractParentDirectory(item.path);
      folderMap.putIfAbsent(folderPath, () => []).add(item);
    }

    final List<MediaFolder> folders = [];

    folderMap.forEach((folderPath, folderItems) {
      final folderName = _extractFolderName(folderPath);
      final totalSize = folderItems.fold<int>(0, (sum, i) => sum + i.sizeBytes);

      // Pick the most recent item for thumbnail preview
      final preview = folderItems.isNotEmpty ? folderItems.first : null;

      folders.add(
        MediaFolder(
          path: folderPath,
          name: folderName,
          items: folderItems,
          totalSizeBytes: totalSize,
          previewItem: preview,
        ),
      );
    });

    // Sort folders alphabetically by name
    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return folders;
  }

  static String _extractParentDirectory(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash != -1) {
      return normalized.substring(0, lastSlash);
    }
    return 'Internal Storage';
  }

  static String _extractFolderName(String folderPath) {
    final normalized = folderPath.replaceAll('\\', '/');
    final trimmed = normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;
    final lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash != -1 && lastSlash < trimmed.length - 1) {
      final name = trimmed.substring(lastSlash + 1);
      return name.isEmpty ? 'Internal Storage' : name;
    }
    return trimmed.isEmpty ? 'Internal Storage' : trimmed;
  }
}
