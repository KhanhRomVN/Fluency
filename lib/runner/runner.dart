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
import 'package:fluency/runner/sherpa/sherpa_initializer.dart'
    if (dart.library.io) 'package:fluency/runner/sherpa/sherpa_initializer_native.dart'
    if (dart.library.html) 'package:fluency/runner/sherpa/sherpa_initializer_web.dart';

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
      },
    );
  }

  static Future<void> _runApp() async {
    WidgetsFlutterBinding.ensureInitialized();
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
  }

  static void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {});
  }
}
