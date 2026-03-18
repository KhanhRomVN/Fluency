import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class QuizResumeDrawer extends StatelessWidget {
  const QuizResumeDrawer({
    required this.lessonTitle,
    required this.quizzes,
    required this.progressData,
    required this.onContinue,
    required this.onReset,
    required this.overallPercentage,
    required this.totalQuestions,
    super.key,
  });

  final String lessonTitle;
  final List<Quiz> quizzes;
  final Map<String, QuizProgress> progressData;
  final VoidCallback onContinue;
  final VoidCallback onReset;
  final double overallPercentage;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    // Calculate completed questions
    int totalCompleted = 0;
    DateTime? lastUpdate;

    for (final progress in progressData.values) {
      totalCompleted += progress.completedItems;
      if (lastUpdate == null || progress.timestamp.isAfter(lastUpdate)) {
        lastUpdate = progress.timestamp;
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume Quiz?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'You left off here last time',
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: appColors.inputBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson title
                  Text(
                    lessonTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: appColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Overall progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Progress',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: appColors.textSecondary,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${overallPercentage.round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: appColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: appColors.border.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Questions Done',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: appColors.textSecondary,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCompleted/$totalQuestions',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: appColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Last update time
                  if (lastUpdate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: appColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last updated: ${_formatTime(lastUpdate)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: appColors.textSecondary,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quiz details
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: progressData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final progress = progressData[quiz.id];
                return _buildQuizProgressItem(
                    context, quiz, progress, appColors);
              },
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: appColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Restart',
                      style: TextStyle(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: appColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizProgressItem(
    BuildContext context,
    Quiz quiz,
    QuizProgress? progress,
    AppColorsExtension appColors,
  ) {
    final String typeLabel;
    final Color typeColor;

    switch (quiz.type) {
      case 'multiple-choice':
        typeLabel = 'MULTIPLE CHOICE';
        typeColor = Colors.blue;
      case 'gap-fill-typing':
        typeLabel = 'GAP FILL';
        typeColor = Colors.green;
      case 'gap-fill-dropdown':
        typeLabel = 'GAP FILL';
        typeColor = Colors.lightGreen;
      case 'matching-dropdown':
        typeLabel = 'MATCHING';
        typeColor = Colors.purple;
      case 'writing-essay':
        typeLabel = 'WRITING';
        typeColor = Colors.orange;
      case 'speaking-essay':
        typeLabel = 'SPEAKING';
        typeColor = Colors.pink;
      case 'free-chat':
        typeLabel = 'FREE CHAT';
        typeColor = Colors.cyan;
      case 'scripted-chat':
        typeLabel = 'SCRIPTED CHAT';
        typeColor = Colors.blueAccent;
      case 'pronunciation-drill':
        typeLabel = 'PRONUNCIATION';
        typeColor = Colors.teal;
      case 'dictation':
      case 'dictation-audio':
        typeLabel = 'DICTATION';
        typeColor = Colors.pink;
      case 'builder':
        typeLabel = 'BUILDER';
        typeColor = Colors.amber;
      case 'sentence-transformation':
        typeLabel = 'TRANSFORMATION';
        typeColor = Colors.deepOrange;
      case 'error-correction':
        typeLabel = 'ERROR CORRECTION';
        typeColor = Colors.redAccent;
      case 'flashcard':
        typeLabel = 'FLASHCARD';
        typeColor = Colors.indigo;
      default:
        typeLabel = 'QUIZ';
        typeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Quiz title
                Text(
                  quiz.title.isNotEmpty
                      ? quiz.title
                      : quiz.question.isNotEmpty
                          ? quiz.question
                          : 'Untitled Question',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Progress Circle
          if (progress != null)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: progress.completedItems / progress.totalItems,
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    color: Colors.redAccent,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: progress.correctItems / progress.totalItems,
                    backgroundColor: Colors.transparent,
                    color: Colors.green,
                    strokeWidth: 2.5,
                  ),
                ),
                Text(
                  '${progress.progressPercentage.round()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                        fontSize: 9,
                      ),
                ),
              ],
            )
          else
            // No progress yet
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '0%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
