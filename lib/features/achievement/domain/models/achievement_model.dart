import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final double progress;
  final bool isCompleted;

  Achievement({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? desc,
    IconData? icon,
    Color? color,
    double? progress,
    bool? isCompleted,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
