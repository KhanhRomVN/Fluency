import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';

class Speaking extends StatefulWidget {
  const Speaking({
    super.key,
    required this.quiz,
  });

  final Quiz quiz;

  @override
  State<Speaking> createState() => _SpeakingState();
}

class _SpeakingState extends State<Speaking> {
  int _activeIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _stepSubmitted = {};
  bool _isRecording = false;

  late final List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.quiz.questions.isNotEmpty
        ? widget.quiz.questions
        : [
            QuizQuestion(
              id: widget.quiz.id,
              question: widget.quiz.question,
              options: const [],
              answer: '',
              validAnswers: const [],
              explain: '',
            )
          ];
  }

  bool get _hasNext => _activeIndex < _questions.length - 1;
  String get _currentAnswer => _answers[_activeIndex] ?? '';
  bool get _isCurrentSubmitted => _stepSubmitted[_activeIndex] ?? false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _handleSubmitStep() {
    setState(() {
      _stepSubmitted[_activeIndex] = true;
      _isRecording = false;
    });
  }

  void _handleNext() {
    setState(() {
      _activeIndex++;
      _isRecording = false;
    });
  }

  void _handleFinish() {}

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final currentQuestion = _questions[_activeIndex];

    return Stack(
      children: [
        // Main Content
        Positioned.fill(
          bottom: 100,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Question
              if (currentQuestion.question.isNotEmpty)
                Text(
                  currentQuestion.question,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: appColors.textPrimary,
                        height: 1.5,
                      ),
                ),
              const SizedBox(height: 16),

              // Answer Input
              Text(
                'Your Answer / Notes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),

              if (_isCurrentSubmitted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentAnswer.isEmpty
                        ? '(No answer provided)'
                        : _currentAnswer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appColors.textPrimary,
                          fontStyle: _currentAnswer.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                  ),
                )
              else
                TextField(
                  maxLines: 8,
                  controller: TextEditingController(text: _currentAnswer),
                  onChanged: (value) {
                    setState(() {
                      _answers[_activeIndex] = value;
                    });
                  },
                  enabled: !_isCurrentSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    hintStyle: TextStyle(color: appColors.textSecondary),
                    filled: true,
                    fillColor: appColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: appColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: appColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: appColors.primary, width: 2),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appColors.textPrimary,
                      ),
                ),

              // Sample Answer (shown after submit)
              if (_isCurrentSubmitted &&
                  widget.quiz.example != null &&
                  widget.quiz.example!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sample Answer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    color: appColors.cardBackground.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appColors.border),
                  ),
                  child: Text(
                    widget.quiz.example!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appColors.textPrimary,
                          height: 1.6,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Floating Bottom Controls
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: appColors.background.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: appColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mic Toggle
                  IconButton(
                    onPressed: _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.mic_off : Icons.mic,
                      color:
                          _isRecording ? Colors.white : appColors.textPrimary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isRecording ? Colors.red : appColors.cardBackground,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Submit or Next Button
                  if (!_isCurrentSubmitted && _currentAnswer.trim().isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _handleSubmitStep,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),

                  if (_isCurrentSubmitted)
                    ElevatedButton.icon(
                      onPressed: _hasNext ? _handleNext : _handleFinish,
                      icon: Icon(
                        _hasNext ? Icons.chevron_right : Icons.check_circle,
                        size: 20,
                      ),
                      label: Text(_hasNext ? 'Next' : 'Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
