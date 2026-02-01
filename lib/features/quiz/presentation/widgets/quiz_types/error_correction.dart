import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/explain_drawer.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ErrorCorrection extends StatefulWidget {
  const ErrorCorrection({
    required this.quiz,
    required this.lessonId,
    this.onNext,
    this.onPrev,
    this.onWordLongPress,
    this.onCheck,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  @override
  State<ErrorCorrection> createState() => _ErrorCorrectionState();
}

class _ErrorCorrectionState extends State<ErrorCorrection> {
  int _currentIndex = 0;

  // Map<ItemID, State>
  final Map<String, _ErrorCorrectionItemState> _itemStates = {};

  // Selection state
  int? _selectedTokenIndex;
  CorrectionError? _selectedError;
  String _inputValue = '';

  // Controllers
  late TextEditingController _inputController;

  bool _showExplanation = false;

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      // Reset interaction state for new item
      _selectedTokenIndex = null;
      _selectedError = null;
      _inputValue = '';
      _inputController.clear();
      _showExplanation = false;
    });
    _saveProgress();
  }

  void _animateToNextQuestion() {
    if (_currentIndex < (widget.quiz.errorCorrections?.length ?? 0) - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onTokenTap(ErrorCorrectionItem item, int tokenIndex) {
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();
    if (state.passed) return; // Prevent interaction if already passed

    // Identify if this token corresponds to an actual error
    final error = item.errors.where((e) => e.index == tokenIndex).firstOrNull;

    setState(() {
      _selectedTokenIndex = tokenIndex;
      _selectedError = error;

      // Load saved correction if exists
      _inputValue = state.corrections[tokenIndex] ?? '';
      _inputController.text = _inputValue;
      // Ensure cursor is at end
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );

      // Reset feedback for this new attempt selection (optional, or keep generic)
      _itemStates[item.id] = state.copyWith(
        feedbackMessage: '',
        isCorrectFeedback: true, // Reset to neutral
      );
    });
  }

  void _checkAnswer() {
    final item = widget.quiz.errorCorrections![_currentIndex];
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();

    if (_selectedTokenIndex == null) return;

    // 1. Check if the selected token IS an error
    if (_selectedError == null) {
      // User selected a word that is NOT an error
      final tokens = item.original.split(RegExp(r'\s+'));
      final errorDescriptions = item.errors.map((e) {
        final incorrectWord = tokens[e.index];
        final correctWord = e.correct.first;
        return '$incorrectWord -> $correctWord';
      }).join(', ');

      setState(() {
        _itemStates[item.id] = state.copyWith(
          feedbackMessage: 'That word is correct. Error: $errorDescriptions',
          isCorrectFeedback: false,
        );
        _selectedTokenIndex = null;
        _selectedError = null;
        _inputValue = '';
        _inputController.clear();
        _saveProgress();
      });
      return;
    }

    // 2. Check if the input correction is correct
    final normalizedInput = _inputValue.trim().toLowerCase();

    // Support multiple valid answers
    final isCorrect = _selectedError!.correct
        .map((e) => e.toLowerCase())
        .contains(normalizedInput);

    if (isCorrect) {
      final newSolved = Set<String>.from(state.solvedErrorIds)
        ..add(_selectedError!.id);
      final allSolved = item.errors.every((e) => newSolved.contains(e.id));

      setState(() {
        _itemStates[item.id] = state.copyWith(
          solvedErrorIds: newSolved,
          passed: allSolved,
          feedbackMessage: allSolved ? 'Excellent!' : 'Correct!',
          isCorrectFeedback: true,
        );
        _selectedTokenIndex = null;
        _selectedError = null;
        _inputValue = '';
        _inputController.clear();
        _saveProgress();
      });
    } else {
      setState(() {
        _itemStates[item.id] = state.copyWith(
          feedbackMessage:
              'Incorrect. Correct answer: ${_selectedError!.correct.join(" / ")}',
          isCorrectFeedback: false,
        );
        _saveProgress();
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Serialize states
    final statesMap = _itemStates.map((key, value) {
      return MapEntry(key, {
        'solvedErrorIds': value.solvedErrorIds.toList(),
        'passed': value.passed,
        'feedbackMessage': value.feedbackMessage,
        'isCorrectFeedback': value.isCorrectFeedback,
        'corrections':
            value.corrections.map((k, v) => MapEntry(k.toString(), v)),
      });
    });

    final totalItems = widget.quiz.errorCorrections?.length ?? 0;
    // Count completed as items where user made any correction entry or passed
    final completedItems = _itemStates.values
        .where((s) => s.corrections.isNotEmpty || s.passed)
        .length;
    final correctItems = _itemStates.values.where((s) => s.passed).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz
          .id, // ErrorCorrection widget uses quiz.id (from constructor usage generally) but let's check.
      // Constructor: required this.quiz. No quizId param in widget?
      // Wait, ErrorCorrection widget definition:
      // class ErrorCorrection extends StatefulWidget { const ErrorCorrection({ required this.quiz, ... });
      // No quizId field?
      // Check `_loadProgress`: `widget.quiz.id`.
      // Yes, widget.quiz.id.
      quizType: 'error-correction',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'currentIndex': _currentIndex,
        'itemStates': statesMap,
      },
    );
  }

  void _retryCurrent() {
    final item = widget.quiz.errorCorrections![_currentIndex];
    setState(() {
      _itemStates[item.id] = _ErrorCorrectionItemState(); // Reset state
      _selectedTokenIndex = null;
      _selectedError = null;
      _inputValue = '';
      _inputController.clear();
      _saveProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.errorCorrections ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    final currentItem = items[_currentIndex];
    final currentState =
        _itemStates[currentItem.id] ?? _ErrorCorrectionItemState();

    return Column(
      children: [
        // 1. Instruction (Rich Text)

        // 2. The Card Area
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is OverscrollNotification) {
                if (notification.overscroll < 0) {
                  widget.onPrev?.call();
                } else if (notification.overscroll > 0) {
                  widget.onNext?.call();
                }
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final state =
                    _itemStates[item.id] ?? _ErrorCorrectionItemState();

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Stack(
                    children: [
                      // The Card
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CustomPaint(
                          painter: _DashedBorderPainter(
                            color: appColors.border,
                            strokeWidth: 1.5,
                            gap: 4,
                            borderRadius: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Card Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${index + 1} / ${items.length}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: appColors.textSecondary,
                                      ),
                                    ),
                                    // Score/State Indicator (Circle)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border:
                                            Border.all(color: appColors.border),
                                      ),
                                      child: Text(
                                        state.passed ? '✓' : '0',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: state.passed
                                              ? Colors.green
                                              : appColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: appColors.border),

                              // Card Content (Sentence)
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 24, 24, 100),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildTokens(
                                        item,
                                        state,
                                        appColors,
                                      ),

                                      // Input Area (Animated)
                                      if (!state.passed &&
                                          _selectedTokenIndex != null)
                                        _buildInputArea(
                                          appColors,
                                          state,
                                          item,
                                        ),

                                      // Feedback Message
                                      if (state.feedbackMessage.isNotEmpty)
                                        _buildFeedbackMessage(
                                          appColors,
                                          state,
                                          item,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating Action Buttons
                      Positioned(
                        bottom: 28,
                        right: 36,
                        child: _buildActionButtons(
                          appColors,
                          state,
                          item,
                          items,
                        ),
                      ),

                      // Explain Drawer
                      if (item.explain != null)
                        ExplainDrawer(
                          isOpen: _showExplanation,
                          onClose: () =>
                              setState(() => _showExplanation = false),
                          explanation: item.explain!,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokens(
    ErrorCorrectionItem item,
    _ErrorCorrectionItemState state,
    AppColorsExtension appColors,
  ) {
    // Splits by whitespace to get tokens.
    // NOTE: This assumes 'original' text in item is space-separated correctly.
    final tokens = item.original.split(RegExp(r'\s+'));

    return Wrap(
      spacing: 8,
      runSpacing: 14,
      children: tokens.asMap().entries.map((entry) {
        final i = entry.key;
        final word = entry.value;
        if (word.isEmpty) return const SizedBox.shrink();

        // Is this token an error?
        final error = item.errors.where((e) => e.index == i).firstOrNull;
        final isError = error != null;
        final isSolved = isError &&
            (state.solvedErrorIds.contains(error.id) || state.passed);

        final isSelected = _selectedTokenIndex == i;

        if (isSolved) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red.withValues(alpha: 0.5),
                    color: Colors.red.withValues(alpha: 0.7),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  error.correct.first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        final Widget wordWidget = GestureDetector(
          onTap: () => _onTokenTap(item, i),
          child: CustomPaint(
            painter: isSelected
                ? _DashedBorderPainter(
                    color: state.isCorrectFeedback
                        ? appColors.textSecondary
                        : Colors.red,
                    strokeWidth: 1.5,
                    gap: 3,
                    borderRadius: 8,
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? (state.isCorrectFeedback
                        ? appColors.textSecondary.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        );

        final savedCorrection = state.corrections[i] ?? '';
        final displayValue = isSelected ? _inputValue : savedCorrection;

        if (displayValue.isNotEmpty &&
            !state.passed &&
            (isSelected || savedCorrection.isNotEmpty)) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              wordWidget,
              const SizedBox(width: 4),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: state.isCorrectFeedback
                    ? appColors.textSecondary
                    : Colors.red,
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isCorrectFeedback
                      ? appColors.textSecondary.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.isCorrectFeedback
                        ? appColors.textSecondary.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: state.isCorrectFeedback
                        ? appColors.textSecondary
                        : Colors.red,
                  ),
                ),
              ),
            ],
          );
        }

        return wordWidget;
      }).toList(),
    );
  }

  Widget _buildInputArea(
    AppColorsExtension appColors,
    _ErrorCorrectionItemState state,
    ErrorCorrectionItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomPaint(
            painter: _DashedBorderPainter(
              color: state.isCorrectFeedback ? appColors.primary : Colors.red,
              strokeWidth: 1.5,
              gap: 4,
              borderRadius: 12,
            ),
            child: TextField(
              controller: _inputController,
              autofocus: true,
              onChanged: (val) {
                setState(() {
                  _inputValue = val;
                  if (_selectedTokenIndex != null) {
                    final newCorrections =
                        Map<int, String>.from(state.corrections);
                    if (val.isEmpty) {
                      newCorrections.remove(_selectedTokenIndex);
                    } else {
                      newCorrections[_selectedTokenIndex!] = val;
                    }
                    _itemStates[item.id] =
                        state.copyWith(corrections: newCorrections);
                  }
                });
              },
              onSubmitted: (_) => _checkAnswer(),
              style: TextStyle(fontSize: 16, color: appColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type correction...',
                hintStyle: TextStyle(color: appColors.textSecondary),
                filled: true,
                fillColor: appColors.inputBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: appColors.primary,
                  onPressed: _checkAnswer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackMessage(
    AppColorsExtension appColors,
    _ErrorCorrectionItemState state,
    ErrorCorrectionItem item,
  ) {
    final isSuccess = state.isCorrectFeedback;
    final color = isSuccess ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.feedbackMessage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (item.explain != null && item.explain!.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showExplanation = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  'Explain',
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    AppColorsExtension appColors,
    _ErrorCorrectionItemState state,
    ErrorCorrectionItem currentItem,
    List<ErrorCorrectionItem> items,
  ) {
    if (state.passed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _retryCurrent,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: appColors.buttonSecondBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  Icon(Icons.refresh, color: appColors.textSecondary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
        ],
      );
    }

    if (_selectedTokenIndex != null) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _checkAnswer,
          icon: const Icon(Icons.check, size: 20),
          label: const Text('Check Answer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ErrorCorrectionItemState {
  _ErrorCorrectionItemState({
    this.solvedErrorIds = const {},
    this.passed = false,
    this.feedbackMessage = '',
    this.isCorrectFeedback = true,
    this.corrections = const {},
  });
  final Set<String> solvedErrorIds;
  final bool passed;
  final String feedbackMessage;
  final bool isCorrectFeedback;
  final Map<int, String> corrections;

  _ErrorCorrectionItemState copyWith({
    Set<String>? solvedErrorIds,
    bool? passed,
    String? feedbackMessage,
    bool? isCorrectFeedback,
    Map<int, String>? corrections,
  }) {
    return _ErrorCorrectionItemState(
      solvedErrorIds: solvedErrorIds ?? this.solvedErrorIds,
      passed: passed ?? this.passed,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      isCorrectFeedback: isCorrectFeedback ?? this.isCorrectFeedback,
      corrections: corrections ?? this.corrections,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.gap = 5,
    this.borderRadius = 0,
  });
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashedPath = _dashPath(path, width: 8, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = (distance + width < metric.length)
            ? width
            : metric.length - distance;
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += width + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
