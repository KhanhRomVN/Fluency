import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class QuizDrawer extends StatefulWidget {
  const QuizDrawer({
    required this.lesson,
    required this.activeQuizIndex,
    required this.onQuizSelected,
    this.onQuestionSelected,
    this.onNextLesson,
    super.key,
  });

  final Lesson lesson;
  final int activeQuizIndex;
  final ValueChanged<int> onQuizSelected;
  final void Function(int quizIndex, int questionIndex)? onQuestionSelected;
  final VoidCallback? onNextLesson;

  @override
  State<QuizDrawer> createState() => _QuizDrawerState();
}

class _QuizDrawerState extends State<QuizDrawer> {
  final Set<int> _expandedIndices = {};

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                ),
                Row(
                  children: [
                    if (widget.onNextLesson != null &&
                        context
                                .watch<QuizStateProvider>()
                                .getLessonProgressPercentage(
                                  widget.lesson.id,
                                  widget.lesson.quizzes.length,
                                ) >=
                            100)
                      InkWell(
                        onTap: widget.onNextLesson,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#${appColors.primary.value.toRadixString(16).substring(2)}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-step-forward-icon lucide-step-forward"><path d="M10.029 4.285A2 2 0 0 0 7 6v12a2 2 0 0 0 3.029 1.715l9.997-5.998a2 2 0 0 0 .003-3.432z"/><path d="M3 4v16"/></svg>''',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: appColors.textSecondary,
                      ),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quiz List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.lesson.quizzes.length,
              separatorBuilder: (_, __) => Divider(
                color: appColors.border.withValues(alpha: 0.3),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final quiz = widget.lesson.quizzes[index];
                final isActive = index == widget.activeQuizIndex;
                final isExpanded = _expandedIndices.contains(index);

                // Get quiz type label and color
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
                  case 'listening-choice':
                    typeLabel = 'LISTENING CHOICE';
                    typeColor = Colors.indigo;
                  default:
                    typeLabel = 'QUIZ';
                    typeColor = Colors.grey;
                }

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        widget.onQuizSelected(index);
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
                                    color: typeColor,
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
                                  // Type badge row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              typeColor.withValues(alpha: 0.1),
                                          border: Border.all(
                                            color: typeColor.withValues(
                                                alpha: 0.3),
                                            width: 0.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                      if (quiz.questions.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: appColors.textSecondary
                                                .withValues(alpha: 0.1),
                                            border: Border.all(
                                              color: appColors.textSecondary
                                                  .withValues(alpha: 0.3),
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${quiz.questions.length} questions',
                                            style: TextStyle(
                                              color: appColors.textSecondary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: appColors.textSecondary
                                                .withValues(alpha: 0.1),
                                            border: Border.all(
                                              color: appColors.textSecondary
                                                  .withValues(alpha: 0.3),
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${context.watch<QuizStateProvider>().getQuizProgress(widget.lesson.id, quiz.id)?.correctItems ?? 0}/${quiz.questions.length}pt',
                                            style: TextStyle(
                                              color: appColors.textSecondary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
                                              ? typeColor
                                              : appColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Expand/Collapse and Progress
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (quiz.questions.isNotEmpty)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedIndices.remove(index);
                                        } else {
                                          _expandedIndices.add(index);
                                        }
                                      });
                                    },
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: SvgPicture.string(
                                      isExpanded
                                          ? '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-list-chevrons-down-up-icon lucide-list-chevrons-down-up"><path d="M3 5h8"/><path d="M3 12h8"/><path d="M3 19h8"/><path d="m15 5 3 3 3-3"/><path d="m15 19 3-3 3 3"/></svg>'''
                                          : '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-list-chevrons-up-down-icon lucide-list-chevrons-up-down"><path d="M3 5h8"/><path d="M3 12h8"/><path d="M3 19h8"/><path d="m15 8 3-3 3 3"/><path d="m15 16 3 3 3-3"/></svg>''',
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                        appColors.textSecondary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                _buildProgressCircle(
                                  context,
                                  widget.lesson.id,
                                  quiz.id,
                                  quiz.type,
                                  typeColor,
                                  appColors,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expandable Mini quiz cards
                    if (isExpanded && quiz.questions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: quiz.questions.asMap().entries.map((entry) {
                            final qIndex = entry.key;
                            final question = entry.value;
                            final isLast = qIndex == quiz.questions.length - 1;
                            final questionState = context
                                .watch<QuizStateProvider>()
                                .getQuestionState(
                                    widget.lesson.id, quiz.id, question.id);

                            final bool isCorrect =
                                questionState?['isCorrect'] == true;
                            final Color badgeColor =
                                isCorrect ? Colors.green : Colors.red;

                            return Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    widget.onQuestionSelected
                                        ?.call(index, qIndex);
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${qIndex + 1}. ${question.question.isNotEmpty ? question.question : 'Question ${qIndex + 1}'}',
                                            style: TextStyle(
                                              color: appColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (questionState != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isCorrect ? '1pt' : '0pt',
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    color: appColors.border
                                        .withValues(alpha: 0.15),
                                    height: 1,
                                    thickness: 0.5,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
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
        width: 32,
        height: 32,
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
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey.withValues(alpha: 0.12),
            color: Colors.redAccent,
            strokeWidth: 2.5,
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
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
