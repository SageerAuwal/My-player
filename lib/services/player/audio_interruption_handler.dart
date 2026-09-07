import 'dart:async';
import '../logger/offline_logger.dart';

enum AudioInterruptionType {
  headphoneUnplugged, // Becoming Noisy event
  audioFocusLossTransient, // Temporary loss (GPS/Notification)
  audioFocusLossPermanent, // Permanent loss (Incoming phone call)
  audioFocusGained, // Audio focus resumed
}

class AudioInterruptionHandler {
  final Future<void> Function() onPauseRequested;
  final void Function(double volumeMultiplier)? onVolumeDuckRequested;

  AudioInterruptionHandler({
    required this.onPauseRequested,
    this.onVolumeDuckRequested,
  });

  /// Simulates handling an audio focus / device disconnect event from Android OS
  Future<void> handleInterruption(AudioInterruptionType type) async {
    await OfflineLogger.instance.logInfo(
      'AudioInterruptionHandler',
      'Handling audio event: ${type.name}',
    );

    switch (type) {
      case AudioInterruptionType.headphoneUnplugged:
      case AudioInterruptionType.audioFocusLossPermanent:
        // Automatically pause immediately to prevent noise leakage
        await onPauseRequested();
        break;

      case AudioInterruptionType.audioFocusLossTransient:
        // Duck volume if handler is provided, otherwise pause
        if (onVolumeDuckRequested != null) {
          onVolumeDuckRequested!(0.2); // Duck to 20%
        } else {
          await onPauseRequested();
        }
        break;

      case AudioInterruptionType.audioFocusGained:
        // Restore full volume
        if (onVolumeDuckRequested != null) {
          onVolumeDuckRequested!(1.0);
        }
        break;
    }
  }
}
