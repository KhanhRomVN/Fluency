import 'package:flutter/foundation.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';

/// Central Monitoring Service to handle all analytics and error reporting
/// This decouples the app from specific third-party providers.
class MonitoringService {
  static final List<MonitoringProvider> _providers = [];

  /// Register a provider (e.g. Firebase, Sentry)
  static void registerProvider(MonitoringProvider provider) {
    _providers.add(provider);
  }

  /// Initialize all registered providers
  static Future<void> init() async {
    for (final provider in _providers) {
      await provider.init();
    }
  }

  /// Capture and report a generic exception/error
  static Future<void> captureError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    if (kDebugMode) {
      debugPrint('[Monitoring] Captured Error: $error');
    }
    for (final provider in _providers) {
      await provider.recordError(error, stackTrace: stackTrace, fatal: fatal);
    }
  }

  /// Capture and report a fatal Flutter error
  static Future<void> captureFatalError(dynamic errorDetails) async {
    for (final provider in _providers) {
      await provider.recordFatalError(errorDetails);
    }
  }

  /// Track a user event (Analytics)
  static Future<void> trackEvent(String name,
      {Map<String, Object>? parameters}) async {
    if (kDebugMode) {
      debugPrint('[Monitoring] Event tracked: $name | $parameters');
    }
    for (final provider in _providers) {
      await provider.logEvent(name, parameters: parameters);
    }
  }

  /// Track a user property
  static Future<void> trackUserProperty(String name, String value) async {
    for (final provider in _providers) {
      await provider.setUserProperty(name, value);
    }
  }

  /// Trigger a crash for testing (only calls the first provider that supports it)
  static void testCrash() {
    if (_providers.isNotEmpty) {
      _providers.first.forceCrash();
    }
  }

  /// Send test signals to all providers (Event and Non-fatal Error)
  static Future<void> testAll() async {
    await trackEvent('test_event',
        parameters: {'time': DateTime.now().toString()});
    await captureError(Exception('Test Non-fatal Error at ${DateTime.now()}'),
        fatal: false);
  }
}
