import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuizDrawer extends StatelessWidget {
  const QuizDrawer({
    super.key,
    required this.lesson,
    required this.activeQuizIndex,
    required this.onQuizSelected,
  });

  final Lesson lesson;
  final int activeQuizIndex;
  final ValueChanged<int> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: appColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: appColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Question List',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'icons/x.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        appColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quiz List
          Expanded(
            child: Container(
              color: appColors.inputBackground.withValues(alpha: 0.3),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: lesson.quizzes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quiz = lesson.quizzes[index];
                  final isActive = index == activeQuizIndex;
                  final isCompleted = index % 3 == 0; // Mock data
                  final isInProgress = index % 3 == 1; // Mock data

                  return InkWell(
                    onTap: () {
                      onQuizSelected(index);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? appColors.background
                            : appColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? appColors.primary
                              : appColors.border.withValues(alpha: 0.5),
                          width: isActive ? 1 : 0.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      appColors.primary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Active indicator
                          if (isActive)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: appColors.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Type and status badges
                                Row(
                                  children: [
                                    // Type badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: quiz.type
                                                .contains('multiple-choice')
                                            ? Colors.purple
                                                .withValues(alpha: 0.1)
                                            : Colors.blue
                                                .withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: quiz.type
                                                  .contains('multiple-choice')
                                              ? Colors.purple.shade200
                                              : Colors.blue.shade200,
                                          width: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        quiz.type.contains('multiple-choice')
                                            ? 'MULTIPLE CHOICE'
                                            : quiz.type == 'matching-dropdown'
                                                ? 'MATCHING'
                                                : 'GAP FILL',
                                        style: TextStyle(
                                          color: quiz.type
                                                  .contains('multiple-choice')
                                              ? Colors.purple.shade700
                                              : Colors.blue.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Status badge
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 10,
                                              color: Colors.green.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Done',
                                              style: TextStyle(
                                                color: Colors.green.shade600,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (isInProgress)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Colors.amber.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'In Progress',
                                              style: TextStyle(
                                                color: Colors.amber.shade600,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Title
                                Text(
                                  '${index + 1}. ${quiz.title.isNotEmpty ? quiz.title : quiz.question.isNotEmpty ? quiz.question : 'Untitled Question'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: isActive
                                            ? appColors.primary
                                            : appColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Time and score info
                                Row(
                                  children: [
                                    if (isCompleted || isInProgress) ...[
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: isInProgress
                                            ? Colors.amber.shade600
                                            : appColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCompleted ? '12:30' : '05:45',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: appColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    if (isCompleted) ...[
                                      Icon(
                                        Icons.emoji_events,
                                        size: 14,
                                        color: Colors.amber.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${85 + (index % 15)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: appColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if (!isCompleted && !isInProgress) ...[
                                      Icon(
                                        Icons.help_outline,
                                        size: 14,
                                        color: appColors.textSecondary
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '- - : - -',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: appColors.textSecondary
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
