import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final primaryColor = appColors.primary;

    // Calculate details
    final skills = _getSkillsList();
    final maxScore = lesson.quizzes.length * 10;

    // Get progress from QuizStateProvider
    final quizStateProvider = context.watch<QuizStateProvider>();
    final progressPercentage = quizStateProvider.getLessonProgressPercentage(
      lesson.id,
      lesson.quizzes.length,
    );
    final progress = progressPercentage / 100;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Left: Square Badge
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCompleted
                    ? primaryColor
                    : appColors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isCompleted ? primaryColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                '${lesson.lessonNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isCompleted
                          ? Colors.white
                          : appColors.textPrimary.withValues(alpha: 0.4),
                    ),
              ),
            ),
            const SizedBox(width: 16),

            // Middle: Lesson Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 4),
                  // Skills and Score info
                  Text(
                    '${skills.join(' • ')}  |  Max Score: $maxScore',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right: Progress Circle with Percentage
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    color: primaryColor,
                    strokeWidth: 2.5,
                  ),
                ),
                Text(
                  '${progressPercentage.round()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progress > 0 ? primaryColor : Colors.grey,
                        fontSize: 9,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getSkillsList() {
    final Set<String> skills = {};
    for (final quiz in lesson.quizzes) {
      final type = quiz.type.toLowerCase();

      // Listening: Has audio
      if (quiz.audio != null && quiz.audio!.isNotEmpty) {
        skills.add('Listen');
      }

      // Reading: Has passage or specific types
      if ((quiz.passage != null && quiz.passage!.isNotEmpty) ||
          type == 'flashcard' ||
          type == 'reading') {
        skills.add('Read');
      }

      // Speaking: Pronunciation or speech builder
      if (type == 'pronunciation' ||
          type == 'pronunciation-drill' ||
          type == 'speech-builder') {
        skills.add('Speak');
      }

      // Writing: Dictation, transformation, error correction
      if (type == 'dictation' ||
          type == 'sentence-transformation' ||
          type == 'error-correction' ||
          type == 'writing') {
        skills.add('Write');
      }
    }

    // Default or fallback
    if (skills.isEmpty) return ['Vocabulary'];

    return skills.toList();
  }
}
