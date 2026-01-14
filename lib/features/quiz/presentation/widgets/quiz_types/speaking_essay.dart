import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SpeakingEssay extends StatefulWidget {
  const SpeakingEssay({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<SpeakingEssay> createState() => _SpeakingEssayState();
}

class _SpeakingEssayState extends State<SpeakingEssay> {
  int _activeIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _stepSubmitted = {};

  bool _isRecording = false;

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
    setState(() {
      _isRecording = !_isRecording;

      // Mock recording logic: in a real app this would start/stop recorder
      if (!_isRecording && !_isCurrentSubmitted) {
        // In TSX, toggling recording doesn't auto-submit or auto-fill text usually,
        // but maybe it transcribes?
        // TSX: setIsRecording(!isRecording). That's it.
        // It doesn't auto-transcribe in the TSX snippet provided (it seems manual mock or just recording state).
        // Left screenshot shows "Tap to speak".
        // We will just toggle state.
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
                  16, 16, 16, 120), // Bottom padding for floating controls
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
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]),
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
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sample Answer',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: appColors.textPrimary),
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
                                  ]
                                ],
                              ),
                            )
                          : TextField(
                              controller:
                                  TextEditingController(text: _currentAnswer)
                                    ..selection = TextSelection.collapsed(
                                        offset: _currentAnswer.length),
                              onChanged: _handleTextChange,
                              expands: true,
                              maxLines: null,
                              minLines: null,
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
                                        .withOpacity(0.7)),
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
            bottom: 24,
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
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
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
                          horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
                            // Finish logic
                          },
                    icon: _hasNext
                        ? const Icon(
                            Icons.arrow_forward) // Right arrow for next
                        : const Icon(Icons.check_circle), // Check for finish
                    label: Text(_hasNext ? 'Next' : 'Finish'),
                    // Icon and Label swap in Flutter is manual, Directionality or just Swap children
                    // TSX: Next <ChevronRight>
                    iconAlignment: IconAlignment
                        .end, // New in Flutter 3.24+? Or manually swap
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
