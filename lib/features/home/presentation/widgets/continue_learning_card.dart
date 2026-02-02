import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/presentation/widgets/course_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getRecentLearningData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120); // Placeholder height
        }

        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink(); // Hide if no history
        }

        final course = data['course'] as Course;
        final latestLessonTitle =
            data['lessonTitle'] as String? ?? 'Recent lesson';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Continue learning...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                context.push(
                  '${RouteConstants.course}/${RouteConstants.courseDetail}',
                  extra: course,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // Image Square
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CourseImage(imageUrl: course.imageUrl),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latestLessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Arrow Right
                  SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-right-icon lucide-chevron-right"><path d="m9 18 6-6-6-6"/></svg>',
                    colorFilter: ColorFilter.mode(
                      (Theme.of(context).iconTheme.color ?? Colors.black)
                          .withValues(alpha: 0.3),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Divider(height: 1),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getRecentLearningData() async {
    try {
      final activityRepo = sl<ActivityRepository>();
      final activities = await activityRepo.getActivities();

      // Find most recent learning activity with course metadata
      Activity? lastLearningActivity;
      for (final activity in activities) {
        if ((activity.type == ActivityType.completeQuiz ||
                activity.type == ActivityType.completeLesson) &&
            activity.metadata?.containsKey('courseId') == true) {
          lastLearningActivity = activity;
          break;
        }
      }

      // If no learning activity, check for most recent imported course
      if (lastLearningActivity == null) {
        for (final activity in activities) {
          if (activity.type == ActivityType.importCourse &&
              activity.metadata?.containsKey('courseId') == true) {
            lastLearningActivity = activity;
            break;
          }
        }
      }

      if (lastLearningActivity == null) {
        final courses = await CourseRepository().getCourses();
        if (courses.isNotEmpty) {
          return {
            'course': courses.first,
            'lessonTitle': courses.first.lessons.isNotEmpty
                ? courses.first.lessons.first.title
                : 'Start learning now',
          };
        }
        return null;
      }

      final courseId = lastLearningActivity.metadata!['courseId'] as String;
      final lessonTitle =
          lastLearningActivity.metadata!['lessonTitle'] as String?;

      // Fetch the full course object
      final courses = await CourseRepository().getCourses();
      final course = courses.cast<Course?>().firstWhere(
            (c) => c?.id == courseId,
            orElse: () => null,
          );

      if (course == null) {
        // Fallback to first course if the specific course ID is not found (maybe deleted)
        if (courses.isNotEmpty) {
          return {
            'course': courses.first,
            'lessonTitle': 'Continue from start',
          };
        }
        return null;
      }

      return {
        'course': course,
        'lessonTitle': lessonTitle ??
            (course.lessons.isNotEmpty
                ? course.lessons.first.title
                : 'Start learning now'),
      };
    } catch (e) {
      debugPrint('Error fetching recent learning data: $e');
      return null;
    }
  }
}
