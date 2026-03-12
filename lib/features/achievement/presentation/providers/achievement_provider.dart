import 'package:flutter/material.dart';
import 'package:fluency/features/achievement/domain/models/achievement_model.dart';

class AchievementProvider extends ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_steps',
      title: 'First Steps',
      desc: 'Complete your first lesson',
      icon: Icons.flag,
      color: Colors.blue[400]!,
      progress: 1.0,
      isCompleted: true,
    ),
    Achievement(
      id: 'streak_7',
      title: '7 Day Streak',
      desc: 'Learn for 7 days in a row',
      icon: Icons.local_fire_department,
      color: Colors.orange[400]!,
      progress: 1.0,
      isCompleted: true,
    ),
    Achievement(
      id: 'vocab_100',
      title: 'Vocab Master',
      desc: 'Learn 100 new words',
      icon: Icons.school,
      color: Colors.amber[400]!,
      progress: 0.65,
      isCompleted: false,
    ),
    Achievement(
      id: 'grammar_l1',
      title: 'Grammar Guru',
      desc: 'Complete all level 1 grammar lessons',
      icon: Icons.auto_stories,
      color: Colors.green[400]!,
      progress: 0.3,
      isCompleted: false,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      desc: 'No missed days for a full week',
      icon: Icons.calendar_month,
      color: Colors.purple[400]!,
      progress: 0.0,
      isCompleted: false,
    ),
    Achievement(
      id: 'polyglot',
      title: 'Polyglot',
      desc: 'Learn phrases in 3 different languages',
      icon: Icons.translate,
      color: Colors.teal[400]!,
      progress: 0.5,
      isCompleted: false,
    ),
    Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      desc: 'Complete a lesson after 10 PM',
      icon: Icons.dark_mode,
      color: Colors.indigo[400]!,
      progress: 0.0,
      isCompleted: false,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      desc: 'Complete a lesson before 7 AM',
      icon: Icons.wb_sunny,
      color: Colors.yellow[600]!,
      progress: 0.0,
      isCompleted: false,
    ),
    Achievement(
      id: 'speed_learner',
      title: 'Speed Learner',
      desc: 'Complete 3 lessons in one day',
      icon: Icons.speed,
      color: Colors.red[400]!,
      progress: 1.0,
      isCompleted: true,
    ),
    Achievement(
      id: 'social_butterfly',
      title: 'Social Butterfly',
      desc: 'Share your progress on social media',
      icon: Icons.share,
      color: Colors.lightBlue[300]!,
      progress: 0.0,
      isCompleted: false,
    ),
  ];

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  List<Achievement> get sortedAchievements {
    final list = List<Achievement>.from(_achievements);
    list.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });
    return list;
  }

  void updateProgress(String id, double progress) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final achievement = _achievements[index];
      _achievements[index] = achievement.copyWith(
        progress: progress,
        isCompleted: progress >= 1.0,
      );
      notifyListeners();
    }
  }
}
