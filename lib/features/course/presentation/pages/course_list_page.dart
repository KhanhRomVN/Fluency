import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../data/fake_course_data.dart';
import '../widgets/course_card.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing fake data
    final courses = FakeCourseData.courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar & Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    hintText: 'Search courses...',
                    leading: const Icon(Icons.search),
                    elevation: MaterialStateProperty.all(1.0),
                    onChanged: (value) {
                      // TODO: Implement search logic
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // TODO: Implement filter logic
                  },
                  icon: const Icon(Icons.filter_list),
                  style: IconButton.styleFrom(
                      // backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Course List
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  onTap: () {
                    context.push(
                      '${RouteConstants.course}/detail',
                      extra: course, // Passing the course object
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
