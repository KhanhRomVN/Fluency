import 'package:flutter/material.dart';
import 'package:fluency/features/setting/data/models/achievement_model.dart';

class AchievementProvider extends ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(
      id: 'vocab',
      icon: Icons.school,
      color: Colors.amber[400]!,
      levels: const [
        AchievementLevel(
          title: 'Vocab Novice',
          desc: 'Learn 10 new words',
          targetValue: 10,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Vocab Apprentice',
          desc: 'Learn 50 new words',
          targetValue: 50,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Vocab Master',
          desc: 'Learn 100 new words',
          targetValue: 100,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
    ),
    Achievement(
      id: 'streak',
      icon: Icons.local_fire_department,
      color: Colors.orange[400]!,
      levels: const [
        AchievementLevel(
          title: 'First Flame',
          desc: 'Learn for 3 days in a row',
          targetValue: 3,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Hot Streak',
          desc: 'Learn for 7 days in a row',
          targetValue: 7,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Inferno',
          desc: 'Learn for 30 days in a row',
          targetValue: 30,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
      prerequisiteId: 'vocab',
    ),
    Achievement(
      id: 'lessons',
      icon: Icons.auto_stories,
      color: Colors.blue[400]!,
      levels: const [
        AchievementLevel(
          title: 'Bookworm',
          desc: 'Complete 5 lessons',
          targetValue: 5,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Scholar',
          desc: 'Complete 20 lessons',
          targetValue: 20,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Sage',
          desc: 'Complete 50 lessons',
          targetValue: 50,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
    ),
    Achievement(
      id: 'perfection',
      icon: Icons.verified_rounded,
      color: Colors.green[400]!,
      levels: const [
        AchievementLevel(
          title: 'First Perfection',
          desc: 'Get 100% on a lesson',
          targetValue: 1,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Flawless',
          desc: 'Get 100% on 10 lessons',
          targetValue: 10,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Untouchable',
          desc: 'Get 100% on 50 lessons',
          targetValue: 50,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
      prerequisiteId: 'lessons',
    ),
    Achievement(
      id: 'social',
      icon: Icons.share_rounded,
      color: Colors.lightBlue[300]!,
      levels: const [
        AchievementLevel(
          title: 'Sharer',
          desc: 'Share your progress once',
          targetValue: 1,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Influencer',
          desc: 'Share your progress 10 times',
          targetValue: 10,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Icon',
          desc: 'Share your progress 50 times',
          targetValue: 50,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
    ),
    Achievement(
      id: 'night_owl',
      icon: Icons.dark_mode_rounded,
      color: Colors.indigo[400]!,
      levels: const [
        AchievementLevel(
          title: 'Moonlight Learner',
          desc: 'Study after 10 PM 3 times',
          targetValue: 3,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Midnight Oil',
          desc: 'Study after 10 PM 15 times',
          targetValue: 15,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Starry Eyes',
          desc: 'Study after 10 PM 50 times',
          targetValue: 50,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
    ),
    Achievement(
      id: 'early_bird',
      icon: Icons.wb_sunny_rounded,
      color: Colors.yellow[600]!,
      levels: const [
        AchievementLevel(
          title: 'Dawn Patrol',
          desc: 'Study before 7 AM 3 times',
          targetValue: 3,
          rarity: AchievementRarity.common,
        ),
        AchievementLevel(
          title: 'Sunrise Sage',
          desc: 'Study before 7 AM 15 times',
          targetValue: 15,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Morning Glory',
          desc: 'Study before 7 AM 50 times',
          targetValue: 50,
          rarity: AchievementRarity.epic,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
    ),
    Achievement(
      id: 'speed',
      icon: Icons.speed_rounded,
      color: Colors.red[400]!,
      levels: const [
        AchievementLevel(
          title: 'Quick Wit',
          desc: 'Complete a lesson in under 2 mins',
          targetValue: 1,
          rarity: AchievementRarity.rare,
        ),
        AchievementLevel(
          title: 'Sonic',
          desc: 'Complete 10 lessons in under 2 mins',
          targetValue: 10,
          rarity: AchievementRarity.epic,
        ),
        AchievementLevel(
          title: 'Godspeed',
          desc: 'Complete 50 lessons in under 2 mins',
          targetValue: 50,
          rarity: AchievementRarity.legendary,
        ),
      ],
      currentValue: 0,
      currentLevelIndex: 0,
      prerequisiteId: 'lessons',
    ),
  ];

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  List<Achievement> get sortedAchievements {
    final list = List<Achievement>.from(_achievements);
    // Sort logic: Locked groups last, then by level progress?
    // For now, keep current sorting logic or group them.
    return list;
  }

  void updateProgress(String id, double value) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final group = _achievements[index];
      double newValue = group.currentValue + value;
      int newLevelIndex = group.currentLevelIndex;

      // Check if leveled up
      while (newLevelIndex < group.levels.length &&
          newValue >= group.levels[newLevelIndex].targetValue) {
        if (newLevelIndex < group.levels.length - 1) {
          // Stay at current value but increment level?
          // Usually currentValue is global.
          newLevelIndex++;
        } else {
          break;
        }
      }

      _achievements[index] = group.copyWith(
        currentValue: newValue,
        currentLevelIndex: newLevelIndex,
      );
      notifyListeners();
    }
  }
}
