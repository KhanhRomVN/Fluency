import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill_typing.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/multiple_choice.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/matching_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/builder.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/chatting_speech.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/dictation_audio.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/error_correction.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/flashcard.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/pronunciation_drill.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/sentence_transformation.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speaking_essay.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speech_builder.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/writing_essay.dart';
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
                      // Left: Back button + Quiz Badge
                      Row(
                        children: [
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
                          const SizedBox(width: 8),
                          _buildQuizTypeBadge(quizType, context),
                        ],
                      ),

                      // Right: Icon row and Progress Badge
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
                                    _showTutorialDrawer
                                        ? appColors.primary
                                        : appColors.textPrimary,
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

                          const SizedBox(width: 4),

                          // Question counter badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: appColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_activeQuizIndex + 1}/${lesson.quizzes.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: appColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                            ),
                          ),

                          const SizedBox(width: 4),

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
            onWordLongPress: _onWordLongPress,
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
      case 'builder':
        return QuizBuilder(
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
      case 'chatting-speech':
        return ChattingSpeech(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'dictation':
      case 'dictation-audio':
        return DictationAudio(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'error-correction':
        return ErrorCorrection(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'flashcard':
        return Flashcard(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'pronunciation':
      case 'pronunciation-drill':
        return PronunciationDrill(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'sentence-transformation':
        return SentenceTransformation(
          quiz: quiz,
          onShowExplain: (explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
        );
      case 'speaking-essay':
        return SpeakingEssay(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'speech-builder':
        return SpeechBuilder(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'writing-essay':
        return WritingEssay(
          quiz: quiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'gap-fill':
      default:
        return GapFillTyping(
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
          onNext: () {
            // Handle next question logic if needed, or if this is the last one.
            // For now, _onQuizChecked handles marking it complete.
            // If we want to move to the next quiz automatically, we'd need a callback for that,
            // but QuizPage handles navigation mainly via drawer or manual back.
            // However, `GapFillTyping` might call `onNext` to signal it's done-done.
            // Let's just check the quiz for now.
            _onQuizChecked();
          },
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

  Widget _buildQuizTypeBadge(String type, BuildContext context) {
    String label;
    Color color;

    switch (type) {
      case 'multiple-choice':
        label = 'Multiple Choice';
        color = Colors.blue;
        break;
      case 'gap-fill':
        label = 'Gap Fill';
        color = Colors.green;
        break;
      case 'gap-fill-typing':
        label = 'Gap Fill';
        color = Colors.green;
        break;
      case 'gap-fill-dropdown':
        label = 'Gap Fill';
        color = Colors.lightGreen;
        break;
      case 'matching-dropdown':
        label = 'Matching';
        color = Colors.purple;
        break;
      case 'writing-essay':
        label = 'Writing';
        color = Colors.orange;
        break;
      case 'speaking-essay':
        label = 'Speaking';
        color = Colors.pink;
        break;
      case 'chatting-speech':
        label = 'Chatting';
        color = Colors.cyan;
        break;
      case 'pronunciation-drill':
        label = 'Pronunciation';
        color = Colors.teal;
        break;
      case 'dictation':
      case 'dictation-audio':
        label = 'Dictation Audio';
        color = Colors.pink;
        break;
      case 'builder':
        label = 'Builder';
        color = Colors.amber;
        break;
      case 'sentence-transformation':
        label = 'Transformation';
        color = Colors.deepOrange;
        break;
      default:
        label = 'Quiz';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
