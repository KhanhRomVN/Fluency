import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';

class SpeakingEssay extends StatefulWidget {
  const SpeakingEssay({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onNext,
    this.onPrev,
    this.onCheck,
    this.onWordLongPress,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  @override
  State<SpeakingEssay> createState() => _SpeakingEssayState();
}

class _SpeakingEssayState extends State<SpeakingEssay> {
  int _activeIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _stepSubmitted = {};

  bool _isRecording = false;
  SttService? _sttService;
  bool _speechEnabled = false;
  // bool _speechEnabled = false; // Removed unused variable
  String _currentTranscript = '';
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeIndex);
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sttService?.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _sttService = SystemSttService();

    final available = await _sttService!.initialize();
    if (mounted) {
      setState(() {
        _speechEnabled = available;
      });
    }
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      setState(() {
        _activeIndex = progress.data?['activeIndex'] as int? ?? 0;
        final answers = progress.data?['answers'] as Map<String, dynamic>?;
        if (answers != null) {
          answers.forEach((key, value) {
            _answers[int.parse(key)] = value as String;
          });
        }
        final submittedData =
            progress.data?['stepSubmitted'] as Map<String, dynamic>?;
        if (submittedData != null) {
          submittedData.forEach((key, value) {
            _stepSubmitted[int.parse(key)] = value as bool;
          });
        }
        _pageController.jumpToPage(_activeIndex);
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    final answersMap = _answers.map((k, v) => MapEntry(k.toString(), v));
    final submittedMap =
        _stepSubmitted.map((k, v) => MapEntry(k.toString(), v));

    final totalItems = _questions.length;
    final completedItems = _stepSubmitted.length;
    // For essay, we count completion as correctness/progress
    final correctItems = completedItems;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'speaking-essay',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'activeIndex': _activeIndex,
        'answers': answersMap,
        'stepSubmitted': submittedMap,
      },
    );
  }

  // For sample answer "hint" clicks similar to TSX HintDrawer
  // We can use the existing explain/dictionary mechanism or a simple dialog
  // The TSX uses HintDrawer. We'll use a simple bottom sheet or dialog if needed.
  // For now, let's just focus on displaying the example.

  List<dynamic> get _questions {
    // In TSX: if (quiz.questions && quiz.questions.length > 0) return quiz.questions; return [quiz];
    // In Dart, types are different. We will treat them as dynamic or a wrapper.
    if (widget.quiz.questions.isNotEmpty) {
      return widget.quiz.questions;
    }
    return [widget.quiz];
  }

  dynamic get _currentQuestion => _questions[_activeIndex];
  int get _totalQuestions => _questions.length;

  String get _currentAnswer => _answers[_activeIndex] ?? '';
  bool get _isCurrentSubmitted => _stepSubmitted[_activeIndex] ?? false;
  bool get _hasNext => _activeIndex < _totalQuestions - 1;

  void _handleTextChange(String val) {
    setState(() {
      _answers[_activeIndex] = val;
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (_sttService == null || !_speechEnabled) return;

    // Get STT settings from provider
    String localeId = 'en_US'; // default

    try {
      await _sttService!.startListening(
        onResult: _onSpeechResult,
        localeId: localeId,
      );
      setState(() {
        _isRecording = true;
        _currentTranscript = '';
      });
    } catch (e) {
      debugPrint('Error starting STT: $e');
    }
  }

  void _stopListening() async {
    if (_sttService == null) return;
    await _sttService!.stopListening();
    setState(() {
      _isRecording = false;
    });
  }

  void _onSpeechResult(String text, bool isFinal) {
    debugPrint('SpeakingEssay STT Result: "$text" (Final: $isFinal)');
    setState(() {
      _currentTranscript = text;
      if (isFinal) {
        debugPrint('SpeakingEssay STT Final: "$_currentTranscript"');
        final existingText = _answers[_activeIndex] ?? '';
        final separator = existingText.isEmpty ? '' : ' ';
        _answers[_activeIndex] = '$existingText$separator$_currentTranscript';
        _currentTranscript = '';
        _isRecording = false;
        _saveProgress();
      }
    });
  }

  void _handleSubmitStep() {
    setState(() {
      _stepSubmitted[_activeIndex] = true;
      _isRecording = false;
      _saveProgress();
    });
  }

  void _handleNext() {
    if (_hasNext) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Finish
    }
  }

  String _getQuestionText(dynamic q) {
    if (q is QuizQuestion) return q.question;
    if (q is Quiz) return q.question;
    return '';
  }

  String? _getExample(dynamic q) {
    if (q is Quiz) return q.example;
    // QuizQuestion in Dart doesn't have example yet.
    // If we need it, we might need to update entity or access json.
    // For now, return null for QuizQuestion unless we fake it or find it.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // final questionText = _getQuestionText(_currentQuestion); // Unused
    // final example = _getExample(_currentQuestion); // Unused (using index-based logic in itemBuilder)

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_android,
                size: 64,
                color: appColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Mobile View Not Supported',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This quiz type is designed for larger screens. Please use a tablet or computer for the best experience.',
                style: TextStyle(
                  fontSize: 16,
                  color: appColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent handles background
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is OverscrollNotification) {
            if (notification.overscroll < 0) {
              widget.onPrev?.call();
            } else if (notification.overscroll > 0) {
              if (_isCurrentSubmitted && !_hasNext) {
                widget.onCheck?.call();
                widget.onNext?.call();
              }
            }
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _totalQuestions,
          onPageChanged: (index) {
            setState(() {
              _activeIndex = index;
              _isRecording = false;
              _saveProgress();
            });
          },
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            final currentItem = _questions[index];
            final questionText = _getQuestionText(currentItem);
            final example = _getExample(currentItem);
            final isSubmitted = _stepSubmitted[index] ?? false;
            final currentAnswer = _answers[index] ?? '';

            return Stack(
              children: [
                // Scrollable Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Display
                        if (questionText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${index + 1}. $questionText',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: appColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),

                        // Input Area (Card)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: appColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSubmitted
                                ? SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          currentAnswer,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: appColors.textPrimary,
                                            height: 1.5,
                                          ),
                                        ),
                                        // Sample Answer (if submitted)
                                        if (example != null &&
                                            example.isNotEmpty) ...[
                                          const SizedBox(height: 32),
                                          const Divider(),
                                          const SizedBox(height: 24),
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'Sample Answer',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: appColors.primary
                                                  .withValues(alpha: 0.1),
                                              border: Border.all(
                                                  color: appColors.border),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: RichTextParser.buildRichText(
                                              context,
                                              example,
                                              onWordLongPress: (text) {
                                                widget.onWordLongPress
                                                    ?.call(text);
                                              },
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: appColors.textPrimary,
                                                height: 1.5,
                                              ),
                                            ).first,
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : TextField(
                                    controller: TextEditingController(
                                      text: _isRecording &&
                                              index == _activeIndex
                                          ? (currentAnswer.isEmpty
                                              ? _currentTranscript
                                              : '$currentAnswer $_currentTranscript')
                                          : currentAnswer,
                                    )..selection = TextSelection.collapsed(
                                        offset: _isRecording &&
                                                index == _activeIndex
                                            ? (currentAnswer.isEmpty
                                                ? _currentTranscript.length
                                                : '$currentAnswer $_currentTranscript'
                                                    .length)
                                            : currentAnswer.length,
                                      ),
                                    onChanged: _handleTextChange,
                                    expands: true,
                                    maxLines: null,
                                    textAlignVertical: TextAlignVertical.top,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: appColors.textPrimary,
                                      height: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Type your answer here...',
                                      hintStyle: TextStyle(
                                        color: appColors.textSecondary
                                            .withValues(alpha: 0.7),
                                      ),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color:
                                _isRecording ? Colors.red : appColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? Colors.red
                                        : appColors.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: _isRecording ? 12 : 10,
                                spreadRadius: _isRecording ? 2 : 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!_isCurrentSubmitted &&
                          _currentAnswer.trim().isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _handleSubmitStep,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      if (_isCurrentSubmitted)
                        ElevatedButton.icon(
                          onPressed: _hasNext
                              ? _handleNext
                              : () {
                                  widget.onCheck?.call();
                                  widget.onNext?.call();
                                },
                          icon: Icon(_hasNext
                              ? Icons.arrow_forward
                              : Icons.check_circle),
                          label: Text(_hasNext ? 'Next' : 'Next question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
