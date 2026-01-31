import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeakingEssay extends StatefulWidget {
  const SpeakingEssay({
    required this.quiz,
    super.key,
    this.onWordLongPress,
    this.onCheck,
    this.onNext,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;

  @override
  State<SpeakingEssay> createState() => _SpeakingEssayState();
}

class _SpeakingEssayState extends State<SpeakingEssay> {
  int _activeIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _stepSubmitted = {};

  bool _isRecording = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _currentTranscript = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
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
    // Get STT settings from provider
    final sttProvider = context.read<SttSettingProvider>();
    String localeId = 'en_US'; // default

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
    );
    setState(() {
      _isRecording = true;
      _currentTranscript = '';
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isRecording = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    debugPrint(
        'SpeakingEssay STT Result: "${result.recognizedWords}" (Final: ${result.finalResult})');
    setState(() {
      _currentTranscript = result.recognizedWords;
      if (result.finalResult) {
        debugPrint('SpeakingEssay STT Final: "$_currentTranscript"');
        final existingText = _answers[_activeIndex] ?? '';
        final separator = existingText.isEmpty ? '' : ' ';
        _answers[_activeIndex] = '$existingText$separator$_currentTranscript';
        _currentTranscript = '';
        _isRecording = false;
      }
    });
  }

  void _handleSubmitStep() {
    setState(() {
      _stepSubmitted[_activeIndex] = true;
      _isRecording = false;
    });
  }

  void _handleNext() {
    if (_hasNext) {
      setState(() {
        _activeIndex++;
        _isRecording = false;
      });
    } else {
      // Finish
      // emulate finish?
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
    final questionText = _getQuestionText(_currentQuestion);
    final example = _getExample(_currentQuestion);

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent handles background
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                120,
              ), // Bottom padding for floating controls
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Display (as Instruction text at top)
                  if (questionText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        questionText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: appColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                  // Input Area (Expanded Card)
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
                      child: _isCurrentSubmitted
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _currentAnswer,
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
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sample Answer',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: appColors.textPrimary,
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
                                        border:
                                            Border.all(color: appColors.border),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: RichTextParser.buildRichText(
                                        context,
                                        example,
                                        onWordLongPress: (text) {
                                          widget.onWordLongPress?.call(text);
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
                                text: _isRecording
                                    ? (_currentAnswer.isEmpty
                                        ? _currentTranscript
                                        : '$_currentAnswer $_currentTranscript')
                                    : _currentAnswer,
                              )..selection = TextSelection.collapsed(
                                  offset: _isRecording
                                      ? (_currentAnswer.isEmpty
                                          ? _currentTranscript.length
                                          : '$_currentAnswer $_currentTranscript'
                                              .length)
                                      : _currentAnswer.length,
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
                                contentPadding: EdgeInsets.zero,
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
                // Mic Button
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56, // 14 * 4 = 56px (tailwind w-14)
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : appColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : appColors.primary)
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

                // Submit / Next Button
                if (!_isCurrentSubmitted && _currentAnswer.trim().isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _handleSubmitStep,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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
                    icon: _hasNext
                        ? const Icon(
                            Icons.arrow_forward,
                          ) // Right arrow for next
                        : const Icon(Icons.check_circle), // Check for finish
                    label: Text(_hasNext ? 'Next' : 'Next question'),
                    // Icon and Label swap in Flutter is manual, Directionality or just Swap children
                    // TSX: Next <ChevronRight>
                    iconAlignment: IconAlignment
                        .end, // New in Flutter 3.24+? Or manually swap
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
