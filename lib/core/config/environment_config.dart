import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static Future<void> init() async {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const fileName = flavor == 'prod' ? '.env.prod' : '.env.dev';
    await dotenv.load(fileName: fileName);
  }

  static String get apiUrl => dotenv.env['API_URL'] ?? 'https://api.example.com';

  static String get appName => dotenv.env['APP_NAME'] ?? 'Template App';
}
