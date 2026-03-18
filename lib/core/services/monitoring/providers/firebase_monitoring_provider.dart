import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';

/// Firebase implementation of the MonitoringProvider
class FirebaseMonitoringProvider extends MonitoringProvider {
  @override
  Future<void> init() async {
    // Firebase core is initialized in the main app runner
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  @override
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    await FirebaseCrashlytics.instance
        .recordError(error, stackTrace, fatal: fatal);
  }

  @override
  Future<void> recordFatalError(dynamic errorDetails) async {
    if (errorDetails is FlutterErrorDetails) {
      await FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      await FirebaseCrashlytics.instance
          .recordError(errorDetails, null, fatal: true);
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
  }

  @override
  void forceCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
