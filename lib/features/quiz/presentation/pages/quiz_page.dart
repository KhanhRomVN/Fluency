import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/multiple_choice.dart'; // Import MultipleChoice
import 'package:fluency/features/quiz/presentation/widgets/media_player.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/widgets/transcript_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _activeQuizIndex = 0;
  bool _isQuizChecked = false;

  void _onQuizChecked() {
    debugPrint('AG_LOG: _onQuizChecked called in QuizPage');
    setState(() {
      _isQuizChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final lesson = widget.lesson;
    debugPrint(
        'AG_LOG: QuizPage build. Lesson: ${lesson.title}, Quizzes count: ${lesson.quizzes.length}');
    for (var i = 0; i < lesson.quizzes.length; i++) {
      debugPrint(
          'AG_LOG: Quiz $i: ${lesson.quizzes[i].title} - ${lesson.quizzes[i].type}');
    }

    // Get current quiz
    final activeQuiz =
        lesson.quizzes.isNotEmpty ? lesson.quizzes[_activeQuizIndex] : null;

    final quizType = activeQuiz?.type ?? 'gap-fill';
    final questionContent =
        activeQuiz?.question ?? '<p>No quiz data available.</p>';

    // Audio path logic
    String? audioPath = activeQuiz?.audio;
    if (audioPath != null && audioPath.startsWith('./')) {
      audioPath = audioPath.replaceFirst(
          './', 'lib/features/course/assets/courses/Cambridge_IELTS_18/');
    }

    String audioFileName = 'Audio';
    if (audioPath != null) {
      audioFileName = audioPath.split('/').last;
    }

    // Transcript Icon Logic Debug
    debugPrint('AG_LOG: QuizPage build. _isQuizChecked: $_isQuizChecked');
    debugPrint(
        'AG_LOG: Active Quiz Transcript: ${activeQuiz?.transcript != null ? "Present" : "NULL"}');

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
                          activeQuiz?.title.isNotEmpty == true
                              ? activeQuiz!.title
                              : lesson
                                  .title, // Use Quiz Title, fallback to Lesson Title
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
                            'Question ${_activeQuizIndex + 1}/${lesson.quizzes.length}',
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
                  // Right side: Menu Icon + Transcript Icon
                  Row(
                    children: [
                      if (_isQuizChecked && activeQuiz?.transcript != null)
                        InkWell(
                          onTap: () {
                            _showTranscriptDrawer(
                                context, activeQuiz!.transcript!, audioPath);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: SvgPicture.asset(
                              'assets/icons/transcript.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                appColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      InkWell(
                        onTap: () {
                          _showQuizDrawer(context);
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
                ],
              ),
            ),
            // Quiz Content
            Expanded(
              child: _buildQuizContent(quizType, questionContent, activeQuiz),
            ),
          ],
        ),
      ),
      bottomNavigationBar: audioPath != null
          ? MediaPlayer(
              key: ValueKey(
                  audioPath), // Rebuild player when audio source changes
              audioPath: audioPath,
              title: audioFileName, // Use audio filename
            )
          : null,
    );
  }

  Widget _buildQuizContent(String type, String question, Quiz? quiz) {
    if (quiz == null) {
      return const Center(child: Text("No quiz available"));
    }

    switch (type) {
      case 'multiple-choice':
        return MultipleChoice(
          quiz: quiz,
          onCheck: _onQuizChecked,
        );
      case 'gap-fill':
      default:
        return GapFill(
          question: question,
          answers: quiz.answers,
          onCheck: _onQuizChecked,
        );
    }
  }

  void _showQuizDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuizDrawer(
          lesson: widget.lesson,
          activeQuizIndex: _activeQuizIndex,
          onQuizSelected: (index) {
            setState(() {
              _activeQuizIndex = index;
              _isQuizChecked = false; // Reset checked state on quiz change
            });
          },
        );
      },
    );
  }

  void _showTranscriptDrawer(
      BuildContext context, String transcript, String? audioPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TranscriptDrawer(transcript: transcript, audioPath: audioPath);
      },
    );
  }
}
