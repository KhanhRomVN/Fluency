import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/multiple_choice.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/matching_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/media_player.dart';
import 'package:fluency/features/quiz/presentation/widgets/transcript_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/passage_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/tutorial_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/explain_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
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
  bool _showPassageDrawer = false;
  bool _showTutorialDrawer = false;
  bool _showTranscriptDrawer = false;
  bool _showExplainDrawer = false;
  bool _showDirectoryDrawer = false;
  String? _selectedWord;
  String _currentExplanation = '';
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onQuizChecked() {
    setState(() {
      _isQuizChecked = true;
    });

    final lesson = widget.lesson;
    final activeQuiz =
        lesson.quizzes.isNotEmpty ? lesson.quizzes[_activeQuizIndex] : null;

    if (activeQuiz != null) {
      context
          .read<QuizStateProvider>()
          .markQuizCompleted(lesson.id, activeQuiz.id);
    }
  }

  void _onWordLongPress(String word) {
    setState(() {
      _selectedWord = word;
      _showDirectoryDrawer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final lesson = widget.lesson;

    // Get current quiz
    final activeQuiz =
        lesson.quizzes.isNotEmpty ? lesson.quizzes[_activeQuizIndex] : null;

    final quizType = activeQuiz?.type ?? 'gap-fill';
    final questionContent =
        activeQuiz?.question ?? '<p>No quiz data available.</p>';

    // Audio path logic
    final String? audioPath = activeQuiz?.audio;
    // Path is already resolved in CourseRepository if it was relative.

    String audioFileName = 'Audio';
    if (audioPath != null) {
      audioFileName = audioPath.split('/').last;
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: appColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navbar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
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
                      // Left: Back button
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SvgPicture.asset(
                            'icons/chevron_left.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              appColors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),

                      // Center: Quiz label
                      Text(
                        'Quiz',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
                            ),
                      ),

                      // Right: Icon row
                      Row(
                        children: [
                          // Passage icon (if available)
                          if (activeQuiz?.passage != null)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showPassageDrawer = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'icons/pilcrow.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    appColors.textPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),

                          // Tutorial/Instruction icon (if available)
                          if (activeQuiz?.instruction != null &&
                              activeQuiz!.instruction.isNotEmpty)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showTutorialDrawer = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'icons/circle_dot_dashed.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    appColors.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),

                          // Transcript icon (shown after checking)
                          if (_isQuizChecked && activeQuiz?.transcript != null)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showTranscriptDrawer = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: SvgPicture.asset(
                                  'icons/audio_lines.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    appColors.textPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),

                          // Question counter badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: appColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_activeQuizIndex + 1}/${lesson.quizzes.length}',
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

                          // Info icon
                          InkWell(
                            onTap: () {
                              // TODO: Show info/help
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: SvgPicture.asset(
                                'icons/info.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  appColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),

                          // Menu icon
                          InkWell(
                            onTap: () {
                              _showQuizDrawer(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: SvgPicture.asset(
                                'icons/align_end_vertical.svg',
                                width: 18,
                                height: 18,
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
                  child:
                      _buildQuizContent(quizType, questionContent, activeQuiz),
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
                  externalPlayer: _audioPlayer,
                )
              : null,
        ),
        // Passage Drawer
        if (_showPassageDrawer)
          PassageDrawer(
            isOpen: _showPassageDrawer,
            onClose: () {
              setState(() {
                _showPassageDrawer = false;
              });
            },
            passagePath: activeQuiz?.passage,
          ),
        // Tutorial Drawer
        if (_showTutorialDrawer)
          TutorialDrawer(
            isOpen: _showTutorialDrawer,
            onClose: () {
              setState(() {
                _showTutorialDrawer = false;
              });
            },
            content: activeQuiz?.instruction ?? '',
          ),
        // Explain Drawer
        if (_showExplainDrawer)
          ExplainDrawer(
            isOpen: _showExplainDrawer,
            onClose: () {
              setState(() {
                _showExplainDrawer = false;
              });
            },
            explanation: _currentExplanation,
          ),
        // Transcript Drawer
        if (_showTranscriptDrawer)
          TranscriptDrawer(
            isOpen: _showTranscriptDrawer,
            onClose: () {
              setState(() {
                _showTranscriptDrawer = false;
              });
            },
            transcriptPath: activeQuiz?.transcript,
            audioPath: audioPath,
            audioPlayer: _audioPlayer,
          ),
        // Directory Drawer
        DirectoryDrawer(
          isOpen: _showDirectoryDrawer,
          onClose: () {
            setState(() {
              _showDirectoryDrawer = false;
            });
          },
          word: _selectedWord,
        ),
      ],
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
          onShowExplain: (explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
        );
      case 'matching-dropdown':
        return MatchingDropdown(
          quiz: quiz,
          isChecked: _isQuizChecked,
          onCheck: _onQuizChecked,
          onShowExplain: (explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
        );
      case 'gap-fill':
      default:
        return GapFill(
          question: question,
          answers: quiz.answers,
          title: quiz.title,
          instruction: quiz.instruction,
          onCheck: _onQuizChecked,
          onShowExplain: (explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          hasAudio: quiz.audio != null && quiz.audio!.isNotEmpty,
          onWordLongPress: _onWordLongPress,
        );
    }
  }

  void _showQuizDrawer(BuildContext context) {
    showModalBottomSheet<void>(
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
}
