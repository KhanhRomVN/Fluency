import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../../features/course/domain/entities/course.dart';
import '../../features/course/presentation/pages/course_detail_page.dart';
import '../../features/course/presentation/pages/course_list_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/setting/presentation/pages/setting_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorCourseKey =
    GlobalKey<NavigatorState>(debugLabel: 'course');
final _shellNavigatorCenterKey =
    GlobalKey<NavigatorState>(debugLabel: 'center');
final _shellNavigatorTempKey = GlobalKey<NavigatorState>(debugLabel: 'temp');
final _shellNavigatorSettingKey =
    GlobalKey<NavigatorState>(debugLabel: 'setting');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path:
            '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
        parentNavigatorKey: _rootNavigatorKey, // Ensure it covers the shell
        builder: (context, state) {
          final lesson = state.extra as Lesson;
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
                    routes: [],
                  ),
                ],
              ),
            ],
          ),
          // Center Button Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCenterKey,
            routes: [
              GoRoute(
                path: RouteConstants.center,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Center Page'))),
              ),
            ],
          ),
          // Temp Branch (No page yet)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTempKey,
            routes: [
              GoRoute(
                path: '/temp',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Temp Page'))),
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
