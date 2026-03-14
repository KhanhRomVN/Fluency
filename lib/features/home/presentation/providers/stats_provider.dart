import 'package:flutter/material.dart';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/core/services/usage/daily_usage_repository.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:fluency/features/setting/presentation/providers/achievement_provider.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';

class StatsProvider extends ChangeNotifier {
  int _streak = 0;
  int _score = 0;
  int _cardsCount = 0;
  int _badgesCount = 0;

  int get streak => _streak;
  int get score => _score;
  int get cardsCount => _cardsCount;
  int get badgesCount => _badgesCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadStats(AchievementProvider achievementProvider) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Calculate Streak
      final usageRepo = sl<DailyUsageRepository>();
      _streak = _calculateStreak(usageRepo);

      // 2. Calculate Badges Count
      _badgesCount =
          achievementProvider.achievements.where((a) => a.isCompleted).length;

      // 3. Calculate Cards Count (Total terms across all collections)
      final collectionRepo = CollectionRepositoryImpl();
      final collections = await collectionRepo.getCollections();
      _cardsCount = collections.fold(
          0, (sum, collection) => sum + collection.terms.length);

      // 4. Calculate Score (Achievements + Activities)
      final activityRepo = sl<ActivityRepository>();
      final activities = await activityRepo.getActivities();
      _score = _calculateScore(activities, _badgesCount);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _calculateStreak(DailyUsageRepository repo) {
    int streak = 0;
    DateTime date = DateTime.now().toLocal();

    // Logic: If user learned today, streak starts from today.
    // If not, it checks if yesterday has activity (streak is still alive).
    bool hasActivityToday = repo.getMinutes(date) > 0;

    if (hasActivityToday) {
      streak++;
      date = date.subtract(const Duration(days: 1));
      while (repo.getMinutes(date) > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    } else {
      // Check yesterday to see if the streak is still alive
      date = date.subtract(const Duration(days: 1));
      while (repo.getMinutes(date) > 0) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  int _calculateScore(List<Activity> activities, int completedAchievements) {
    // 100 points per completed achievement
    int score = completedAchievements * 100;

    for (final activity in activities) {
      if (activity.type == ActivityType.completeQuiz) {
        score += 10;
      } else if (activity.type == ActivityType.completeLesson) {
        score += 20;
      } else if (activity.type == ActivityType.addTerm) {
        score += 5;
      }
    }

    return score;
  }
}
