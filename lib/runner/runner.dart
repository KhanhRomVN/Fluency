import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../app.dart';
import '../core/config/environment_config.dart';
import '../di/injection_container.dart' as di;

/// App runner class
class Runner {
  /// Defines how the application should start
  static Future<void> run() async {
    // Handling errors that occur before the application starts
    runZonedGuarded<Future<void>>(
      () async {
        _initLogger();
        _runApp();
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
    runApp(const Application());
  }

  static void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Basic print for now, can be improved
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }
}
