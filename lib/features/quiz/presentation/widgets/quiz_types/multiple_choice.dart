import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class MultipleChoice extends StatefulWidget {
  const MultipleChoice({
    required this.quiz,
    this.onCheck,
    super.key,
  });

  // Accepting the whole Quiz object since MC might need access to nested 'questions'
  // which might not be fully parsed by the current Quiz model yet.
  // Ideally, we'd pass a specific MultipleChoiceData object.
  final Quiz quiz;
  final VoidCallback? onCheck;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  // Map of question ID to selected option key (e.g. 'question_01' -> 'A')
  final Map<String, String> _selectedAnswers = {};
  bool _isChecked = false;
  bool _areAllQuestionsAnswered = false;

  void _onOptionSelected(String questionId, String optionKey) {
    if (_isChecked) return; // Disable changes after checking

    setState(() {
      _selectedAnswers[questionId] = optionKey;
      _checkIfAllAnswered();
    });
  }

  void _checkIfAllAnswered() {
    final allAnswered = widget.quiz.questions.every(
      (q) => _selectedAnswers.containsKey(q.id),
    );
    if (allAnswered != _areAllQuestionsAnswered) {
      setState(() {
        _areAllQuestionsAnswered = allAnswered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final questions = widget.quiz.questions;

    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: appColors.textPrimary,
              ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruction
                if (widget.quiz.instruction.isNotEmpty) ...[
                  _buildRichText(context, widget.quiz.instruction),
                  const SizedBox(height: 16),
                ],
                // Questions List
                ...questions.map((question) {
                  return _buildQuestionItem(context, question, appColors);
                }),
              ],
            ),
          ),
        ),
        // Check Answers Button
        if (_areAllQuestionsAnswered && !_isChecked)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isChecked = true;
                  });
                  debugPrint(
                      'AG_LOG: MultipleChoice Check Answers pressed. Calling widget.onCheck');
                  widget.onCheck?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Check answers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        // If checked, maybe show score or just leave it visually marked
      ],
    );
  }

  Widget _buildQuestionItem(BuildContext context, QuizQuestion question,
      AppColorsExtension appColors) {
    final selectedOptionKey = _selectedAnswers[question.id];
    final isCorrect = selectedOptionKey == question.answer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          // Options
          ...question.options.map((option) {
            final isSelected = selectedOptionKey == option.key;
            final isAnswerCorrect = option.key == question.answer;

            Color borderColor = appColors.border;
            Color backgroundColor = Colors.transparent;
            Color textColor = appColors.textPrimary;

            if (_isChecked) {
              if (isAnswerCorrect) {
                // Always highlight the correct answer in Green
                borderColor = appColors.primary;
                backgroundColor = appColors.primary.withValues(alpha: 0.1);
                textColor = appColors.primary;
              } else if (isSelected && !isCorrect) {
                // Highlight incorrect selection in Red
                borderColor = Colors.red;
                backgroundColor = Colors.red.withValues(alpha: 0.1);
                textColor = Colors.red;
              }
            } else {
              if (isSelected) {
                borderColor = appColors.primary;
                backgroundColor = appColors.primary.withValues(alpha: 0.1);
                textColor = appColors.primary;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _onOptionSelected(question.id, option.key),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isChecked && isAnswerCorrect
                              ? appColors.primary
                              : (isSelected
                                  ? appColors.primary
                                  : Colors.transparent),
                          border: Border.all(
                            color: _isChecked && isAnswerCorrect
                                ? appColors.primary
                                : (isSelected
                                    ? appColors.primary
                                    : appColors.border),
                            width: 2,
                          ),
                        ),
                        child: (isSelected || (_isChecked && isAnswerCorrect))
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text(
                                option.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // Explanation Button (if checked)
          if (_isChecked)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () => _showExplanation(context, question),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: appColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      "Explain",
                      style: TextStyle(
                        color: appColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Helper to build rich text using the shared RichTextParser
  Widget _buildRichText(BuildContext context, String content) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: RichTextParser.buildRichText(context, content),
    );
  }

  void _showExplanation(BuildContext context, QuizQuestion question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: appColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Explanation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children:
                        RichTextParser.buildRichText(context, question.explain),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
