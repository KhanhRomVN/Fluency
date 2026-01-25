import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SpeechBuilder extends StatefulWidget {
  const SpeechBuilder({
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
  State<SpeechBuilder> createState() => _SpeechBuilderState();
}

class _SpeechBuilderState extends State<SpeechBuilder> {
  int _currentIndex = 0;

  // Map<ItemID, State>
  final Map<String, _SpeechBuilderItemState> _itemStates = {};

  @override
  void initState() {
    super.initState();
    _initCurrentItem();
  }

  void _initCurrentItem() {
    final items = widget.quiz.speechBuilders ?? [];
    if (items.isEmpty) return;
    if (_currentIndex >= items.length) return;

    final item = items[_currentIndex];
    if (_itemStates.containsKey(item.id)) return;

    // Initialize pool with scrambled items (if provided) or split question?
    // Usually `item.items` contains the scrambled words.
    final pool = List<String>.from(item.items ?? []);
    _itemStates[item.id] = _SpeechBuilderItemState(
      pool: pool,
      selected: [],
    );
  }

  void _toggleWord(String word, bool fromPool, SpeechBuilderItem item) {
    final state =
        _itemStates[item.id] ?? _SpeechBuilderItemState(pool: [], selected: []);
    if (state.passed) return;

    final newPool = List<String>.from(state.pool);
    final newSelected = List<String>.from(state.selected);

    if (fromPool) {
      newPool.remove(word); // Remove one instance
      newSelected.add(word);
    } else {
      newSelected.remove(word);
      newPool.add(word);
    }

    setState(() {
      _itemStates[item.id] =
          state.copyWith(pool: newPool, selected: newSelected);
    });
  }

  void _checkAnswer(SpeechBuilderItem item) {
    final state = _itemStates[item.id];
    if (state == null) return;

    final builtSentence = state.selected.join(' ');
    final normalizedBuilt =
        builtSentence.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // Check against valid answers
    // item.answers is List<QuizAnswer>
    final validAnswers = item.answers?.expand((a) => a.answer).toList() ?? [];

    final isCorrect = validAnswers.any((ans) {
      final normalizedAns =
          ans.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      return normalizedAns == normalizedBuilt;
    });

    setState(() {
      _itemStates[item.id] = state.copyWith(
        passed: isCorrect,
        attempts: state.attempts + 1,
        showFeedback: true,
      );
    });
  }

  void _next() {
    if (widget.quiz.speechBuilders != null &&
        _currentIndex < widget.quiz.speechBuilders!.length - 1) {
      setState(() {
        _currentIndex++;
        _initCurrentItem();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.speechBuilders ?? [];

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No speech builder items.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

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

  Widget _buildCard(
    BuildContext context,
    SpeechBuilderItem item,
    int index,
    AppColorsExtension appColors,
  ) {
    final state =
        _itemStates[item.id] ?? _SpeechBuilderItemState(pool: [], selected: []);
    final isCurrent = index == _currentIndex;
    final isPassed = state.passed;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isCurrent
            ? appColors.cardBackground
            : appColors.cardBackground.withValues(alpha: 0.5),
        border: Border.all(
          color: isCurrent
              ? appColors.primary.withValues(alpha: 0.5)
              : appColors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isPassed && !isCurrent)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                SizedBox(width: isPassed && !isCurrent ? 8 : 0),
                Text(
                  '${index + 1}/${widget.quiz.speechBuilders?.length ?? 0}',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: appColors.border.withValues(alpha: 0.5)),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.question != null)
                  Text(
                    item.question!,
                    style:
                        TextStyle(fontSize: 18, color: appColors.textPrimary),
                  ),
                const SizedBox(height: 24),

                // Selected Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(minHeight: 60),
                  decoration: BoxDecoration(
                    color: appColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appColors.border),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.selected
                        .map(
                          (word) =>
                              _buildChip(context, word, false, item, appColors),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Pool Area
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: state.pool
                      .map(
                        (word) =>
                            _buildChip(context, word, true, item, appColors),
                      )
                      .toList(),
                ),

                if (state.showFeedback) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: state.passed
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.passed ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.passed ? 'Correct!' : 'Incorrect. Try again.',
                          style: TextStyle(
                            color: state.passed ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!state.passed && state.attempts >= 3) ...[
                          const SizedBox(height: 8),
                          if (item.answers != null && item.answers!.isNotEmpty)
                            Text(
                              'Answer: ${item.answers!.first.answer.first}',
                              style: TextStyle(
                                color: appColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isCurrent && !isPassed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed:
                    state.selected.isNotEmpty ? () => _checkAnswer(item) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Check',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (isCurrent && isPassed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (index < (widget.quiz.speechBuilders?.length ?? 0) - 1) {
                    _next();
                  } else {
                    widget.onCheck?.call();
                    widget.onNext?.call();
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String word,
    bool inPool,
    SpeechBuilderItem item,
    AppColorsExtension appColors,
  ) {
    return GestureDetector(
      onTap: () => _toggleWord(word, inPool, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: inPool
              ? appColors.cardBackground
              : appColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: inPool ? appColors.border : appColors.primary),
          boxShadow: inPool
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          word,
          style: TextStyle(
            color: inPool ? appColors.textPrimary : appColors.primary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SpeechBuilderItemState {
  _SpeechBuilderItemState({
    required this.pool,
    required this.selected,
    this.passed = false,
    this.attempts = 0,
    this.showFeedback = false,
  });
  final List<String> pool;
  final List<String> selected;
  final bool passed;
  final int attempts;
  final bool showFeedback;

  _SpeechBuilderItemState copyWith({
    List<String>? pool,
    List<String>? selected,
    bool? passed,
    int? attempts,
    bool? showFeedback,
  }) {
    return _SpeechBuilderItemState(
      pool: pool ?? this.pool,
      selected: selected ?? this.selected,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      showFeedback: showFeedback ?? this.showFeedback,
    );
  }
}
