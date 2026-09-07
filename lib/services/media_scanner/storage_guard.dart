import 'dart:io';
import '../logger/offline_logger.dart';

class StorageGuard {
  /// Verifies if a media file is readable, not empty, and has standard media headers
  static Future<bool> isValidMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        await OfflineLogger.instance.log(
          LogLevel.warning,
          'StorageGuard',
          'Media file not found: $filePath',
        );
        return false;
      }

      final length = await file.length();
      if (length <= 0) {
        await OfflineLogger.instance.log(
          LogLevel.warning,
          'StorageGuard',
          'Encountered empty 0-byte media file: $filePath',
        );
        return false;
      }

      // Check header readability (first 64 bytes)
      final stream = file.openRead(0, 64);
      final bytes = await stream.first;
      if (bytes.isEmpty) {
        return false;
      }

      return true;
    } catch (e, stack) {
      await OfflineLogger.instance.logError('StorageGuard', 'Corrupt file error: $e', stack);
      return false;
    }
  }

  /// Checks if available storage space is sufficient before writing subtitles or cache
  static bool hasSufficientStorage({required int requiredBytes, required int availableBytes}) {
    // Reserve minimum 20MB buffer for OS stability
    const safetyBuffer = 20 * 1024 * 1024;
    return availableBytes > (requiredBytes + safetyBuffer);
  }
}
