import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/explain_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/media_player.dart';
import 'package:fluency/features/quiz/presentation/widgets/passage_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/builder.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/dictation_audio.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/error_correction.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/flashcard.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/free_chat.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill_typing.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/listening_choice.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/matching_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/multiple_choice.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/pronunciation_drill.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/scripted_chat.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/sentence_transformation.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speaking_essay.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speech_builder.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/writing_essay.dart';
import 'package:fluency/features/quiz/presentation/widgets/transcript_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/tutorial_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    required this.lesson,
    this.onNextLesson,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback? onNextLesson;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
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
  late PageController _pageController;
  late AnimationController _tutorialPulseController;
  late Animation<double> _tutorialPulseAnimation;

  double? _currentSegmentStart; // Question-level (for looping)
  double? _currentSegmentEnd; // Question-level (for looping)

  // Track target question index for each quiz ID to support navigation from drawer
  final Map<String, int> _targetQuestionIndices = {};

  @override
  void initState() {
    super.initState();
    // Create new AudioPlayer instance
    // Note: On hot restart, old instances may persist. We can't stop them from here
    // because we don't have reference to them. The stop() in dispose() should handle it.
    _audioPlayer = AudioPlayer();

    // Find first uncompleted quiz index
    final lesson = widget.lesson;
    final quizStateProvider = context.read<QuizStateProvider>();
    int firstUncompletedIndex = 0;
    for (int i = 0; i < lesson.quizzes.length; i++) {
      if (!quizStateProvider.isQuizCompleted(lesson.id, lesson.quizzes[i].id)) {
        firstUncompletedIndex = i;
        break;
      }
    }
    _activeQuizIndex = firstUncompletedIndex;
    _isQuizChecked = quizStateProvider.isQuizCompleted(
      lesson.id,
      lesson.quizzes[_activeQuizIndex].id,
    );

    _pageController = PageController(initialPage: _activeQuizIndex);

    // Initialize tutorial rotation animation (Sweep effect)
    _tutorialPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _tutorialPulseAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _tutorialPulseController,
      curve: Curves.linear,
    ));

    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer.onPositionChanged.listen((p) {});
  }

  @override
  void dispose() {
    _audioPlayer.stop(); // Stop playback before disposing
    _audioPlayer.dispose();
    _pageController.dispose();
    _tutorialPulseController.dispose();
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

  void _onNextQuiz() {
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

    if (_activeQuizIndex < widget.lesson.quizzes.length - 1) {
      _pageController.animateToPage(
        _activeQuizIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last quiz completed, maybe show summary or go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson completed!')),
      );
    }
  }

  void _onPrevQuiz() {
    if (_activeQuizIndex > 0) {
      _pageController.animateToPage(
        _activeQuizIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onWordLongPress(String word) {
    setState(() {
      _selectedWord = word;
      _showDirectoryDrawer = true;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _activeQuizIndex = index;
      _isQuizChecked = false;
      _isQuizChecked = false;
      _currentSegmentStart = null;
      _currentSegmentEnd = null;
    });
  }

  void _handleSegmentChange(double? start, double? end) {
    if (_currentSegmentStart == start && _currentSegmentEnd == end) return;
    debugPrint('QuizPage: Received segment change. Start: $start, End: $end');
    setState(() {
      _currentSegmentStart = start;
      _currentSegmentEnd = end;
    });
    // Note: We don't auto-seek here. The looping logic in _initAudio handles playback.
    // Auto-seeking would jump to the segment start immediately, which is not desired on page load.
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final lesson = widget.lesson;

    // Get current quiz
    final activeQuiz =
        lesson.quizzes.isNotEmpty ? lesson.quizzes[_activeQuizIndex] : null;

    final quizType = activeQuiz?.type ?? 'gap-fill';

    // Audio path logic
    final audioPath = activeQuiz?.audio;
    // Path is already resolved in CourseRepository if it was relative.

    var audioFileName = 'Audio';
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
                      Container(
                        decoration: BoxDecoration(
                          color: appColors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: _showExitConfirmationDrawer,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/icons/chevron_left.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                appColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center: Quiz text + Badge
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Quiz',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: appColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                          ],
                        ),
                      ),

                      // Right: Icon row and Progress Badge
                      Row(
                        children: [
                          // Passage icon (if available)
                          if (activeQuiz?.passage != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: appColors.textPrimary
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showPassageDrawer = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    'assets/icons/pilcrow.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      appColors.textPrimary
                                          .withValues(alpha: 0.6),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Tutorial/Instruction icon (if available)
                          if (activeQuiz?.instruction != null &&
                              activeQuiz!.instruction.isNotEmpty)
                            AnimatedBuilder(
                              animation: _tutorialPulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // The Sweep Highlight
                                    CustomPaint(
                                      size: const Size(32, 32),
                                      painter: _SweepPainter(
                                        angle: _tutorialPulseAnimation.value,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    // The styled button container
                                    Container(
                                      decoration: BoxDecoration(
                                        color: appColors.textPrimary
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showTutorialDrawer = true;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: SvgPicture.string(
                                            '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></svg>''',
                                            width: 16,
                                            height: 16,
                                            colorFilter: const ColorFilter.mode(
                                              Colors.orange,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          // Transcript icon (shown after checking)
                          if (_isQuizChecked &&
                              activeQuiz?.transcript != null) ...[
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _tutorialPulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // The Sweep Highlight
                                    CustomPaint(
                                      size: const Size(32, 32),
                                      painter: _SweepPainter(
                                        angle: _tutorialPulseAnimation.value,
                                        color: appColors.primary,
                                      ),
                                    ),
                                    // The styled button container
                                    Container(
                                      decoration: BoxDecoration(
                                        color: appColors.textPrimary
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showTranscriptDrawer = true;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: SvgPicture.asset(
                                            'assets/icons/audio_lines.svg',
                                            width: 16,
                                            height: 16,
                                            colorFilter: ColorFilter.mode(
                                              appColors.textPrimary
                                                  .withValues(alpha: 0.6),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],

                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color:
                                  appColors.textPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () {
                                _showQuizDrawer(context);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset(
                                  'assets/icons/align_end_vertical.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                    appColors.textPrimary
                                        .withValues(alpha: 0.6),
                                    BlendMode.srcIn,
                                  ),
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
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: lesson.quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = lesson.quizzes[index];
                      return _buildQuizContent(quiz.type, quiz.question, quiz);
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: audioPath != null
              ? MediaPlayer(
                  key: ValueKey(
                    audioPath,
                  ), // Rebuild player when audio source changes
                  audioPath: audioPath,
                  title: audioFileName, // Use audio filename
                  externalPlayer: _audioPlayer,
                  transcriptPath: activeQuiz?.transcript,
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
            quizType: activeQuiz?.type ?? 'gap-fill',
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
      return const Center(child: Text('No quiz available'));
    }

    switch (type) {
      case 'gap-fill-dropdown':
        return GapFillDropdown(
          question: quiz.question,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          answers: quiz.answers,
          title: quiz.title,
          instruction: quiz.instruction,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
        );
      case 'multiple-choice':
        return MultipleChoice(
          quiz: quiz,
          lessonId: widget.lesson.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
          targetQuestionIndex: _targetQuestionIndices[quiz.id],
        );
      case 'matching-dropdown':
        return MatchingDropdown(
          quiz: quiz,
          lessonId: widget.lesson.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
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
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
        );
      case 'free-chat':
        return FreeChat(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onWordLongPress: _onWordLongPress,
          onCheck: _onQuizChecked,
        );
      case 'scripted-chat':
        return ScriptedChat(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onWordLongPress: _onWordLongPress,
          onCheck: _onQuizChecked,
        );
      case 'chatting-speech': // Legacy support
        return ScriptedChat(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onWordLongPress: _onWordLongPress,
        );
      case 'dictation':
      case 'dictation-audio':
        return DictationAudio(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'error-correction':
        return ErrorCorrection(
          quiz: quiz,
          lessonId: widget.lesson.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'flashcard':
        return Flashcard(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'pronunciation':
      case 'pronunciation-drill':
        return PronunciationDrill(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'sentence-transformation':
        return SentenceTransformation(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onCheck: _onQuizChecked,
          onShowExplain: (String explanation) {
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
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'listening-choice':
        return ListeningChoice(
          quiz: quiz,
          lessonId: widget.lesson.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
            setState(() {
              _currentExplanation = explanation;
              _showExplainDrawer = true;
            });
          },
          onWordLongPress: _onWordLongPress,
          onSegmentChange: _handleSegmentChange,
          targetQuestionIndex: _targetQuestionIndices[quiz.id],
        );
      case 'speech-builder':
        return SpeechBuilder(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      case 'writing-essay':
        return WritingEssay(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onWordLongPress: _onWordLongPress,
        );
      default:
        return GapFillTyping(
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          question: question,
          answers: quiz.answers,
          title: quiz.title,
          instruction: quiz.instruction,
          onCheck: _onQuizChecked,
          onNext: _onNextQuiz,
          onPrev: _onPrevQuiz,
          onShowExplain: (String explanation) {
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
            if (index != _activeQuizIndex) {
              _pageController.jumpToPage(index);
            }
          },
          onQuestionSelected: (quizIndex, questionIndex) {
            final quiz = widget.lesson.quizzes[quizIndex];
            setState(() {
              _targetQuestionIndices[quiz.id] = questionIndex;
            });
            if (quizIndex != _activeQuizIndex) {
              _pageController.jumpToPage(quizIndex);
            }
          },
          onNextLesson: widget.onNextLesson,
        );
      },
    );
  }

  void _showExitConfirmationDrawer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: appColors.drawerBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exit Quiz?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: appColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Your progress will be saved',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: appColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: appColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: appColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: appColors.border.withValues(alpha: 0.5),
                height: 1,
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildExitOption(
                      title: 'Stay & Continue',
                      subtitle: 'Keep practicing and improve your skills',
                      icon: Icons.play_arrow_rounded,
                      iconColor: Colors.blue,
                      onTap: () => Navigator.pop(context),
                      appColors: appColors,
                    ),
                    const SizedBox(height: 12),
                    _buildExitOption(
                      title: 'Exit & Save Progress',
                      subtitle: 'Finish later, your data is safe',
                      icon: Icons.logout_rounded,
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context).pop(); // Exit quiz page
                      },
                      appColors: appColors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExitOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: appColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: appColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.angle, required this.color});
  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
