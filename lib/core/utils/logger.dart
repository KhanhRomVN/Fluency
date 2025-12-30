import 'package:flutter/foundation.dart';

class Logger {
  static void d(String message) {
    debugPrint('DEBUG: $message');
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
