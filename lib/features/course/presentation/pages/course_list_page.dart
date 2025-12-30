import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Example navigation to detail
            context.push('${RouteConstants.course}/detail');
            // Note: Router config will define 'detail' as sub-route
          },
          child: const Text('Go to Course Detail'),
        ),
      ),
    );
  }
}
