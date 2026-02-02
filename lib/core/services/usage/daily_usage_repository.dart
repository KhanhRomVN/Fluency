import 'package:shared_preferences/shared_preferences.dart';

class DailyUsageRepository {
  final SharedPreferences _prefs;
  static const String _usagePrefix = 'app_usage_';

  DailyUsageRepository(this._prefs);

  String _getKey(DateTime date) {
    return '$_usagePrefix${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> addMinutes(int minutes) async {
    final now = DateTime.now();
    final key = _getKey(now);
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + minutes);
  }

  int getMinutes(DateTime date) {
    return _prefs.getInt(_getKey(date)) ?? 0;
  }

  List<int> getLast7DaysMinutes() {
    final results = <int>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      results.add(getMinutes(date));
    }
    return results;
  }
}
