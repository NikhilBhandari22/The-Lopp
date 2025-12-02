import 'package:flutter/foundation.dart';

/// Production-safe logger that only logs in debug mode
class AppLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  static void info(String message, {String? tag}) {
    log('ℹ️ $message', tag: tag);
  }

  static void success(String message, {String? tag}) {
    log('✅ $message', tag: tag);
  }

  static void warning(String message, {String? tag}) {
    log('⚠️ $message', tag: tag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix❌ $message');
      if (error != null) {
        debugPrint('$prefix   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$prefix   Stack: $stackTrace');
      }
    }
  }
}
