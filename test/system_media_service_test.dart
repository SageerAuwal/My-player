import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_player/services/system_media/system_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemMediaService Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes with default isPipMode as false', () {
      final isPip = container.read(isPipModeProvider);
      expect(isPip, isFalse);
    });

    test('handles fallback when running without native platform bridge', () async {
      final service = container.read(systemMediaServiceProvider);

      // Should not throw exceptions on any platform fallback
      expect(() async => await service.enterPiP(), returnsNormally);
      expect(() async => await service.setVideoActive(true), returnsNormally);
      expect(() async => await service.updateNotification(title: 'Test', artist: 'Artist', isPlaying: true), returnsNormally);
      expect(() async => await service.hideNotification(), returnsNormally);
    });
  });
}
