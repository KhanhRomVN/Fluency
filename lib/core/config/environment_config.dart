import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static Future<void> init() async {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    // Try to load .env first, then specialty env files
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
    try {
      final fileName = flavor == 'prod' ? '.env.prod' : '.env.dev';
      await dotenv.load(fileName: fileName, mergeWith: dotenv.env);
    } catch (_) {}
  }

  static String get apiUrl =>
      dotenv.env['API_URL'] ?? 'https://api.example.com';

  static String get appName => dotenv.env['APP_NAME'] ?? 'Template App';

  static List<String> get courseBaseUrls {
    final urls = dotenv.env['COURSE_BASE_URLS'] ?? '';
    if (urls.isEmpty) return [];
    return urls.split(',').map((u) => u.trim()).toList();
  }
}
