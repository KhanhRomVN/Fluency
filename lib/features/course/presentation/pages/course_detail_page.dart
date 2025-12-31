import 'package:flutter/material.dart';
import '../../domain/entities/course.dart';
import '../../data/fake_course_data.dart';

class CourseDetailPage extends StatelessWidget {
  final Course? course;

  const CourseDetailPage({super.key, this.course});

  @override
  Widget build(BuildContext context) {
    // Fallback to fake data if course is null (e.g. direct navigation for dev)
    final displayCourse = course ?? FakeCourseData.hackerToeicListening;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, displayCourse),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(context, displayCourse),
                  const SizedBox(height: 24),
                  _buildDetailedInfo(context, displayCourse),
                  const SizedBox(height: 24),
                  _buildDescription(context, displayCourse),
                  const SizedBox(height: 24),
                  _buildLessonList(context, displayCourse),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey, child: const Icon(Icons.error)),
            ),
            // Gradient for better text visibility (optional, but good for UI)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.school, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              course.skill.join(', '),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(BuildContext context, Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Author', course.author),
          const Divider(),
          _buildInfoRow(context, 'Translator', course.translator),
          const Divider(),
          _buildInfoRow(context, 'Adapter', course.adapter),
          const Divider(),
          _buildInfoRow(context, 'Publisher', course.publisher),
          const Divider(),
          _buildInfoRow(context, 'Year', course.publicationYear.toString()),
          const Divider(),
          _buildInfoRow(context, 'Pages', course.pageCount.toString()),
          const Divider(),
          _buildInfoRow(context, 'Target', course.targetAudience),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this course',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          course.fullDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildLessonList(BuildContext context, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Syllabus',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: course.lessons.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final lesson = course.lessons[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${lesson.lessonNumber}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: lesson.description.isNotEmpty
                  ? Text(
                      lesson.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                // Navigate to lesson or quiz
                // context.push('${RouteConstants.course}/detail/${RouteConstants.quiz}');
              },
            );
          },
        ),
      ],
    );
  }
}
