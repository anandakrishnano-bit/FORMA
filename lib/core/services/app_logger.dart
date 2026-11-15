import 'dart:collection';
import 'package:flutter/foundation.dart';

enum AppLogLevel { info, warn, error, success }

class AppLogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
  final AppLogLevel level;
  final String? errorDetails;

  const AppLogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
    required this.level,
    this.errorDetails,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelPrefix {
    switch (level) {
      case AppLogLevel.info:
        return '[INFO]';
      case AppLogLevel.warn:
        return '[WARN]';
      case AppLogLevel.error:
        return '[ERROR]';
      case AppLogLevel.success:
        return '[SUCCESS]';
    }
  }

  @override
  String toString() {
    final err = errorDetails != null ? ' | Details: $errorDetails' : '';
    return '$formattedTime $levelPrefix [$tag] $message$err';
  }
}

/// Central in-memory ring-buffer logger and diagnostics recorder for FORMA.
class AppLogger {
  static const int _maxLogs = 200;
  static final DoubleLinkedQueue<AppLogEntry> _logs =
      DoubleLinkedQueue<AppLogEntry>();
  static final ValueNotifier<int> logCountNotifier = ValueNotifier<int>(0);

  static void info(String tag, String message) {
    _add(AppLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: AppLogLevel.info,
    ));
  }

  static void success(String tag, String message) {
    _add(AppLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: AppLogLevel.success,
    ));
  }

  static void warn(String tag, String message, [Object? error]) {
    _add(AppLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: AppLogLevel.warn,
      errorDetails: error?.toString(),
    ));
  }

  static void error(String tag, String message,
      [Object? error, StackTrace? stack]) {
    _add(AppLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      level: AppLogLevel.error,
      errorDetails: error != null ? '$error\n${stack ?? ""}' : null,
    ));
  }

  static void _add(AppLogEntry entry) {
    if (_logs.length >= _maxLogs) {
      _logs.removeFirst();
    }
    _logs.addLast(entry);
    logCountNotifier.value++;
    debugPrint(entry.toString());
  }

  static List<AppLogEntry> getLogs() {
    return _logs.toList();
  }

  static String exportLogsAsString() {
    if (_logs.isEmpty) {
      return '--- FORMA System Logs (Empty) ---';
    }
    final buffer = StringBuffer();
    buffer.writeln('=== FORMA LIVE SYSTEM DIAGNOSTICS & LOGS ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Log Entries: ${_logs.length}\n');
    for (final entry in _logs) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }

  static void clear() {
    _logs.clear();
    logCountNotifier.value = 0;
  }
}
