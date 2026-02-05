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
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image (Square Ratio)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CourseImage(
                        imageUrl: course.imageUrl,
                        width: 100,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.textPrimary,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.shortDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .extension<AppColorsExtension>()
                                  ?.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Time & Completed Lessons
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.textSecondary ??
                                Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '12h 30m',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .extension<AppColorsExtension>()
                                          ?.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 16),
                          _buildInfoRow(
                            context,
                            'assets/icons/lesson.svg',
                            '${course.completedLessons}/${course.lessons.length} lessons',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar (Fake Data)
                      _buildProgressBar(context),
                    ],
                  ),
                ),
                // Menu Icon
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context)
                        .extension<AppColorsExtension>()
                        ?.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _showActionDrawer(context),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final primaryColor =
        Theme.of(context).extension<AppColorsExtension>()?.primary ??
            Theme.of(context).primaryColor;

    // Calculate real progress from all lessons
    final quizStateProvider = context.watch<QuizStateProvider>();
    double totalProgress = 0.0;
    int lessonCount = 0;

    for (final lesson in course.lessons) {
      final lessonProgress = quizStateProvider.getLessonProgressPercentage(
        lesson.id,
        lesson.quizzes.length,
      );
      totalProgress += lessonProgress;
      lessonCount++;
    }

    final averageProgress = lessonCount > 0 ? totalProgress / lessonCount : 0.0;
    final progress = averageProgress / 100;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${averageProgress.round()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .extension<AppColorsExtension>()
                    ?.textPrimary,
                fontWeight: FontWeight.bold,
              ),
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
}
