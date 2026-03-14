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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quiz.id,
    );

    if (progress != null && mounted) {
      setState(() {
        _currentIndex = progress.data?['currentIndex'] as int? ?? 0;

        final savedStates =
            progress.data?['itemStates'] as Map<String, dynamic>?;
        if (savedStates != null) {
          savedStates.forEach((key, value) {
            final data = value as Map<String, dynamic>;
            _itemStates[key] = _ErrorCorrectionItemState(
              solvedErrorIds:
                  (data['solvedErrorIds'] as List?)?.cast<String>().toSet() ??
                      {},
              passed: data['passed'] as bool? ?? false,
              feedbackMessage: data['feedbackMessage'] as String? ?? '',
              isCorrectFeedback: data['isCorrectFeedback'] as bool? ?? true,
              corrections: (data['corrections'] as Map<String, dynamic>?)?.map(
                    (k, v) => MapEntry(int.parse(k), v as String),
                  ) ??
                  {},
            );
          });
        }
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      });
    }
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
      _selectedTokenIndex = null;
      _selectedError = null;
      _inputValue = '';
      _inputController.clear();
      _showExplanation = false;
    });
    _saveProgress();
  }

  List<_Token> _parseTokens(ErrorCorrectionItem item) {
    // If the original text is likely not HTML-tagged (legacy), fallback to split?
    // But we assume updated content.
    final tokens = <_Token>[];
    int tokenCounter = 0;

    // Regex to match <error> or <p> blocks
    // Captures: 1=attributes, 2=content
    final blockRegex = RegExp(
      r"<(?:error|p)\b([^>]*)>(.*?)<\/(?:error|p)>",
      caseSensitive: false,
      dotAll: true,
    );

    final brRegex = RegExp(r"<br\s*/?>", caseSensitive: false);

    void addTextTokens(
        String text, bool isError, String? errorId, bool isUnderline) {
      // Split by <br> tags to handle newlines
      // We use splitMapJoin logic but manually
      int lastIndex = 0;
      final brMatches = brRegex.allMatches(text);

      void processSegment(String segment) {
        if (segment.isEmpty) return;
        // Strip other tags
        final clean = segment.replaceAll(RegExp(r'<[^>]*>'), '');
        final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        for (final w in words) {
          tokens.add(_Token(
            id: 'tok-${tokenCounter}',
            text: w,
            isError: isError,
            errorId: errorId,
            index: tokenCounter++,
            isUnderline: isUnderline,
          ));
        }
      }

      for (final match in brMatches) {
        if (match.start > lastIndex) {
          processSegment(text.substring(lastIndex, match.start));
        }
        // Add newline token
        tokens.add(_Token(
          id: 'nl-${tokenCounter++}', // Unique ID
          text: '\n',
          isError: false,
          index: -1, // Newlines don't have index for corrections
          isNewline: true,
        ));
        lastIndex = match.end;
      }
      if (lastIndex < text.length) {
        processSegment(text.substring(lastIndex));
      }
    }

    // Main parsing loop
    int lastIndex = 0;
    for (final match in blockRegex.allMatches(item.original)) {
      // Text before
      if (match.start > lastIndex) {
        final textBefore = item.original.substring(lastIndex, match.start);
        addTextTokens(textBefore, false, null, false);
      }

      final attrString = match.group(1) ?? '';
      final content = match.group(2) ?? '';

      // Extract error ID
      final idMatch = RegExp(r"(?:error|id)=['\u0022]([^'\u0022]+)['\u0022]",
              caseSensitive: false)
          .firstMatch(attrString);
      final errorId = idMatch?.group(1);

      // Check underline
      final isUnderline = attrString.contains('underline');

      addTextTokens(content, errorId != null, errorId, isUnderline);

      lastIndex = match.end;
    }

    // Text after
    if (lastIndex < item.original.length) {
      final textAfter = item.original.substring(lastIndex);
      addTextTokens(textAfter, false, null, false);
    }

    // Fallback: If no tags found at all and text is not empty, assume plain text?
    // Or assume it's just one text block.
    // The previous implementation just split by space.
    // If tokens is empty and original is not, do plain parse.
    if (tokens.isEmpty && item.original.isNotEmpty) {
      addTextTokens(item.original, false, null, false);
    }

    return tokens;
  }

  void _onTokenTap(ErrorCorrectionItem item, _Token token) {
    if (token.isNewline) return;
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();
    if (state.passed) return;

    if (token.errorId != null && state.solvedErrorIds.contains(token.errorId)) {
      return; // Already solved
    }

    // Find error object associated with this token if any
    CorrectionError? error;
    if (token.isError && token.errorId != null) {
      error = item.errors.where((e) => e.id == token.errorId).firstOrNull;
    } else {
      // Fallback: finding error by index? No, relying on parsed ID is safer if tags exist.
      // If tags don't exist (legacy), we might match by index?
      // But we enforced parsing.
      // If token.isError is false, user clicked a non-error word.
    }

    setState(() {
      _selectedTokenIndex = token.index;
      _selectedError = error;

      _inputValue = state.corrections[token.index] ?? '';
      _inputController.text = _inputValue;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );

      _itemStates[item.id] = state.copyWith(
        feedbackMessage: '',
        isCorrectFeedback: true,
      );
    });
  }

  void _checkAnswer() {
    final item = widget.quiz.errorCorrections![_currentIndex];
    final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();

    if (_selectedTokenIndex == null) return;

    // 1. Check if token is an error
    if (_selectedError == null) {
      setState(() {
        _itemStates[item.id] = state.copyWith(
          feedbackMessage: "Incorrect selection. The error wasn't here.",
          isCorrectFeedback: false,
        );
        // Reset selection
        _selectedTokenIndex = null;
        _inputValue = '';
        _inputController.clear();
        _saveProgress();
      });
      return;
    }

    // 2. Check value
    final normalizedInput = _inputValue.trim().toLowerCase();
    final isCorrect = _selectedError!.correct
        .map((e) => e.toLowerCase())
        .contains(normalizedInput);

    if (isCorrect) {
      final newSolved = Set<String>.from(state.solvedErrorIds)
        ..add(_selectedError!.id);

      // Check if all errors solved
      // We need to know total errors.
      // Assumption: item.errors list contains ALL errors.
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
      final correctAns = _selectedError!.correct.isNotEmpty
          ? _selectedError!.correct.first
          : 'unknown';
      setState(() {
        _itemStates[item.id] = state.copyWith(
          feedbackMessage: 'Right spot, but wrong fix. Expected: "$correctAns"',
          isCorrectFeedback: false,
        );
        _saveProgress();
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

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
    final completedItems = _itemStates.values
        .where((s) => s.corrections.isNotEmpty || s.passed)
        .length;
    final correctItems = _itemStates.values.where((s) => s.passed).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz.id,
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
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final state = _itemStates[item.id] ?? _ErrorCorrectionItemState();

              // Parse tokens specifically for this item (rebuilding cheaper than caching usually)
              final tokens = _parseTokens(item);

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: state.passed
                              ? appColors.primary
                              : appColors.border,
                          strokeWidth: 2,
                          gap: 4,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 24, 24, 100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTokensWidget(
                                      item,
                                      state,
                                      tokens,
                                      appColors,
                                    ),
                                    if (!state.passed &&
                                        _selectedTokenIndex != null)
                                      _buildInputArea(
                                        appColors,
                                        state,
                                        item,
                                      ),
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
                            if (state.passed ||
                                _selectedTokenIndex != null) ...[
                              Divider(height: 1, color: appColors.border),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildActionButtons(
                                      appColors,
                                      state,
                                      item,
                                      items,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (item.explain != null)
                      ExplainDrawer(
                        isOpen: _showExplanation,
                        onClose: () => setState(() => _showExplanation = false),
                        explanation: item.explain!,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTokensWidget(
    ErrorCorrectionItem item,
    _ErrorCorrectionItemState state,
    List<_Token> tokens,
    AppColorsExtension appColors,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 14,
      children: tokens.map((token) {
        if (token.isNewline) {
          return const SizedBox(width: double.infinity, height: 8);
        }

        final isSolved = token.isError &&
            token.errorId != null &&
            (state.solvedErrorIds.contains(token.errorId) || state.passed);

        final isSelected = _selectedTokenIndex == token.index;

        if (isSolved) {
          // Find correct word from metadata
          // If we have multiple tokens for same error, how do we handle text?
          // The logic assumes 1-1 mapping or we reconstruct.
          // For simplicity, we just look up correction for this specific error ID and display it once?
          // React implementation handles "First token of error" to display correction block involving multiple words.
          // Here we simplify: If it's the FIRST match for this errorID in tokens that we've encountered?
          // Since `_buildTokensWidget` iterates, we cannot peek easily without index.
          // Let's just assume simple word-for-word or group.
          // React: "if (isFirst && errorDef)".
          // We can verify if this is the first token of this errorId.
          final isFirstOfError =
              tokens.firstWhere((t) => t.errorId == token.errorId).index ==
                  token.index;

          if (isFirstOfError && token.errorId != null) {
            final errorDef =
                item.errors.where((e) => e.id == token.errorId).firstOrNull;
            final errorTokens =
                tokens.where((t) => t.errorId == token.errorId).toList();
            final originalText = errorTokens.map((t) => t.text).join(' ');
            final correctText = errorDef?.correct.first ?? '';

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
                    originalText,
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
                    correctText,
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
          if (!isFirstOfError)
            return const SizedBox
                .shrink(); // Hide subsequent tokens of same error
        }

        // Normal render
        final Widget wordWidget = GestureDetector(
          onTap: () => _onTokenTap(item, token),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (state.isCorrectFeedback
                      ? appColors.textSecondary.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: state.isCorrectFeedback
                          ? appColors.textSecondary
                          : Colors.red,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Text(
              token.text,
              style: TextStyle(
                fontSize: 20,
                height: 1.5,
                color: appColors.textPrimary,
                fontWeight: FontWeight.normal,
                decoration: token.isUnderline
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
        );

        final savedCorrection = state.corrections[token.index] ?? '';
        final displayValue = isSelected ? _inputValue : savedCorrection;

        if (displayValue.isNotEmpty &&
            !state.passed &&
            (isSelected || savedCorrection.isNotEmpty)) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              wordWidget,
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
          TextField(
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
                borderSide: BorderSide(
                    color: state.isCorrectFeedback
                        ? appColors.primary
                        : Colors.red,
                    width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: state.isCorrectFeedback
                        ? appColors.primary
                        : Colors.red,
                    width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: state.isCorrectFeedback
                        ? appColors.primary
                        : Colors.red,
                    width: 2),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                color: appColors.primary,
                onPressed: _checkAnswer,
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
    ErrorCorrectionItem item,
    List<ErrorCorrectionItem> items,
  ) {
    if (state.passed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.primary.withValues(alpha: 0.15),
              foregroundColor: appColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: widget.onNext,
            child: const Text('Next',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (_selectedTokenIndex != null) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.primary.withValues(alpha: 0.15),
            foregroundColor: appColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Check Answer'),
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

class _Token {
  final String id;
  final String text;
  final bool isError;
  final String? errorId;
  final int index;
  final bool isUnderline;
  final bool isNewline;

  _Token({
    required this.id,
    required this.text,
    required this.isError,
    this.errorId,
    required this.index,
    this.isUnderline = false,
    this.isNewline = false,
  });
}
