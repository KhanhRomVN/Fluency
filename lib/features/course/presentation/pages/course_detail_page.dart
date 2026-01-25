import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/presentation/widgets/course_image.dart';
import 'package:fluency/features/course/presentation/widgets/lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, this.course});

  final Course? course;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  Course? _course;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _course = widget.course;
      _isLoading = false;
    } else {
      _loadCourse();
    }
  }

  Future<void> _loadCourse() async {
    try {
      final repository = CourseRepository();
      final courses = await repository.getCourses();
      if (courses.isNotEmpty) {
        if (mounted) {
          setState(() {
            _course = courses.first; // Default to first course for dev
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No courses found.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading course: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: appColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _course == null) {
      return Scaffold(
        backgroundColor: appColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: appColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? 'Course not found',
            style: TextStyle(color: appColors.textPrimary),
          ),
        ),
      );
    }

    final displayCourse = _course!;

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Header with 'Course' title and Badge
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Course',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: appColors.textPrimary,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 2. Centered Image (50% screen width)
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CourseImage(
                    imageUrl: displayCourse.imageUrl,
                  ),
                ),
              ),
            ),
            // 3. Centered Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  displayCourse.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                        height: 1.3,
                      ),
                ),
              ),
            ),
            // 4. Centered Skill Badge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayCourse.skill.map((String skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                const Color(0xFF2196F3).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          skill,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF2196F3),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // 5. Info Section Label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                ),
              ),
            ),
            // Info Section Content
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildDetailedInfo(context, displayCourse, appColors),
              ),
            ),
            // 6. About this course (Reduced size)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'About this course',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, // Reduced from Large
                            color: appColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayCourse.fullDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: appColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // 7. Lessons Header (Renamed from Detail Syllabus)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Lessons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                ),
              ),
            ),
            // 8. Lesson List (New Card Design)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final itemIndex = index ~/ 2;
                    if (index.isOdd) {
                      return Divider(
                        color: appColors.border.withValues(alpha: 0.3),
                        height: 1,
                      );
                    }

                    final lesson = displayCourse.lessons[itemIndex];
                    final isCompleted =
                        itemIndex < displayCourse.completedLessons;
                    const isLocked = false; // Always unlocked for now

                    return LessonCard(
                      lesson: lesson,
                      isCompleted: isCompleted,
                      isLocked: isLocked,
                      onTap: () {
                        context.push(
                          '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
                          extra: lesson,
                        );
                      },
                    );
                  },
                  childCount: displayCourse.lessons.length * 2 - 1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfo(
    BuildContext context,
    Course course,
    AppColorsExtension appColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Author', course.author, appColors),
          _buildDivider(appColors),
          _buildInfoRow(context, 'Translator', course.translator, appColors),
          _buildDivider(appColors),
          _buildInfoRow(context, 'Adapter', course.adapter, appColors),
          _buildDivider(appColors),
          _buildInfoRow(context, 'Publisher', course.publisher, appColors),
          _buildDivider(appColors),
          _buildInfoRow(
            context,
            'Year',
            course.publicationYear.toString(),
            appColors,
          ),
          _buildDivider(appColors),
          _buildInfoRow(
            context,
            'Pages',
            course.pageCount.toString(),
            appColors,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColorsExtension appColors) {
    return Divider(
      height: 24,
      color: appColors.divider.withValues(alpha: 0.5),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    AppColorsExtension appColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.textSecondary,
              ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
