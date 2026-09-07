import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_folder.dart';
import '../../../core/models/media_item.dart';
import '../../../services/database/app_database.dart';
import '../../../services/media_scanner/media_scanner_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final mediaScannerProvider = Provider<MediaScannerService>((ref) {
  return MediaScannerService.instance;
});

final scanProgressProvider = StateProvider<ScanProgress>((ref) {
  return const ScanProgress();
});

final mediaSearchQueryProvider = StateProvider<String>((ref) => '');

enum VideoViewMode {
  folders,
  allVideos,
}

final videoViewModeProvider = StateProvider<VideoViewMode>((ref) => VideoViewMode.folders);

final videoListProvider = FutureProvider<List<MediaItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final query = ref.watch(mediaSearchQueryProvider);
  return db.getMediaList(type: MediaType.video, searchQuery: query);
});

final videoFoldersProvider = FutureProvider<List<MediaFolder>>((ref) async {
  final videos = await ref.watch(videoListProvider.future);
  return MediaFolder.groupByFolder(videos);
});

final audioListProvider = FutureProvider<List<MediaItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final query = ref.watch(mediaSearchQueryProvider);
  return db.getMediaList(type: MediaType.audio, searchQuery: query);
});

final recentMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getRecentMedia(limit: 10);
});

final favoriteMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getMediaList(favoritesOnly: true);
});

class MediaNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final AppDatabase _db;
  final MediaScannerService _scanner;
  final Ref _ref;

  MediaNotifier(this._db, this._scanner, this._ref) : super(const AsyncValue.loading()) {
    loadAllMedia();
  }

  Future<void> loadAllMedia() async {
    try {
      state = const AsyncValue.loading();
      final items = await _db.getMediaList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> scanDevice() async {
    _ref.read(scanProgressProvider.notifier).state = const ScanProgress(isScanning: true);
    await _scanner.scanDeviceStorage(
      onProgress: (progress) {
        _ref.read(scanProgressProvider.notifier).state = progress;
      },
    );
    await loadAllMedia();
    _ref.invalidate(videoListProvider);
    _ref.invalidate(audioListProvider);
    _ref.invalidate(recentMediaProvider);
    _ref.invalidate(favoriteMediaProvider);
  }

  Future<void> toggleFavorite(int id) async {
    await _db.toggleFavorite(id);
    await loadAllMedia();
    _ref.invalidate(favoriteMediaProvider);
    _ref.invalidate(videoListProvider);
    _ref.invalidate(audioListProvider);
  }

  Future<void> updatePlaybackPosition(int id, int positionMs) async {
    await _db.updateLastPosition(id, positionMs);
    _ref.invalidate(recentMediaProvider);
  }
}

final mediaNotifierProvider = StateNotifierProvider<MediaNotifier, AsyncValue<List<MediaItem>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final scanner = ref.watch(mediaScannerProvider);
  return MediaNotifier(db, scanner, ref);
});
