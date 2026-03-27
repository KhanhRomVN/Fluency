import 'dart:async';

import 'package:fluency/app.dart';
import 'package:fluency/core/config/environment_config.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/core/services/usage/app_usage_service.dart';
import 'package:fluency/di/injection_container.dart' as di;
import 'package:fluency/di/injection_container.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluency/runner/sherpa/sherpa_initializer.dart'
    if (dart.library.io) 'package:fluency/runner/sherpa/sherpa_initializer_native.dart'
    if (dart.library.html) 'package:fluency/runner/sherpa/sherpa_initializer_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/firebase_options.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/core/services/monitoring/providers/firebase_monitoring_provider.dart';
import 'package:fluency/core/services/monitoring/providers/sentry_monitoring_provider.dart';
import 'package:fluency/core/services/monitoring/providers/talsec_monitoring_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// App runner class
class Runner {
  /// Defines how the application should start
  static Future<void> run() async {
    // Handling errors that occur before the application starts
    await runZonedGuarded<Future<void>>(
      () async {
        _initLogger();
        await _runApp();
      },
      (error, stack) {
        // Log startup error
        Logger('Runner').severe('Startup error', error, stack);
        MonitoringService.captureError(error, stackTrace: stack, fatal: true);
      },
    );
  }

  static Future<void> _runApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Sentry
    if (!kIsWeb) {
      await SentryFlutter.init(
        (options) {
          options.dsn =
              'https://6f7d290fb7a06a5996c8e91ab780b41f@o4511049481322496.ingest.us.sentry.io/4511049482502144';
          // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
          // We recommend adjusting this value in production.
          options.tracesSampleRate = 1.0;
        },
      );
    }

    // Register Monitoring Providers
    MonitoringService.registerProvider(FirebaseMonitoringProvider());
    if (!kIsWeb) {
      MonitoringService.registerProvider(SentryMonitoringProvider(
        dsn:
            'https://6f7d290fb7a06a5996c8e91ab780b41f@o4511049481322496.ingest.us.sentry.io/4511049482502144',
      ));
    }
    if (!kIsWeb) {
      MonitoringService.registerProvider(TalsecMonitoringProvider(
        watcherMail: 'khanhromvn@gmail.com',
        androidPackageName: 'com.zenoravn.fluency',
        androidSigningHashes: ['iQ5Y1CmtCE0mJH5vX0i7VVprC5KN8BPtH7PzstHyNGI='],
        iosBundleId: 'com.zenoravn.fluency',
      ));
    }

    // Initialize monitoring. Sentry/Firebase are critical, others can follow.
    await MonitoringService.init();

    // Pass all uncaught "fatal" errors from the framework to Monitoring Service
    FlutterError.onError = MonitoringService.captureFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Monitoring Service
    PlatformDispatcher.instance.onError = (error, stack) {
      MonitoringService.captureError(error, stackTrace: stack, fatal: true);
      return true;
    };
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize Environment Config
    await EnvironmentConfig.init();
    // Initialize Dependency Injection
    await di.init();
    // Initialize Sherpa Onnx
    initSherpaBindings();

    // Initialize DirectoryStorage
    await directoryStorage.init();

    // Start Usage Tracking
    sl<AppUsageService>().startTracking();

    // Initialize SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();

    runApp(Application(sharedPreferences: sharedPreferences));

    // Log app start after UI is visible
    unawaited(MonitoringService.trackEvent('app_start_optimized'));
  }

  static void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {});
  }
}
