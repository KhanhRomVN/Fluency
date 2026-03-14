import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/presentation/widgets/course_image.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.course,
    required this.onTap,
    super.key,
  });

  final Course course;
  final VoidCallback onTap;

  void _showActionDrawer(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: appColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: appColors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Course Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, appColors);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete Course',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppColorsExtension appColors) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appColors.background,
        title: Text('Delete Course',
            style: TextStyle(color: appColors.textPrimary)),
        content: Text('Are you sure you want to delete "${course.title}"?',
            style: TextStyle(color: appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<CourseProvider>().deleteCourse(course);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 90,
                  child: Stack(
                    children: [
                      CourseImage(
                        imageUrl: course.imageUrl,
                        height: 90,
                        fit: BoxFit.fitHeight,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            'v${course.version}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Course Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.skill.isNotEmpty) ...[
                      _buildSkillBadges(context),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    _buildProgressBar(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillBadges(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: course.skill.map((skill) {
          final color = _getSkillColor(skill);
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4), width: 1.2),
            ),
            child: Text(
              skill,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
      case 'listen':
        return Colors.red;
      case 'speaking':
      case 'speak':
        return Colors.orange;
      case 'reading':
      case 'read':
        return Colors.green;
      case 'writing':
      case 'write':
        return Colors.blue;
      case 'grammar':
        return Colors.purple;
      case 'vocabulary':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  int _calculateTotalScore(BuildContext context) {
    final quizStateProvider = context.watch<QuizStateProvider>();
    int totalScore = 0;
    for (final lesson in course.lessons) {
      final lessonProgress = quizStateProvider.getLessonProgress(lesson.id);
      if (lessonProgress != null) {
        for (final progress in lessonProgress.values) {
          totalScore += progress.correctItems;
        }
      }
    }
    return totalScore;
  }

  Widget _buildProgressBar(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    // Calculate real progress from all lessons
    final quizStateProvider = context.watch<QuizStateProvider>();
    int totalCompleted = 0;
    int totalCorrect = 0;
    int totalCourseItems = 0;

    for (final lesson in course.lessons) {
      final lessonProgress = quizStateProvider.getLessonProgress(lesson.id);
      if (lessonProgress != null) {
        for (final progress in lessonProgress.values) {
          totalCompleted += progress.completedItems;
          totalCorrect += progress.correctItems;
        }
      }
      totalCourseItems += lesson.totalItems;
    }

    final int wrong = totalCompleted - totalCorrect;
    final int averageProgress = totalCourseItems > 0
        ? (totalCompleted / totalCourseItems * 100).round().clamp(0, 100)
        : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildInfoRow(
                  context,
                  'assets/icons/lesson.svg',
                  '${course.lessons.length} lessons',
                ),
                const SizedBox(width: 8),
                _buildInfoMetric(
                  context,
                  Icons.emoji_events_outlined,
                  '${_calculateTotalScore(context)}pts',
                ),
              ],
            ),
            Text(
              '$averageProgress%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _SegmentedProgressBar(
          correct: totalCorrect,
          wrong: wrong > 0 ? wrong : 0,
          total: totalCourseItems > 0 ? totalCourseItems : 1,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String iconAsset, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(
            Theme.of(context).extension<AppColorsExtension>()?.textSecondary ??
                Colors.grey[500]!,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .extension<AppColorsExtension>()
                      ?.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMetric(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context)
                  .extension<AppColorsExtension>()
                  ?.textSecondary ??
              Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .extension<AppColorsExtension>()
                      ?.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final int correct;
  final int wrong;
  final int total;

  const _SegmentedProgressBar({
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final int remaining = total - correct - wrong;
    final int safeRemaining = remaining > 0 ? remaining : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: Row(
          children: [
            if (correct > 0)
              Expanded(
                flex: correct,
                child: Container(
                  color: const Color(0xFF22C55E), // Match Home Page Green
                ),
              ),
            if (wrong > 0)
              Expanded(
                flex: wrong,
                child: Container(
                  color: const Color(0xFFEF4444), // Match Home Page Red style
                ),
              ),
            if (safeRemaining > 0)
              Expanded(
                flex: safeRemaining,
                child: Container(
                  color: Colors.blue[400]!.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
