import 'package:package_info_plus/package_info_plus.dart';

/// Service for retrieving app information
class AppInfoService {
  PackageInfo? _packageInfo;

  /// Get app information
  Future<PackageInfo> getAppInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  /// Get app version string
  Future<String> getVersionString() async {
    final info = await getAppInfo();
    return '${info.version} (${info.buildNumber})';
  }

  /// Get app name
  Future<String> getAppName() async {
    final info = await getAppInfo();
    return info.appName;
  }

  /// Get package name
  Future<String> getPackageName() async {
    final info = await getAppInfo();
    return info.packageName;
  }
}
