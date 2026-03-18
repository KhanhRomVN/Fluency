import 'package:flutter/foundation.dart';

/// Base interface for monitoring providers (Firebase, Sentry, etc.)
abstract class MonitoringProvider {
  /// Initialize the provider
  Future<void> init();

  /// Log an analytical event
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Record a non-fatal error
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false});

  /// Record a fatal platform-level error
  Future<void> recordFatalError(dynamic errorDetails);

  /// Track a change in user property (e.g. theme, level)
  Future<void> setUserProperty(String name, String value);

  /// Force a crash (for testing purposes)
  void forceCrash() {
    throw UnsupportedError('forceCrash is only for specific providers');
  }
}
