import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Minimal logger. Release builds keep warning and above only.
class Log {
  const Log._();

  static LogLevel minLevel = kReleaseMode ? LogLevel.warning : LogLevel.debug;

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);
  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);
  static void w(String tag, String message) =>
      _log(LogLevel.warning, tag, message);
  static void e(String tag, String message, [Object? error]) =>
      _log(LogLevel.error, tag, error == null ? message : '$message: $error');

  static void _log(LogLevel level, String tag, String message) {
    if (level.index < minLevel.index) return;
    debugPrint('[${level.name}] $tag: $message');
  }
}
