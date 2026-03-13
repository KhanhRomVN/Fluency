import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/features/collection/presentation/pages/collection_page.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/presentation/pages/course_detail_page.dart';
import 'package:fluency/features/course/presentation/pages/course_list_page.dart';
import 'package:fluency/features/error/presentation/pages/not_found_page.dart';
import 'package:fluency/features/home/presentation/pages/home_page.dart';
import 'package:fluency/features/main/presentation/pages/main_page.dart';
import 'package:fluency/features/quiz/presentation/pages/quiz_page.dart';
import 'package:fluency/features/setting/presentation/pages/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorCourseKey =
    GlobalKey<NavigatorState>(debugLabel: 'course');

final _shellNavigatorTempKey = GlobalKey<NavigatorState>(debugLabel: 'temp');
final _shellNavigatorSettingKey =
    GlobalKey<NavigatorState>(debugLabel: 'setting');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.dashboard,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: RouteConstants.home,
        redirect: (context, state) => RouteConstants.dashboard,
      ),
      GoRoute(
        path:
            '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
        parentNavigatorKey: _rootNavigatorKey, // Ensure it covers the shell
        builder: (context, state) {
          final lesson = state.extra! as Lesson;
          return QuizPage(lesson: lesson);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainPage(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: RouteConstants.dashboard,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // Course Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCourseKey,
            routes: [
              GoRoute(
                path: RouteConstants.course,
                builder: (context, state) => const CourseListPage(),
                routes: [
                  GoRoute(
                    path: RouteConstants.courseDetail,
                    builder: (context, state) {
                      final course = state.extra as Course?;
                      return CourseDetailPage(course: course);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Collection Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTempKey,
            routes: [
              GoRoute(
                path: RouteConstants.collection,
                builder: (context, state) => const CollectionPage(),
              ),
            ],
          ),

          // Setting Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingKey,
            routes: [
              GoRoute(
                path: RouteConstants.setting,
                builder: (context, state) => const SettingPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
