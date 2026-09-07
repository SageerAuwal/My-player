import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../core/models/media_item.dart';
import '../database/app_database.dart';

class ScanProgress {
  final int filesFound;
  final String currentPath;
  final bool isScanning;

  const ScanProgress({
    this.filesFound = 0,
    this.currentPath = '',
    this.isScanning = false,
  });
}

class MediaScannerService {
  static final MediaScannerService instance = MediaScannerService._internal();
  MediaScannerService._internal();

  static const Set<String> supportedVideoExtensions = {
    '.mp4', '.mkv', '.avi', '.mov', '.webm', '.ts', '.flv', '.wmv', '.m4v', '.3gp'
  };

  static const Set<String> supportedAudioExtensions = {
    '.mp3', '.flac', '.aac', '.wav', '.ogg', '.m4a', '.opus', '.wma'
  };

  Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) granular permissions
      final videoStatus = await Permission.videos.request();
      final audioStatus = await Permission.audio.request();

      if (videoStatus.isGranted || audioStatus.isGranted) {
        return true;
      }

      // Fallback for Android 12 and below
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<List<MediaItem>> scanDeviceStorage({
    void Function(ScanProgress progress)? onProgress,
  }) async {
    final hasPermission = await requestStoragePermissions();
    if (!hasPermission) {
      debugPrint('MediaScannerService: Storage permissions not granted');
      return [];
    }

    final discoveredMedia = <MediaItem>[];
    final targetDirectories = <Directory>[];

    if (Platform.isAndroid) {
      const rootPath = '/storage/emulated/0';
      final commonFolders = [
        'Movies',
        'Download',
        'Music',
        'DCIM',
        'Videos',
        'Podcasts',
        'Audiobooks',
        'Ringtones',
      ];

      for (final folder in commonFolders) {
        final dir = Directory('$rootPath/$folder');
        if (dir.existsSync()) {
          targetDirectories.add(dir);
        }
      }

      // If specific directories don't exist, scan root folder safely
      if (targetDirectories.isEmpty && Directory(rootPath).existsSync()) {
        targetDirectories.add(Directory(rootPath));
      }
    } else {
      // For desktop / emulator test environments
      final current = Directory.current;
      targetDirectories.add(current);
    }

    int count = 0;

    for (final dir in targetDirectories) {
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            final isVideo = supportedVideoExtensions.contains(ext);
            final isAudio = supportedAudioExtensions.contains(ext);

            if (isVideo || isAudio) {
              try {
                final stat = await entity.stat();
                final filename = p.basenameWithoutExtension(entity.path);

                final mediaItem = MediaItem(
                  path: entity.path,
                  title: filename,
                  durationMs: 0, // Updated on first load via media_kit
                  type: isVideo ? MediaType.video : MediaType.audio,
                  sizeBytes: stat.size,
                  dateAdded: stat.modified.millisecondsSinceEpoch,
                );

                discoveredMedia.add(mediaItem);
                count++;

                onProgress?.call(ScanProgress(
                  filesFound: count,
                  currentPath: entity.path,
                  isScanning: true,
                ));
              } catch (e) {
                debugPrint('Error reading file metadata: ${entity.path} - $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning directory: ${dir.path} - $e');
      }
    }

    // Persist discovered media to SQLite database in batch
    if (discoveredMedia.isNotEmpty) {
      await AppDatabase.instance.batchInsertOrUpdateMedia(discoveredMedia);
    }

    onProgress?.call(ScanProgress(
      filesFound: count,
      currentPath: '',
      isScanning: false,
    ));

    return discoveredMedia;
  }
}
