import 'package:flutter_test/flutter_test.dart';
import 'package:aura_player/services/logger/offline_logger.dart';

void main() {
  test('LogEntry formats timestamp, level, tag, and message cleanly', () {
    final entry = LogEntry(
      timestamp: DateTime(2026, 8, 21, 12, 0, 0),
      level: LogLevel.error,
      tag: 'PlaybackEngine',
      message: 'Decoder initialization failed',
    );

    final formatted = entry.format();
    expect(formatted, contains('[ERROR]'));
    expect(formatted, contains('[PlaybackEngine]'));
    expect(formatted, contains('Decoder initialization failed'));
  });

  test('OfflineLogger maintains in-memory buffer correctly', () async {
    final logger = OfflineLogger.instance;
    logger.clearInMemoryLogs();

    await logger.logInfo('TestTag', 'Info message 1');
    await logger.logInfo('TestTag', 'Info message 2');

    expect(logger.inMemoryLogs.length, 2);
    expect(logger.inMemoryLogs.first.message, 'Info message 1');
    expect(logger.inMemoryLogs.last.message, 'Info message 2');
  });
}
