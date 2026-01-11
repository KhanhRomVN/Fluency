import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class ErrorCorrection extends StatefulWidget {
  const ErrorCorrection({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<ErrorCorrection> createState() => _ErrorCorrectionState();
}

class _ErrorCorrectionState extends State<ErrorCorrection> {
  int _currentIndex = 0;

  // Map<ItemID, State>
  final Map<String, _ErrorCorrectionItemState> _itemStates = {};

  // Current edit state
  CorrectionError? _selectedError; // Which error token is selected?
  // We need to track selected token via index if multiple errors map to same index?
  // Or just selected index.
  int? _selectedTokenIndex;

  String _inputValue = '';

  void _onTokenTap(
      ErrorCorrectionItem item, int tokenIndex, CorrectionError? error) {
    if (error == null) {
      // Tapped a non-error token. Nothing happens?
      // Or maybe highlight it as selected but invalid?
      // TSX: `if (!isCompleted && handleTokenClick(item, token))`
      // TSX logic allows selecting any token?
      // `setSelectedTokenIndex(token.index)`
      // If the token is NOT an error, user might guess wrong.
      // TSX checks: `const isError = item.errors.some(e => e.id === token.errorId);`
      // If user selects a token, they can try to correct it.
      // If it's not an actual error, they fail.
      setState(() {
        _selectedTokenIndex = tokenIndex;
        _selectedError =
            null; // No known error at this index (or maybe there is, handled below)
        _inputValue = '';
      });
      return;
    }

    // If it IS an error
    setState(() {
      _selectedTokenIndex = tokenIndex;
      _selectedError = error;
      _inputValue = '';
    });
  }

  void _checkAnswer() {
    // Current item
    final item = widget.quiz.errorCorrections![_currentIndex];
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();

    if (_selectedTokenIndex == null) return;

    // Is there an error at this index?
    final realError =
        item.errors.where((e) => e.index == _selectedTokenIndex).firstOrNull;

    if (realError == null) {
      // User selected a token that is NOT an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That word is correct! Find the error.')),
      );
      // Penalty?
      return;
    }

    // User selected correct error token. Now check their input correction.
    final normalizedInput = _inputValue.trim().toLowerCase();
    final isCorrect =
        realError.correct.map((e) => e.toLowerCase()).contains(normalizedInput);

    if (isCorrect) {
      final newSolved = Set<String>.from(state.solvedErrorIds)
        ..add(realError.id);
      final allSolved = item.errors.every((e) => newSolved.contains(e.id));

      setState(() {
        _itemStates[item.id] = state.copyWith(
          solvedErrorIds: newSolved,
          passed: allSolved,
          feedbackMessage: allSolved ? 'Excellent!' : 'Correct correction!',
          isCorrectFeedback: true,
        );
        _selectedTokenIndex = null;
        _selectedError = null;
        _inputValue = '';
      });
    } else {
      setState(() {
        _itemStates[item.id] = state.copyWith(
          feedbackMessage: 'Incorrect correction. Try again.',
          isCorrectFeedback: false,
        );
      });
    }
  }

  void _next() {
    if (widget.quiz.errorCorrections != null &&
        _currentIndex < widget.quiz.errorCorrections!.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedTokenIndex = null;
        _selectedError = null;
        _inputValue = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.errorCorrections ?? [];

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No error correction items.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    // Show only passed+1 items
    // TSX shows passed items and current.

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.quiz.instruction.isNotEmpty) ...[
                RichTextParser.buildRichText(
                  context,
                  widget.quiz.instruction,
                  onWordLongPress: widget.onWordLongPress,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16),
                ).first,
                const SizedBox(height: 24),
              ],
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                if (index > _currentIndex) return const SizedBox.shrink();

                return _buildCard(context, item, index, appColors);
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ErrorCorrectionItem item, int index,
      AppColorsExtension appColors) {
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();
    final isCurrent = index == _currentIndex;
    final isCompleted = state.passed;

    // Tokenize
    // Simple space tokenizer for MVP. Ideally keep punctuation separate.
    final tokens = item.original.split(' ');

    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isCurrent
              ? appColors.cardBackground
              : appColors.cardBackground.withValues(alpha: 0.5),
          border: Border.all(
              color: isCurrent
                  ? appColors.primary.withValues(alpha: 0.5)
                  : appColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content Flow
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
                children: tokens.asMap().entries.map((entry) {
                  final i = entry.key;
                  final word = entry.value;

                  // Check if this token is an error
                  // Logic assumes `CorrectionError.index` maps to `tokens` index.
                  final error =
                      item.errors.where((e) => e.index == i).firstOrNull;
                  final isError = error != null;
                  final isSolved =
                      isError && state.solvedErrorIds.contains(error.id);

                  final isSelected = isCurrent && _selectedTokenIndex == i;

                  Color bgColor = Colors.transparent;
                  Color textColor = appColors.textPrimary;
                  TextDecoration? decoration;

                  if (isSolved) {
                    // Show CORRECTION instead of original word?
                    // TSX: Shows strikethrough original + array of correct words.
                    // Simplified: Show corrected word in green.
                    // Actually let's show complex view if solved.
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(word,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.red,
                                fontSize: 14,
                              )),
                          const Icon(Icons.arrow_right_alt,
                              size: 14, color: Colors.green),
                          Text(
                            error!.correct.first,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isSelected) {
                    bgColor = appColors.primary.withValues(alpha: 0.1);
                    // if incorrect feedback
                    if (!state.isCorrectFeedback &&
                        state.feedbackMessage.isNotEmpty) {
                      bgColor = Colors.red.withValues(alpha: 0.1);
                    }
                  }

                  return GestureDetector(
                    onTap:
                        isCompleted ? null : () => _onTokenTap(item, i, error),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? Border.all(color: appColors.primary)
                            : null,
                      ),
                      child: Text(word,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              decoration: decoration)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Area (if token selected)
            if (isCurrent && _selectedTokenIndex != null && !isCompleted)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (val) {
                        _inputValue = val;
                      },
                      onSubmitted: (_) => _checkAnswer(),
                      decoration: InputDecoration(
                        hintText: 'Type correction...',
                        filled: true,
                        fillColor: appColors.inputBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: _checkAnswer,
                        ),
                      ),
                    ),
                    if (state.feedbackMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.feedbackMessage,
                          style: TextStyle(
                            color: state.isCorrectFeedback
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Success / Next
            if (isCompleted && isCurrent)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('All errors corrected!',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (index < (widget.quiz.errorCorrections?.length ?? 0) - 1)
                      ElevatedButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ));
  }
}

class _ErrorCorrectionItemState {
  final Set<String> solvedErrorIds;
  final bool passed;
  final String feedbackMessage;
  final bool isCorrectFeedback;

  _ErrorCorrectionItemState({
    this.solvedErrorIds = const {},
    this.passed = false,
    this.feedbackMessage = '',
    this.isCorrectFeedback = true,
  });

  _ErrorCorrectionItemState copyWith({
    Set<String>? solvedErrorIds,
    bool? passed,
    String? feedbackMessage,
    bool? isCorrectFeedback,
  }) {
    return _ErrorCorrectionItemState(
      solvedErrorIds: solvedErrorIds ?? this.solvedErrorIds,
      passed: passed ?? this.passed,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      isCorrectFeedback: isCorrectFeedback ?? this.isCorrectFeedback,
    );
  }
}
