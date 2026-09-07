import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/playback_state.dart';

final seekStepDurationProvider = StateProvider<int>((ref) => 10);
final defaultAspectRatioProvider = StateProvider<PlayerAspectRatio>((ref) => PlayerAspectRatio.fit);
final autoPlayNextProvider = StateProvider<bool>((ref) => true);
final backgroundPlaybackProvider = StateProvider<bool>((ref) => true);

final cacheSizeProvider = FutureProvider<String>((ref) async {
  try {
    final tempDir = await getTemporaryDirectory();
    int totalBytes = 0;
    if (tempDir.existsSync()) {
      for (final file in tempDir.listSync(recursive: true)) {
        if (file is File) {
          totalBytes += await file.length();
        }
      }
    }
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } catch (_) {
    return '0.0 MB';
  }
});

class CacheCleaner {
  static Future<int> clearCache() async {
    int deletedBytes = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        for (final file in tempDir.listSync(recursive: true)) {
          if (file is File) {
            try {
              final len = await file.length();
              await file.delete();
              deletedBytes += len;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return deletedBytes;
  }
}
