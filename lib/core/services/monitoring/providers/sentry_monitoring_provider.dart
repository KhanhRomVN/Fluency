import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';
import 'package:flutter/foundation.dart';

/// Sentry implementation of the MonitoringProvider
class SentryMonitoringProvider extends MonitoringProvider {
  final String dsn;

  SentryMonitoringProvider({required this.dsn});

  @override
  Future<void> init() async {
    // Sentry is initialized in its own static method in the runner
    // but we ensure it's configured here if needed for per-provider logic.
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Sentry uses breadcrumbs for non-error events
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: name,
        data: parameters,
        category: 'action',
        level: SentryLevel.info,
      ),
    );
  }

  @override
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (fatal) {
          scope.level = SentryLevel.fatal;
        }
      },
    );
  }

  @override
  Future<void> recordFatalError(dynamic errorDetails) async {
    if (errorDetails is FlutterErrorDetails) {
      await Sentry.captureException(
        errorDetails.exception,
        stackTrace: errorDetails.stack,
        withScope: (scope) {
          scope.level = SentryLevel.fatal;
        },
      );
    } else {
      await Sentry.captureException(
        errorDetails,
        withScope: (scope) {
          scope.level = SentryLevel.fatal;
        },
      );
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    await Sentry.configureScope((scope) {
      scope.setTag(name, value);
    });
  }

  @override
  void forceCrash() {
    throw Exception('Sentry Test Crash: ${DateTime.now()}');
  }
}
