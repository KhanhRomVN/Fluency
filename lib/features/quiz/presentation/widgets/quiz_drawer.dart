import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class QuizDrawer extends StatelessWidget {
  const QuizDrawer({
    required this.lesson,
    required this.activeQuizIndex,
    required this.onQuizSelected,
    super.key,
  });

  final Lesson lesson;
  final int activeQuizIndex;
  final ValueChanged<int> onQuizSelected;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: appColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: appColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/x.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        appColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quiz List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: lesson.quizzes.length,
              separatorBuilder: (_, __) => Divider(
                color: appColors.border.withValues(alpha: 0.3),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final quiz = lesson.quizzes[index];
                final isActive = index == activeQuizIndex;
                final isCompleted = context
                    .watch<QuizStateProvider>()
                    .isQuizCompleted(lesson.id, quiz.id);

                // Get quiz type label and color (similar to QuizPage)
                final String typeLabel;
                final Color typeColor;
                switch (quiz.type) {
                  case 'multiple-choice':
                    typeLabel = 'MULTIPLE CHOICE';
                    typeColor = Colors.blue;
                  case 'gap-fill-typing':
                    typeLabel = 'GAP FILL';
                    typeColor = Colors.green;
                  case 'gap-fill-dropdown':
                    typeLabel = 'GAP FILL';
                    typeColor = Colors.lightGreen;
                  case 'matching-dropdown':
                    typeLabel = 'MATCHING';
                    typeColor = Colors.purple;
                  case 'writing-essay':
                    typeLabel = 'WRITING';
                    typeColor = Colors.orange;
                  case 'speaking-essay':
                    typeLabel = 'SPEAKING';
                    typeColor = Colors.pink;
                  case 'free-chat':
                    typeLabel = 'FREE CHAT';
                    typeColor = Colors.cyan;
                  case 'scripted-chat':
                    typeLabel = 'SCRIPTED CHAT';
                    typeColor = Colors.blueAccent;
                  case 'pronunciation-drill':
                    typeLabel = 'PRONUNCIATION';
                    typeColor = Colors.teal;
                  case 'dictation-audio':
                    typeLabel = 'DICTATION';
                    typeColor = Colors.pink;
                  case 'builder':
                    typeLabel = 'BUILDER';
                    typeColor = Colors.amber;
                  case 'sentence-transformation':
                    typeLabel = 'TRANSFORMATION';
                    typeColor = Colors.deepOrange;
                  case 'error-correction':
                    typeLabel = 'ERROR CORRECTION';
                    typeColor = Colors.redAccent;
                  case 'flashcard':
                    typeLabel = 'FLASHCARD';
                    typeColor = Colors.indigo;
                  case 'speech-builder':
                    typeLabel = 'SPEECH BUILDER';
                    typeColor = Colors.blueGrey;
                  default:
                    typeLabel = 'QUIZ';
                    typeColor = Colors.grey;
                }

                return InkWell(
                  onTap: () {
                    onQuizSelected(index);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isActive
                          ? Border(
                              left: BorderSide(
                                color: appColors.primary,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: typeColor.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Title
                              Text(
                                '${index + 1}. ${quiz.title.isNotEmpty ? quiz.title : quiz.question.isNotEmpty ? quiz.question : 'Untitled Question'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isActive
                                          ? appColors.primary
                                          : appColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Progress Circle
                        _buildProgressCircle(
                          context,
                          lesson.id,
                          quiz.id,
                          quiz.type,
                          typeColor,
                          appColors,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(
    BuildContext context,
    String lessonId,
    String quizId,
    String quizType,
    Color typeColor,
    AppColorsExtension appColors,
  ) {
    final quizStateProvider = context.watch<QuizStateProvider>();
    final progress = quizStateProvider.getQuizProgress(lessonId, quizId);

    if (progress == null) {
      // No progress yet
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '0%',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final progressValue = progress.completedItems / progress.totalItems;
    final percentage = progress.progressPercentage.round();

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey.withValues(alpha: 0.12),
            color: Colors.redAccent,
            strokeWidth: 2.5,
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: progress.correctItems / progress.totalItems,
            backgroundColor: Colors.transparent,
            color: Colors.green,
            strokeWidth: 2.5,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: progressValue > 0 ? typeColor : Colors.grey,
          ),
        ),
      ],
    );
  }
}
