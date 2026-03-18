import 'package:freerasp/freerasp.dart';
import 'package:fluency/core/services/monitoring/providers/monitoring_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Talsec (freeRASP) implementation of the MonitoringProvider.
/// This provider handles runtime application self-protection (RASP).
class TalsecMonitoringProvider extends MonitoringProvider {
  final String watcherMail;
  final String androidPackageName;
  final List<String> androidSigningHashes;
  final String iosBundleId;
  final String? iosTeamId;

  TalsecMonitoringProvider({
    required this.watcherMail,
    required this.androidPackageName,
    required this.androidSigningHashes,
    required this.iosBundleId,
    this.iosTeamId,
  });

  @override
  Future<void> init() async {
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: androidPackageName,
        signingCertHashes: androidSigningHashes,
      ),
      iosConfig: IOSConfig(
        bundleIds: [iosBundleId], // ✅ Đổi từ bundleId → bundleIds (List)
        teamId: iosTeamId ?? '',
      ),
      watcherMail: watcherMail,
      isProd: kReleaseMode, // ✅ Thay isSlowDeviceCheckEnabled bằng isProd
    );

    final callback = ThreatCallback(
      // ✅ Đổi TalsecCallback → ThreatCallback
      onPrivilegedAccess: () => _handleThreat('Root/Jailbreak Detected'),
      onSimulator: () => _handleThreat('Emulator/Simulator Detected'),
      onDebug: () => _handleThreat('Debugger Detected'),
      onAppIntegrity: () => _handleThreat('App Integrity Issue'),
      onObfuscationIssues: () => _handleThreat('Obfuscation Issue'),
      onHooks: () => _handleThreat('Hooks Detected'),
      onDeviceBinding: () => _handleThreat('Device Binding Issue'),
      onSecureHardwareNotAvailable: () =>
          _handleThreat('Secure Hardware Not Available'),
      onSystemVPN: () => _handleThreat('VPN Detected'),
    );

    try {
      // 1. Check for unsupported architectures (x86, x86_64) that cause crash on startup
      // Talsec (freeRASP) does not support x86/x86_64 architectures (common in emulators)
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final abis = androidInfo.supportedAbis.map((e) => e.toLowerCase());

        if (abis.any((abi) => abi.contains('x86'))) {
          debugPrint(
              '[Talsec] Skipping RASP on unsupported architecture (x86/x86_64): ${androidInfo.supportedAbis}');
          return;
        }
      }

      Talsec.instance.attachListener(callback); // ✅ attachListener trước
      await Talsec.instance.start(config); // ✅ start chỉ nhận config
      debugPrint('[Talsec] RASP started successfully');
    } catch (e, stack) {
      debugPrint('[Talsec] Failed to start RASP: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  void _handleThreat(String threatType) {
    debugPrint('[Talsec] THREAT DETECTED: $threatType');
    MonitoringService.trackEvent('security_threat_detected', parameters: {
      'type': threatType,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // In a production app, you might want to show a warning or exit
    // but for now we just log it.
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Talsec is for security monitoring, it doesn't log general events
  }

  @override
  Future<void> recordError(dynamic error,
      {StackTrace? stackTrace, bool fatal = false}) async {
    // Talsec doesn't log generic errors
  }

  @override
  Future<void> recordFatalError(dynamic errorDetails) async {
    // Talsec doesn't log fatal errors
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    // Talsec doesn't store user properties
  }

  @override
  void forceCrash() {
    // Not applicable
  }
}
