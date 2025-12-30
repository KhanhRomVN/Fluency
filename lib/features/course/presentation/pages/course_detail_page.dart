import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Course Detail & Lessons'),
            ElevatedButton(
              onPressed: () {
                // Navigate to Quiz (sibling or sub-route)
                // Assuming quiz is at /course/detail/quiz for now or just /quiz
                // User asked: "when choosing a lesson in course -> move here to do quiz"
                context.push(
                    '${RouteConstants.course}/detail/${RouteConstants.quiz}');
              },
              child: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
