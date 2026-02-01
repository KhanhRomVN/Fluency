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
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/free_chat.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/scripted_chat.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/dictation_audio.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/error_correction.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/flashcard.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/gap_fill_typing.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/matching_dropdown.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/multiple_choice.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/pronunciation_drill.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/sentence_transformation.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speaking_essay.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/speech_builder.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/writing_essay.dart';
import 'package:fluency/features/quiz/presentation/widgets/transcript_drawer.dart';
import 'package:fluency/features/quiz/presentation/widgets/tutorial_drawer.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({required this.lesson, super.key});

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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _pageController = PageController(initialPage: _activeQuizIndex);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
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
                      // Left: Back button + Quiz Badge
                      Row(
                        children: [
                          InkWell(
                            onTap: _showExitConfirmationDrawer,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
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
                                padding: const EdgeInsets.all(6),
                                child: SvgPicture.asset(
                                  'assets/icons/pilcrow.svg',
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: appColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Must read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                                padding: const EdgeInsets.all(6),
                                child: SvgPicture.asset(
                                  'assets/icons/audio_lines.svg',
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

                          // Quick Settings Button
                          InkWell(
                            onTap: _showQuickSettingsDrawer,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: SvgPicture.string(
                                '''<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><circle cx="12" cy="12" r="4"/></svg>''',
                                colorFilter: ColorFilter.mode(
                                  appColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
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
                              padding: const EdgeInsets.all(6),
                              child: SvgPicture.asset(
                                'assets/icons/align_end_vertical.svg',
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
        );
      case 'scripted-chat':
        return ScriptedChat(
          quiz: quiz,
          lessonId: widget.lesson.id,
          quizId: quiz.id,
          onWordLongPress: _onWordLongPress,
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
      case 'gap-fill':
      case 'gap-fill-typing':
      case 'gap-fill-dropdown':
        label = 'Gap Fill';
        color = Colors.green;
      case 'matching-dropdown':
        label = 'Matching';
        color = Colors.purple;
      case 'writing-essay':
        label = 'Writing';
        color = Colors.orange;
      case 'speaking-essay':
      case 'speaking':
        label = 'Speaking';
        color = Colors.pink;
      case 'free-chat':
      case 'free-typing-chat':
        label = 'Free Chat';
        color = Colors.cyan;
      case 'scripted-chat':
      case 'chatting-speech':
        label = 'Scripted Chat';
        color = Colors.blueAccent;
      case 'pronunciation-drill':
      case 'pronunciation':
        label = 'Pronunciation';
        color = Colors.teal;
      case 'dictation':
      case 'dictation-audio':
        label = 'Dictation';
        color = Colors.pink;
      case 'builder':
        label = 'Builder';
        color = Colors.amber;
      case 'sentence-transformation':
        label = 'Transformation';
        color = Colors.deepOrange;
      case 'error-correction':
        label = 'Error Correction';
        color = Colors.redAccent;
      case 'flashcard':
        label = 'Flashcard';
        color = Colors.indigo;
      case 'speech-builder':
        label = 'Speech Builder';
        color = Colors.blueGrey;
      default:
        label = 'Quiz';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  void _showQuickSettingsDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return Container(
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Voice Recognition Option
              _buildQuickSettingOption(
                icon: Icons.mic,
                title: 'Voice Recognition',
                subtitle: 'Speech-to-text settings',
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceRecognitionDrawer();
                },
                colors: appColors,
              ),

              const SizedBox(height: 12),

              // Voice Settings Option
              _buildQuickSettingOption(
                icon: Icons.volume_up,
                title: 'Voice Settings',
                subtitle: 'Text-to-speech settings',
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceSettingsDrawer();
                },
                colors: appColors,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceRecognitionDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        final sttProvider = context.watch<SttSettingProvider>();

        return Container(
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice Recognition',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // System STT Option
              _buildSTTOption(
                title: 'System',
                subtitle: 'Device built-in recognition',
                isSelected:
                    sttProvider.currentProviderType == SttProviderType.system,
                onTap: () {
                  sttProvider.setProviderType(SttProviderType.system);
                },
                colors: appColors,
              ),

              const SizedBox(height: 12),

              // Vosk STT Option
              _buildSTTOption(
                title: 'Vosk (Offline)',
                subtitle: 'Local speech recognition',
                isSelected:
                    sttProvider.currentProviderType == SttProviderType.vosk,
                onTap: () {
                  sttProvider.setProviderType(SttProviderType.vosk);
                },
                colors: appColors,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceSettingsDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        final ttsProvider = context.watch<TtsProvider>();

        return Container(
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voice Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // System TTS Option
              _buildTTSOption(
                title: 'System',
                subtitle: 'Device built-in voice',
                isSelected: ttsProvider.activeEngine == 'System',
                onTap: () {
                  ttsProvider.setEngine('System');
                },
                colors: appColors,
              ),

              const SizedBox(height: 12),

              // Piper TTS Option
              _buildTTSOption(
                title: 'Piper',
                subtitle: 'High quality AI voices',
                isSelected: ttsProvider.activeEngine == 'Piper',
                onTap: () {
                  ttsProvider.setEngine('Piper');
                },
                colors: appColors,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSTTOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.border.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmationDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return Container(
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .exit_to_app_rounded, // Use rounded icon if available for softer look
                size: 40,
                color: appColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Exit Quiz?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your progress will be saved',
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: appColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close drawer
                        Navigator.of(context).pop(); // Exit quiz page
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: appColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
