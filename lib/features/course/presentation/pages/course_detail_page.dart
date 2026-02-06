import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/presentation/widgets/course_image.dart';
import 'package:fluency/features/course/presentation/widgets/lesson_card.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_resume_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';

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

    // Sort lessons by ID (numerically if possible)
    final sortedLessons = List<Lesson>.from(displayCourse.lessons)
      ..sort((a, b) {
        final idA = int.tryParse(a.id);
        final idB = int.tryParse(b.id);
        if (idA != null && idB != null) {
          return idA.compareTo(idB);
        }
        return a.id.compareTo(b.id);
      });

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Header with 'Course' title and Badge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back Button on the far left
                    Positioned(
                      left: 4,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: SvgPicture.asset(
                          'assets/icons/chevron_left.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            appColors.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    // Centered Title and Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Courses',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                    // Menu Icon on the far right
                    Positioned(
                      right: 4,
                      child: IconButton(
                        onPressed: () => _showActionDrawer(context, appColors),
                        icon: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-ellipsis-vertical-icon lucide-ellipsis-vertical"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            appColors.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
            // 5. Info Section Label
            if (displayCourse.author.isNotEmpty ||
                displayCourse.adapter.isNotEmpty ||
                displayCourse.publisher.isNotEmpty ||
                displayCourse.publicationYear > 0 ||
                displayCourse.skill.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
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
            ],
            // 6. About this course (Reduced size)
            if (displayCourse.fullDescription.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'About this course',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final itemIndex = index ~/ 2;
                    if (index.isOdd) {
                      return Divider(
                        color: appColors.border.withValues(alpha: 0.1),
                        height: 1,
                        indent: 60,
                        endIndent: 8,
                      );
                    }

                    final lesson = sortedLessons[itemIndex];
                    final isCompleted =
                        itemIndex < displayCourse.completedLessons;
                    const isLocked = false; // Always unlocked for now

                    return LessonCard(
                      lesson: lesson,
                      isCompleted: isCompleted,
                      isLocked: isLocked,
                      onTap: () => _handleLessonTap(context, lesson),
                    );
                  },
                  childCount: sortedLessons.length * 2 - 1,
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
    final infoItems = <Widget>[];

    if (course.author.isNotEmpty) {
      infoItems.add(_buildInfoRow(context, 'Author', course.author, appColors));
    }

    if (course.adapter.isNotEmpty) {
      infoItems
          .add(_buildInfoRow(context, 'Adapter', course.adapter, appColors));
    }

    if (course.publisher.isNotEmpty) {
      infoItems.add(
          _buildInfoRow(context, 'Publisher', course.publisher, appColors));
    }

    if (course.publicationYear > 0) {
      infoItems.add(_buildInfoRow(
        context,
        'Year',
        course.publicationYear.toString(),
        appColors,
      ));
    }

    if (course.skill.isNotEmpty) {
      infoItems.add(_buildSkillRow(context, 'Skill', course.skill, appColors));
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < infoItems.length; i++) {
      children.add(infoItems[i]);
      if (i < infoItems.length - 1) {
        children.add(_buildDivider(appColors));
      }
    }

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
        children: children,
      ),
    );
  }

  Widget _buildDivider(AppColorsExtension appColors) {
    return Divider(
      height: 24,
      color: appColors.divider.withValues(alpha: 0.5),
    );
  }

  Widget _buildSkillRow(
    BuildContext context,
    String label,
    List<String> skills,
    AppColorsExtension appColors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: appColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: skills.map((skill) {
              final color = _getSkillColor(skill);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  skill,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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

  void _showActionDrawer(BuildContext context, AppColorsExtension appColors) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
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
                    color: appColors.textSecondary.withValues(alpha: 0.2),
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
                          'Delete',
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
      builder: (context) => AlertDialog(
        backgroundColor: appColors.background,
        title: Text(
          'Confirm Delete',
          style: TextStyle(color: appColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this course?',
          style: TextStyle(color: appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCourse();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse() async {
    if (_course == null) return;
    try {
      final provider = context.read<CourseProvider>();
      await provider.deleteCourse(_course!);
      if (mounted) {
        context.pop(); // Go back after deletion using go_router
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting course: $e')),
        );
      }
    }
  }

  Future<void> _handleLessonTap(BuildContext context, Lesson lesson) async {
    final quizStateProvider = context.read<QuizStateProvider>();

    await quizStateProvider.init();

    // Check if lesson has any saved progress
    final hasProgress = quizStateProvider.hasLessonProgress(lesson.id);

    if (hasProgress) {
      // Load all progress for this lesson
      final progressData = <String, QuizProgress>{};
      int totalQuestions = 0;

      // Calculate total questions for the entire lesson
      for (final quiz in lesson.quizzes) {
        int quizTotal = 0;
        final type = quiz.type.toLowerCase();

        if (type.contains('multiple-choice')) {
          quizTotal = quiz.questions.length;
        } else if (type.contains('dictation')) {
          quizTotal = quiz.dictations?.length ?? 0;
        } else if (type.contains('flashcard')) {
          quizTotal = quiz.flashcards?.length ?? 0;
        } else if (type.contains('sentence-transformation')) {
          quizTotal = quiz.sentenceTransformations?.length ?? 0;
        } else if (type.contains('speech-builder')) {
          quizTotal = quiz.speechBuilders?.length ?? 0;
        } else if (type.contains('pronunciation')) {
          quizTotal = quiz.pronunciations?.length ?? 0;
        } else if (type.contains('error-correction')) {
          quizTotal = quiz.errorCorrections?.length ?? 0;
        } else if (type.contains('matching')) {
          quizTotal = quiz.matchings?.length ?? 0;
        } else if (type.contains('gap-fill')) {
          quizTotal = quiz.answers.length;
          if (quizTotal == 0) quizTotal = 1;
        } else if (type.contains('chat')) {
          quizTotal = 1; // Chat is counted as 1 unit of progress
        }

        if (quizTotal == 0) quizTotal = 1;
        totalQuestions += quizTotal;
      }

      for (final quiz in lesson.quizzes) {
        final progress =
            await quizStateProvider.loadQuizProgress(lesson.id, quiz.id);
        if (progress != null) {
          progressData[quiz.id] = progress;
        }
      }

      final overallPercentage = quizStateProvider.getLessonProgressPercentage(
        lesson.id,
        lesson.quizzes.length,
      );

      if (progressData.isNotEmpty && mounted) {
        // Show resume drawer
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return QuizResumeDrawer(
              lessonTitle: lesson.title,
              quizzes: lesson.quizzes,
              progressData: progressData,
              overallPercentage: overallPercentage,
              totalQuestions: totalQuestions,
              onContinue: () {
                Navigator.pop(context);
                context.push(
                  '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
                  extra: lesson,
                );
              },
              onReset: () async {
                await quizStateProvider.clearLessonProgress(lesson.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  context.push(
                    '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
                    extra: lesson,
                  );
                }
              },
            );
          },
        );
        return;
      }
    }

    // No progress, navigate directly
    if (mounted) {
      context.push(
        '${RouteConstants.course}/${RouteConstants.courseDetail}/${RouteConstants.quiz}',
        extra: lesson,
      );
    }
  }
}
