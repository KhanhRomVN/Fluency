import 'dart:convert';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  static const String _activitiesKey = 'user_activities';
  final SharedPreferences _prefs;

  ActivityRepositoryImpl(this._prefs);

  @override
  Future<List<Activity>> getActivities() async {
    final jsonString = _prefs.getString(_activitiesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort(
            (a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> logActivity(Activity activity) async {
    final activities = await getActivities();
    activities.insert(0, activity); // Add to the beginning

    // Limit to last 50 activities for performance (reduced from 100 as it's a small part)
    if (activities.length > 50) {
      activities.removeRange(50, activities.length);
    }

    final jsonList = activities.map((a) => a.toJson()).toList();
    await _prefs.setString(_activitiesKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clearActivities() async {
    await _prefs.remove(_activitiesKey);
  }
}
