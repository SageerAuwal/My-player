import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/media_item.dart';
import '../../../core/models/subtitle_segment.dart';
import '../../../services/ai_engine/srt_parser.dart';
import '../../../services/ai_engine/whisper_engine.dart';
import '../../../services/database/app_database.dart';
import '../../home/controller/media_providers.dart';
import '../../video/controller/playback_controller.dart';

final whisperEngineProvider = Provider<WhisperEngine>((ref) {
  return WhisperEngine.instance;
});

final transcriptionProgressProvider = StateProvider<TranscriptionProgress>((ref) {
  return const TranscriptionProgress();
});

final isSubtitlesEnabledProvider = StateProvider<bool>((ref) => true);
final subtitleDelayMsProvider = StateProvider<int>((ref) => 0);
final subtitleFontSizeProvider = StateProvider<double>((ref) => 18.0);

final subtitleSegmentsProvider = StateProvider<List<SubtitleSegment>>((ref) {
  return const [];
});

/// Reactive provider that returns the subtitle text matching current video playback position using O(log N) binary search
final currentSubtitleTextProvider = Provider<String?>((ref) {
  final isEnabled = ref.watch(isSubtitlesEnabledProvider);
  if (!isEnabled) return null;

  final segments = ref.watch(subtitleSegmentsProvider);
  if (segments.isEmpty) return null;

  final delayMs = ref.watch(subtitleDelayMsProvider);
  final currentPos = ref.watch(playbackControllerProvider).position;
  final adjustedPos = currentPos - Duration(milliseconds: delayMs);

  return SubtitleSegment.findSegmentAt(segments, adjustedPos)?.text;
});

class SubtitleNotifier extends StateNotifier<List<SubtitleSegment>> {
  final WhisperEngine _engine;
  final AppDatabase _db;
  final Ref _ref;

  SubtitleNotifier(this._engine, this._db, this._ref) : super(const []);

  Future<void> startTranscription(MediaItem video) async {
    _ref.read(transcriptionProgressProvider.notifier).state = const TranscriptionProgress(
      progress: 0.05,
      status: 'Initializing Whisper engine...',
    );

    try {
      await for (final progress in _engine.transcribeVideo(video: video)) {
        _ref.read(transcriptionProgressProvider.notifier).state = progress;
        if (progress.currentSegments.isNotEmpty) {
          state = progress.currentSegments;
          _ref.read(subtitleSegmentsProvider.notifier).state = progress.currentSegments;
        }
      }
    } catch (e) {
      _ref.read(transcriptionProgressProvider.notifier).state = TranscriptionProgress(
        progress: 0.0,
        status: 'Failed: $e',
        isCompleted: true,
      );
    }
  }

  Future<void> loadSubtitlesForMedia(int mediaId) async {
    final subs = await _db.getSubtitlesForMedia(mediaId);
    if (subs.isNotEmpty) {
      final file = File(subs.first.path);
      if (file.existsSync()) {
        final content = await file.readAsString();
        final segments = SrtParser.parse(content);
        state = segments;
        _ref.read(subtitleSegmentsProvider.notifier).state = segments;
      }
    }
  }

  void loadFromSrtString(String content) {
    final segments = SrtParser.parse(content);
    state = segments;
    _ref.read(subtitleSegmentsProvider.notifier).state = segments;
  }

  Future<void> loadFromFile(File file) async {
    if (await file.exists()) {
      final content = await file.readAsString();
      loadFromSrtString(content);
    }
  }

  void adjustDelay(int deltaMs) {
    final current = _ref.read(subtitleDelayMsProvider);
    _ref.read(subtitleDelayMsProvider.notifier).state = current + deltaMs;
  }

  void setFontSize(double size) {
    _ref.read(subtitleFontSizeProvider.notifier).state = size;
  }

  void clearSubtitles() {
    state = const [];
    _ref.read(subtitleSegmentsProvider.notifier).state = const [];
  }
}

final subtitleNotifierProvider = StateNotifierProvider<SubtitleNotifier, List<SubtitleSegment>>((ref) {
  final engine = ref.watch(whisperEngineProvider);
  final db = ref.watch(appDatabaseProvider);
  return SubtitleNotifier(engine, db, ref);
});
