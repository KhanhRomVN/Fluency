import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({
    required this.lesson,
    required this.isCompleted,
    required this.isLocked,
    this.onTap,
    super.key,
  });

  final Lesson lesson;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            // Left: Square Badge (Reduced size to 28x28)
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCompleted
                    ? appColors.primary
                    : (isLocked
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.transparent), // Transparent for unlocked
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted
                      ? appColors.primary
                      : (isLocked
                          ? Colors.grey.withValues(alpha: 0.3)
                          : appColors.primary),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${lesson.lessonNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced font size
                      color: isCompleted
                          ? Colors.white
                          : (isLocked ? Colors.grey : appColors.primary),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            // Right: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? appColors.textSecondary
                              : appColors.textPrimary,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 6),
                  // Row 2: Quiz Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withValues(alpha: 0.1)
                          : appColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${lesson.quizCount} Quizzes',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isLocked ? Colors.grey : appColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
