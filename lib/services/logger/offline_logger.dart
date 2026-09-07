import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LogLevel { info, warning, error, fatal }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  String format() {
    final timeStr = timestamp.toIso8601String();
    final lvl = level.name.toUpperCase();
    final stack = stackTrace != null ? '\n$stackTrace' : '';
    return '[$timeStr][$lvl][$tag] $message$stack';
  }
}

class OfflineLogger {
  static final OfflineLogger instance = OfflineLogger._internal();
  OfflineLogger._internal();

  final List<LogEntry> _inMemoryLogs = [];
  List<LogEntry> get inMemoryLogs => List.unmodifiable(_inMemoryLogs);

  static const int maxInMemoryLogs = 200;
  static const int maxLogFileSize = 2 * 1024 * 1024; // 2MB max log size

  Future<void> log(
    LogLevel level,
    String tag,
    String message, {
    StackTrace? stackTrace,
  }) async {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      stackTrace: stackTrace?.toString(),
    );

    _inMemoryLogs.add(entry);
    if (_inMemoryLogs.length > maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint(entry.format());
    }

    // Write to offline local log file
    await _writeToDisk(entry);
  }

  Future<void> logError(String tag, dynamic error, [StackTrace? stackTrace]) async {
    await log(LogLevel.error, tag, error.toString(), stackTrace: stackTrace);
  }

  Future<void> logInfo(String tag, String message) async {
    await log(LogLevel.info, tag, message);
  }

  Future<void> _writeToDisk(LogEntry entry) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logFile = File(p.join(dir.path, 'aura_player_offline.log'));

      // Check log rotation if file exceeds 2MB
      if (await logFile.exists()) {
        final length = await logFile.length();
        if (length > maxLogFileSize) {
          final oldLog = File(p.join(dir.path, 'aura_player_offline.log.old'));
          if (await oldLog.exists()) {
            await oldLog.delete();
          }
          await logFile.rename(oldLog.path);
        }
      }

      await logFile.writeAsString(
        '${entry.format()}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Zero crash guarantee on logging
    }
  }

  void clearInMemoryLogs() {
    _inMemoryLogs.clear();
  }
}
