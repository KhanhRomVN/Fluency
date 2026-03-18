import 'dart:math';
import 'package:fluency/core/config/environment_config.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  static List<String> get courseBaseUrls => EnvironmentConfig.courseBaseUrls;

  static String get randomCourseBaseUrl {
    final random = Random();
    return courseBaseUrls[random.nextInt(courseBaseUrls.length)];
  }
}
