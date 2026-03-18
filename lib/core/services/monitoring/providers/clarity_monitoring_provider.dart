import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';

/// Microsoft Clarity implementation of the MonitoringProvider
class ClarityMonitoringProvider extends MonitoringProvider {
  @override
  Future<void> init() async {
    // Clarity is initialized via ClarityWidget in runner.dart
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Clarity primarily records sessions, but we can set custom tags to mark events
    await Clarity.setCustomTag(
        name, parameters?.values.join(',') ?? 'triggered');
  }

  @override
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    // Clarity automatically captures errors and associates them with session recordings
  }

  @override
  Future<void> recordFatalError(dynamic errorDetails) async {
    // Clarity automatically captures fatal crashes
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    if (name == 'userId' || name == 'id') {
      await Clarity.setCustomUserId(value);
    } else {
      await Clarity.setCustomTag(name, value);
    }
  }

  @override
  void forceCrash() {
    // Not supported by Clarity
  }
}
