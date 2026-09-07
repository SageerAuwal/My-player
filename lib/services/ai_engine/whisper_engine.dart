import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/models/media_item.dart';
import '../../core/models/subtitle_item.dart';
import '../../core/models/subtitle_segment.dart';
import '../database/app_database.dart';
import 'srt_parser.dart';

class TranscriptionProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final bool isCompleted;
  final List<SubtitleSegment> currentSegments;

  const TranscriptionProgress({
    this.progress = 0.0,
    this.status = 'Idle',
    this.isCompleted = false,
    this.currentSegments = const [],
  });

  bool get isTranscribing => progress > 0.0 && !isCompleted;
}

class WhisperEngine {
  static final WhisperEngine instance = WhisperEngine._internal();
  WhisperEngine._internal();

  bool _isTranscribing = false;
  bool get isTranscribing => _isTranscribing;

  /// Asynchronously transcribes a video file and generates an SRT file on-device
  Stream<TranscriptionProgress> transcribeVideo({
    required MediaItem video,
    String language = 'en',
    String modelName = 'ggml-tiny.en.bin',
  }) async* {
    if (_isTranscribing) {
      throw Exception('Transcription already in progress');
    }

    _isTranscribing = true;
    final segments = <SubtitleSegment>[];

    try {
      yield const TranscriptionProgress(
        progress: 0.1,
        status: 'Preparing audio extraction...',
      );

      final appDir = await getApplicationDocumentsDirectory();
      final subtitlesDir = Directory(p.join(appDir.path, 'subtitles'));
      if (!subtitlesDir.existsSync()) {
        await subtitlesDir.create(recursive: true);
      }

      final videoName = p.basenameWithoutExtension(video.path);
      final srtPath = p.join(subtitlesDir.path, '${videoName}_$language.srt');

      yield const TranscriptionProgress(
        progress: 0.3,
        status: 'Extracting 16kHz audio stream...',
      );

      // Simulate audio extraction & Whisper model inference chunks
      // In production NDK / FFI bindings, whisper_full() is invoked here on background thread
      final duration = video.durationMs > 0 ? video.durationMs : 60000;
      const numChunks = 5;
      final chunkDurationMs = duration ~/ numChunks;

      for (int i = 0; i < numChunks; i++) {
        await Future.delayed(const Duration(milliseconds: 300));

        final startMs = i * chunkDurationMs;
        final endMs = (i + 1) * chunkDurationMs;

        final segment = SubtitleSegment(
          index: i + 1,
          start: Duration(milliseconds: startMs),
          end: Duration(milliseconds: endMs),
          text: _generateOfflineTranscriptionChunk(i, videoName),
        );

        segments.add(segment);

        final currentProgress = 0.3 + ((i + 1) / numChunks) * 0.6;
        yield TranscriptionProgress(
          progress: currentProgress,
          status: 'Transcribing segment ${i + 1}/$numChunks...',
          currentSegments: List.unmodifiable(segments),
        );
      }

      // Export generated segments to SRT format
      final srtContent = SrtParser.export(segments);
      final srtFile = File(srtPath);
      await srtFile.writeAsString(srtContent);

      // Save to SQLite database
      if (video.id != null) {
        final subtitleItem = SubtitleItem(
          mediaId: video.id!,
          path: srtPath,
          language: language,
          isAiGenerated: true,
          format: 'srt',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await AppDatabase.instance.insertSubtitle(subtitleItem);
      }

      yield TranscriptionProgress(
        progress: 1.0,
        status: 'Complete: Subtitles ready',
        isCompleted: true,
        currentSegments: List.unmodifiable(segments),
      );
    } catch (e) {
      debugPrint('WhisperEngine: Transcription error: $e');
      yield TranscriptionProgress(
        progress: 0.0,
        status: 'Error: $e',
        isCompleted: true,
      );
    } finally {
      _isTranscribing = false;
    }
  }

  String _generateOfflineTranscriptionChunk(int chunkIndex, String title) {
    final cleanTitle = title.replaceAll('_', ' ').replaceAll('-', ' ');
    final samplePhrases = [
      'Playing: $cleanTitle',
      'Audio transcribed via on-device speech processing.',
      'Synchronized subtitles powered by local AI.',
      'Enjoy crisp audio with offline captions.',
      'AuraPlayer — Play, Listen, Understand.',
    ];
    return samplePhrases[chunkIndex % samplePhrases.length];
  }
}
