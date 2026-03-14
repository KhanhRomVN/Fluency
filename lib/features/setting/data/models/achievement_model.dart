import 'package:flutter/material.dart';

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class AchievementLevel {
  final String title;
  final String desc;
  final double targetValue;
  final AchievementRarity rarity;

  const AchievementLevel({
    required this.title,
    required this.desc,
    required this.targetValue,
    required this.rarity,
  });
}

class Achievement {
  final String id;
  final IconData icon;
  final Color color;
  final List<AchievementLevel> levels;
  final int currentLevelIndex;
  final double currentValue; // Total value accumulated for this group
  final String? prerequisiteId;

  Achievement({
    required this.id,
    required this.icon,
    required this.color,
    required this.levels,
    this.currentLevelIndex = 0,
    this.currentValue = 0.0,
    this.prerequisiteId,
  });

  // Getters for current state
  AchievementLevel get currentLevel => levels[currentLevelIndex < levels.length
      ? currentLevelIndex
      : levels.length - 1];

  String get title => currentLevel.title;
  String get desc => currentLevel.desc;
  AchievementRarity get rarity => currentLevel.rarity;

  bool get isMaxLevel => currentLevelIndex >= levels.length - 1 && isCompleted;

  bool get isCompleted => currentValue >= currentLevel.targetValue;

  double get progress {
    if (currentLevelIndex >= levels.length) return 1.0;
    final target = currentLevel.targetValue;
    return (currentValue / target).clamp(0.0, 1.0);
  }

  Achievement copyWith({
    String? id,
    IconData? icon,
    Color? color,
    List<AchievementLevel>? levels,
    int? currentLevelIndex,
    double? currentValue,
    String? prerequisiteId,
  }) {
    return Achievement(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      levels: levels ?? this.levels,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      currentValue: currentValue ?? this.currentValue,
      prerequisiteId: prerequisiteId ?? this.prerequisiteId,
    );
  }
}
