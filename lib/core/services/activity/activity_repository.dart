import 'package:fluency/core/services/activity/activity.dart';

abstract class ActivityRepository {
  Future<List<Activity>> getActivities();
  Future<void> logActivity(Activity activity);
  Future<void> clearActivities();
}
