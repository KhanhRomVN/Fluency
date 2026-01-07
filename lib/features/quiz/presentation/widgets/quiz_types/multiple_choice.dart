import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class MultipleChoice extends StatefulWidget {
  const MultipleChoice({
    required this.quiz,
    this.onCheck,
    this.onShowExplain,
    super.key,
  });

  final Quiz quiz;
  final VoidCallback? onCheck;
  final void Function(String explanation)? onShowExplain;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  // Key: Question ID, Value: Set of selected option keys
  final Map<String, Set<String>> _selectedOptions = {};
  bool _isChecked = false;
  bool _areAllAnswered = false;

  void _onOptionSelected(QuizQuestion question, String optionKey) {
    if (_isChecked) return;

    final questionId = question.id;
    final isMultiSelect = question.validAnswers.length > 1;

    setState(() {
      if (!_selectedOptions.containsKey(questionId)) {
        _selectedOptions[questionId] = {};
      }

      final selectedSet = _selectedOptions[questionId]!;

      if (isMultiSelect) {
        // Toggle selection
        if (selectedSet.contains(optionKey)) {
          selectedSet.remove(optionKey);
        } else {
          selectedSet.add(optionKey);
        }
      } else {
        // Radio behavior
        selectedSet.clear();
        selectedSet.add(optionKey);
      }

      _checkIfAllAnswered();
    });
  }

  void _checkIfAllAnswered() {
    // Ideally check if user selected correct amount of answers?
    // For now, just check if at least one option is selected per question.
    final allAnswered = widget.quiz.questions.every(
      (q) =>
          _selectedOptions.containsKey(q.id) &&
          _selectedOptions[q.id]!.isNotEmpty,
    );
    if (allAnswered != _areAllAnswered) {
      setState(() {
        _areAllAnswered = allAnswered;
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

    // Determine correctness for score/feedback if needed
    // currently just visual feedback per item

    return Stack(
      children: [
        Column(
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
            if (_areAllAnswered && !_isChecked)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isChecked = true;
                      });
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
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionItem(BuildContext context, QuizQuestion question,
      AppColorsExtension appColors) {
    final selectedSet = _selectedOptions[question.id] ?? {};

    // Logic: A question is correct if selectedSet matches validAnswers
    // But individual option coloring depends on:
    // 1. Is it a valid answer?
    // 2. Is it selected?

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
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final optionText = entry.value;
            final optionKey = String.fromCharCode(65 + index); // 65 = 'A'

            final isSelected = selectedSet.contains(optionKey);

            // Check if this specific option is one of the correct answers
            final isCorrectOption = question.validAnswers.contains(optionKey) ||
                question.validAnswers.contains(optionText);

            Color borderColor = appColors.border;
            Color backgroundColor = Colors.transparent;
            Color textColor = appColors.textPrimary;
            IconData? statusIcon;
            Color? iconColor;

            if (_isChecked) {
              if (isCorrectOption) {
                // Correct answer(s) should always be green
                borderColor = appColors.primary;
                backgroundColor = appColors.primary.withValues(alpha: 0.1);
                textColor = appColors.primary;
                statusIcon = Icons.check;
                iconColor = Colors.white;
              } else if (isSelected && !isCorrectOption) {
                // User chose this, but it's wrong -> Red
                borderColor = Colors.red;
                backgroundColor = Colors.red.withValues(alpha: 0.1);
                textColor = Colors.red;
                statusIcon = Icons.close;
                iconColor = Colors.white;
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
                onTap: () => _onOptionSelected(question, optionKey),
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
                          color: _isChecked
                              ? (isCorrectOption
                                  ? appColors.primary
                                  : (isSelected
                                      ? Colors.red
                                      : Colors.transparent))
                              : (isSelected
                                  ? appColors.primary
                                  : Colors.transparent),
                          border: Border.all(
                            color: _isChecked
                                ? (isCorrectOption
                                    ? appColors.primary
                                    : (isSelected
                                        ? Colors.red
                                        : appColors.border))
                                : (isSelected
                                    ? appColors.primary
                                    : appColors.border),
                            width: 2,
                          ),
                        ),
                        child: statusIcon != null && _isChecked
                            ? Icon(statusIcon, size: 16, color: iconColor)
                            : (isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : Text(
                                    optionKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: appColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
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

  Widget _buildRichText(BuildContext context, String content) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: RichTextParser.buildRichText(context, content),
    );
  }

  void _showExplanation(BuildContext context, QuizQuestion question) {
    final explanation = question.explain.isNotEmpty
        ? question.explain
        : '<p>No explanation available.</p>';
    widget.onShowExplain?.call(explanation);
  }
}
