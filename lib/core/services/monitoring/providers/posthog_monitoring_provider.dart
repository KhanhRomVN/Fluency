import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';

/// PostHog implementation of the MonitoringProvider
class PostHogMonitoringProvider extends MonitoringProvider {
  @override
  Future<void> init() async {
    // PostHog is mainly configured via native metadata (AndroidManifest.xml / Info.plist)
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await Posthog().capture(
      eventName: name,
      properties: parameters,
    );
  }

  @override
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    // PostHog is primarily for product analytics, so we log errors as events
    await Posthog().capture(
      eventName: 'exception',
      properties: {
        'error': error.toString(),
        'fatal': fatal,
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  @override
  Future<void> recordFatalError(dynamic errorDetails) async {
    await Posthog().capture(
      eventName: 'fatal_error',
      properties: {
        'details': errorDetails.toString(),
      },
    );
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    await Posthog().capture(
      eventName: r'$set',
      properties: {
        r'$set': {name: value}
      },
    );
  }

  @override
  void forceCrash() {
    // PostHog doesn't typically handle hard crashes; it's an analytics service.
  }
}
