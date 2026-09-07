import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/services/media_scanner/storage_guard.dart';
import 'package:aura_player/services/player/audio_interruption_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageGuard edge-case tests', () {
    test('Non-existent and empty files are flagged as invalid', () async {
      final isNonExistentValid = await StorageGuard.isValidMediaFile('/invalid/path/video.mp4');
      expect(isNonExistentValid, isFalse);

      final tempDir = await Directory.systemTemp.createTemp('aura_test_');
      final emptyFile = File('${tempDir.path}/empty_video.mp4');
      await emptyFile.writeAsBytes([]);

      final isEmptyValid = await StorageGuard.isValidMediaFile(emptyFile.path);
      expect(isEmptyValid, isFalse);

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('Valid files with content pass validation', () async {
      final tempDir = await Directory.systemTemp.createTemp('aura_test_valid_');
      final validFile = File('${tempDir.path}/sample.mp4');
      await validFile.writeAsBytes(List.filled(128, 0xFF));

      final isValid = await StorageGuard.isValidMediaFile(validFile.path);
      expect(isValid, isTrue);

      await tempDir.delete(recursive: true);
    });

    test('hasSufficientStorage reserves safety buffer for OS', () {
      // 50MB available, requiring 10MB -> True (10MB + 20MB buffer < 50MB)
      expect(
        StorageGuard.hasSufficientStorage(
          requiredBytes: 10 * 1024 * 1024,
          availableBytes: 50 * 1024 * 1024,
        ),
        isTrue,
      );

      // 25MB available, requiring 10MB -> False (10MB + 20MB buffer = 30MB > 25MB)
      expect(
        StorageGuard.hasSufficientStorage(
          requiredBytes: 10 * 1024 * 1024,
          availableBytes: 25 * 1024 * 1024,
        ),
        isFalse,
      );
    });
  });

  group('AudioInterruptionHandler robustness tests', () {
    test('Headphone unplug ("Becoming Noisy") pauses playback immediately', () async {
      bool wasPaused = false;
      final handler = AudioInterruptionHandler(
        onPauseRequested: () async {
          wasPaused = true;
        },
      );

      await handler.handleInterruption(AudioInterruptionType.headphoneUnplugged);
      expect(wasPaused, isTrue);
    });

    test('Transient audio focus loss ducks volume properly', () async {
      double duckedVolume = 1.0;
      final handler = AudioInterruptionHandler(
        onPauseRequested: () async {},
        onVolumeDuckRequested: (vol) {
          duckedVolume = vol;
        },
      );

      await handler.handleInterruption(AudioInterruptionType.audioFocusLossTransient);
      expect(duckedVolume, 0.2);

      await handler.handleInterruption(AudioInterruptionType.audioFocusGained);
      expect(duckedVolume, 1.0);
    });
  });
}
