import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class QuizBuilder extends StatefulWidget {
  const QuizBuilder({
    required this.quiz,
    super.key,
    this.onCheck,
    this.onNext,
    this.onShowExplain,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;

  @override
  State<QuizBuilder> createState() => _QuizBuilderState();
}

class _QuizBuilderState extends State<QuizBuilder> {
  int _currentIndex = 0;
  // Key: Question ID, Value: List of selected indices from the options pool
  final Map<String, List<int>> _selectedIndices = {};
  // Map<QuestionID, isCorrect>
  final Map<String, bool?> _correctness = {};
  final Map<String, bool> _isCheckedMap = {};

  QuizQuestion? get _currentItem => widget.quiz.questions.isNotEmpty
      ? widget.quiz.questions[_currentIndex]
      : null;

  List<int> get _currentSelected => _selectedIndices[_currentItem?.id] ?? [];
  bool get _currentIsChecked => _isCheckedMap[_currentItem?.id] ?? false;
  bool? get _currentIsCorrect => _correctness[_currentItem?.id];

  void _handleItemClick(int itemIndex) {
    final currentItem = _currentItem;
    if (currentItem == null || _currentIsChecked) return;

    setState(() {
      final selected = List<int>.from(_currentSelected);

      // If already selected, allow removing (last one only)
      if (selected.contains(itemIndex)) {
        if (selected.isNotEmpty && selected.last == itemIndex) {
          selected.removeLast();
        }
      } else {
        // Add to selection
        selected.add(itemIndex);
      }

      _selectedIndices[currentItem.id] = selected;
    });
  }

  void _checkAnswer() {
    final currentItem = _currentItem;
    if (currentItem == null) return;

    final options = currentItem.options;
    final builtSentence = _currentSelected.map((i) => options[i]).join(' ');
    final normalizedBuilt =
        builtSentence.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final isCorrect = currentItem.validAnswers.any((ans) {
      final normalizedAns =
          ans.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      return normalizedAns == normalizedBuilt;
    });

    setState(() {
      _correctness[currentItem.id] = isCorrect;
      _isCheckedMap[currentItem.id] = true;
    });

    widget.onCheck?.call();
  }

  void _resetCurrent() {
    final currentItem = _currentItem;
    if (currentItem == null) return;

    setState(() {
      _selectedIndices[currentItem.id] = [];
      _correctness[currentItem.id] = null;
      _isCheckedMap[currentItem.id] = false;
    });
  }

  void _goToNext() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  String _getCorrectString() {
    final currentItem = _currentItem;
    if (currentItem == null) return '';
    return currentItem.validAnswers.firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final questions = widget.quiz.questions;

    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No builder items available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentItem = _currentItem!;
    final options = currentItem.options;
    final hint = currentItem.question; // Using question field as hint

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
                  Wrap(
                    children: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                      onWordLongPress: widget.onWordLongPress,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16),
                    ),
                  ),
                  Divider(height: 32, color: appColors.border),
                ],

                // Context Hint (with lightbulb icon)
                if (hint.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appColors.cardBackground.withValues(alpha: 0.5),
                      border: Border.all(color: appColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '💡 $hint',
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Built Sentence Display (Dashed Border)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentIsChecked
                        ? (_currentIsCorrect ?? false
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1))
                        : appColors.cardBackground,
                    border: Border.all(
                      color: _currentIsChecked
                          ? (_currentIsCorrect ?? false
                              ? Colors.green
                              : Colors.red)
                          : appColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _currentSelected.isEmpty
                      ? Center(
                          child: Text(
                            'Tap blocks below to build',
                            style: TextStyle(
                              color: appColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentSelected.map((index) {
                            return GestureDetector(
                              onTap: () => _handleItemClick(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentIsChecked
                                      ? appColors.background
                                      : appColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  options[index],
                                  style: TextStyle(
                                    color: _currentIsChecked
                                        ? appColors.textPrimary
                                        : Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),

                // Correct Answer (shown after check if wrong)
                if (_currentIsChecked && _currentIsCorrect == false) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correct answer:',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCorrectString(),
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Explanation Button
                if (_currentIsChecked && currentItem.explain.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        widget.onShowExplain?.call(currentItem.explain);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 16,
                            color: appColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Explain',
                            style: TextStyle(
                              color: appColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Item Blocks (Available Words)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final word = entry.value;
                      final isSelected = _currentSelected.contains(index);

                      return GestureDetector(
                        onTap: () => _handleItemClick(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected || _currentIsChecked ? 0.5 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? appColors.background
                                  : appColors.cardBackground,
                              border: Border.all(
                                color: appColors.border,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                color: isSelected
                                    ? appColors.textSecondary
                                    : appColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: appColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Column(
            children: [
              // Reset Button (always visible if not correct)
              if (_currentIsCorrect != true)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _resetCurrent,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: appColors.textSecondary,
                      backgroundColor: appColors.cardBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Check Button (visible when all items selected and not checked)
              if (!_currentIsChecked &&
                  _currentSelected.length == options.length)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Check'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Next Button (visible after checking)
              if (_currentIsChecked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentIndex < widget.quiz.questions.length - 1) {
                        _goToNext();
                      } else {
                        widget.onCheck?.call();
                        widget.onNext?.call();
                      }
                    },
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: const Text('Next question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
