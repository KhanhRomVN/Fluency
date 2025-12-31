import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_gap_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    // Use the first quiz question if available, otherwise show placeholder
    final activeQuiz = lesson.quizzes.isNotEmpty ? lesson.quizzes.first : null;
    final questionContent =
        activeQuiz?.question ?? '<p>No quiz data available.</p>';
    final activeQuizIndex = 0; // Currently hardcoded to first quiz

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navbar
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8), // Reduced padding
              decoration: BoxDecoration(
                color: appColors.cardBackground,
              ),
              child: Row(
                children: [
                  // Left side: Title + Question Counter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    // Reduced font size
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Question ${activeQuizIndex + 1}/${lesson.quizzes.length}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: appColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Menu Icon
                  InkWell(
                    onTap: () {
                      _showQuizDrawer(context, appColors);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0), // Reduced padding
                      child: SvgPicture.asset(
                        'assets/icons/menu_quiz.svg',
                        width: 20, // Reduced icon size
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          appColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quiz Content
            Expanded(
              child: SingleChildScrollView(
                child: QuizGapFill(
                  question: questionContent,
                  answers: activeQuiz?.answers ?? [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizDrawer(BuildContext context, AppColorsExtension appColors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: appColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(
                  height: 16), // Add some spacing since handle is gone
              // Quiz List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lesson.quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final quiz = lesson.quizzes[index];
                    final isCurrent = index == 0; // Hardcoded check for demo
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? appColors.primary.withValues(alpha: 0.1)
                            : appColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? appColors.primary
                              : appColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? appColors.primary
                                  : appColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.title.isNotEmpty
                                      ? quiz.title
                                      : 'Quiz ${index + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: appColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                ),
                                if (quiz.type.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      quiz.type.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Exit Button
              // Exit Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    context.pop(); // Close drawer
                    context.pop(); // Pop QuizPage
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
