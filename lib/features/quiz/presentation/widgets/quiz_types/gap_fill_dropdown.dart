import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GapFillDropdown extends StatefulWidget {
  const GapFillDropdown({
    required this.quiz,
    required this.question,
    required this.answers,
    required this.lessonId,
    required this.quizId,
    this.title,
    this.instruction,
    this.onCheck,
    this.onShowExplain,
    this.onWordLongPress,
    this.onNext,
    this.onPrev,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String question;
  final List<QuizAnswer> answers;
  final String lessonId;
  final String quizId;
  final String? title;
  final String? instruction;
  final VoidCallback? onCheck;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<GapFillDropdown> createState() => _GapFillDropdownState();
}

class _GapFillDropdownState extends State<GapFillDropdown> {
  // Map of gap ID to selected value
  final Map<String, String> _selections = {};
  bool _isChecked = false;
  late List<String> _sharedOptions;

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _sharedOptions = _calculateSharedOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  List<String> _calculateSharedOptions() {
    debugPrint(
        '[GapFillDropdown] Calculating shared options for ${widget.answers.length} answers');
    for (var i = 0; i < widget.answers.length; i++) {
      debugPrint(
          '[GapFillDropdown] Answer $i (id: ${widget.answers[i].id}): ${widget.answers[i].answer}');
    }

    final allAnswers = widget.answers
        .expand((a) => a.answer)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    debugPrint('[GapFillDropdown] Generated shared word bank: $allAnswers');
    return allAnswers;
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      debugPrint(
          '[GapFillDropdown] Progress loaded for ${widget.quizId}: ${progress.data}');
      setState(() {
        _isChecked = progress.data?['isChecked'] as bool? ?? false;

        // Restore selections
        final savedSelections =
            progress.data?['selections'] as Map<String, dynamic>?;
        if (savedSelections != null) {
          savedSelections.forEach((key, value) {
            _selections[key] = value as String;
          });
        }

        _checkIfAllGapsFilled();

        // If already checked, notify parent to show transcript/etc
        if (_isChecked) {
          widget.onCheck?.call();
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    final totalScore = widget.quiz.totalScore;
    final filledScore = widget.answers
        .where((a) => _selections[a.id]?.isNotEmpty == true)
        .fold(0, (sum, a) => sum + a.score);

    int correctScore = 0;
    final Map<String, bool> correctness = {};
    if (_isChecked) {
      for (final answer in widget.answers) {
        final selectedValue = _selections[answer.id] ?? '';
        final isCorrect = answer.answer.any(
          (ans) =>
              selectedValue.toLowerCase().trim() == ans.toLowerCase().trim(),
        );
        if (isCorrect) {
          correctScore += answer.score;
        }
        correctness[answer.id] = isCorrect;
      }
    }

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'gap-fill-dropdown',
      completedItems: filledScore,
      totalItems: totalScore,
      correctItems: correctScore,
      data: {
        'isChecked': _isChecked,
        'selections': _selections,
        'correctness': correctness,
      },
    );
    debugPrint(
        '[GapFillDropdown] Progress saved for ${widget.quizId}: $_selections');
  }

  @override
  void didUpdateWidget(covariant GapFillDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question ||
        oldWidget.answers != widget.answers) {
      setState(() {
        _isChecked = false;
        _sharedOptions = _calculateSharedOptions();
      });
      _initializeSelections();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeSelections() {
    _selections.clear();
    final regex = RegExp("</gap id='(.*?)'>");
    final matches = regex.allMatches(widget.question);
    for (final match in matches) {
      final id = match.group(1);
      if (id != null) {
        _selections[id] = '';
      }
    }
    debugPrint('[GapFillDropdown] Initialized selections: $_selections');
  }

  bool _checkIfAllGapsFilled() {
    return _selections.values.every((val) => val.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Main Content Area
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: Theme.of(context).textTheme.copyWith(
                                      bodyMedium: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 16),
                                    ),
                              ),
                              child: Builder(
                                builder: _buildContent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
              child: _buildActionButtons(appColors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    // Determine button text and action
    String text;
    VoidCallback? onPressed;
    Color? backgroundColor = appColors.primary.withValues(alpha: 0.15);
    Color? foregroundColor = appColors.primary;

    if (_isChecked) {
      text = widget.finalActionText ?? 'Next';
      onPressed = widget.onNext;
    } else {
      text = 'Check answers';
      // Enable only if all gaps are filled
      onPressed = _checkIfAllGapsFilled()
          ? () {
              setState(() {
                _isChecked = true;
              });

              // Check if all are correct to play sound
              bool allCorrect = true;
              for (final answer in widget.answers) {
                final selectedValue = _selections[answer.id] ?? '';
                final isCorrect = answer.answer.any(
                  (ans) =>
                      selectedValue.toLowerCase().trim() ==
                      ans.toLowerCase().trim(),
                );
                if (!isCorrect) {
                  allCorrect = false;
                  break;
                }
              }

              if (mounted) {
                final soundProvider = context.read<SoundEffectProvider>();
                if (allCorrect) {
                  soundProvider.playCorrect();
                } else {
                  soundProvider.playWrong();
                }
              }

              _saveProgress();
              widget.onCheck?.call();
            }
          : null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              appColors.textPrimary.withValues(alpha: 0.05),
          disabledForegroundColor: appColors.textPrimary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final spans = RichTextParser.buildTextSpans(
      context,
      widget.question,
      isQuestion: true,
      onGapFound: (id) => _createGapWidget(id, appColors, context),
      onWordLongPress: widget.onWordLongPress,
    );

    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.8,
            color: appColors.textPrimary,
          ),
    );
  }

  Widget _createGapWidget(
    String id,
    AppColorsExtension appColors,
    BuildContext context,
  ) {
    final answer = widget.answers.firstWhere(
      (a) => a.id == id,
      orElse: () => const QuizAnswer(id: '', answer: [], explain: ''),
    );

    final selectedValue = _selections[id] ?? '';
    final possibleAnswers = answer.answer;
    final isCorrect = possibleAnswers.any(
      (ans) => selectedValue.toLowerCase().trim() == ans.toLowerCase().trim(),
    );

    if (_isChecked) {
      Widget content;
      if (isCorrect) {
        content = Text(
          selectedValue,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.primary,
                fontWeight: FontWeight.bold,
              ),
        );
      } else {
        content = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              selectedValue.isEmpty ? '___' : selectedValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              possibleAnswers.firstOrNull ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      }

      return InkWell(
        onTap: () => _showExplanation(context, answer),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    // Use options from answer object if available, otherwise fallback to _sharedOptions
    final options = answer.options.isNotEmpty ? answer.options : _sharedOptions;

    return _DropdownTrigger(
      value: selectedValue,
      options: options,
      onTap: () => _showOptionsBottomSheet(
        context,
        id,
        options,
        selectedValue,
        appColors,
      ),
      onClear: () => _onOptionSelected(id, ''),
      appColors: appColors,
    );
  }

  void _onOptionSelected(String id, String val) {
    debugPrint('[GapFillDropdown] Option selected for $id: $val');
    setState(() {
      // Clear other gaps using this value (unique selection)
      _selections.forEach((key, value) {
        if (val.isNotEmpty && value == val) {
          _selections[key] = '';
        }
      });
      _selections[id] = val;
    });
    _saveProgress();
  }

  void _showOptionsBottomSheet(
    BuildContext context,
    String id,
    List<String> options,
    String currentSelection,
    AppColorsExtension appColors,
  ) {
    debugPrint(
        '[GapFillDropdown] Showing options for $id. Current: $currentSelection');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appColors.drawerBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: appColors.drawerBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select an answer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: appColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Choose the word that fits the gap',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: appColors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: appColors.border.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        final isSelected = opt == currentSelection;

                        // Find which gaps have selected this option
                        final selectedGapIds = _selections.entries
                            .where((e) => e.value == opt)
                            .map((e) => e.key)
                            .toList();

                        final isUsed = selectedGapIds.isNotEmpty;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: (isUsed && !isSelected)
                                ? null
                                : () {
                                    _onOptionSelected(id, opt);
                                    Navigator.pop(context);
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? appColors.textPrimary
                                        .withValues(alpha: 0.05)
                                    : appColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? appColors.primary.withValues(alpha: 0.3)
                                      : appColors.border.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: isUsed ? 40 : 0,
                                    ),
                                    child: Opacity(
                                      opacity:
                                          (isUsed && !isSelected) ? 0.35 : 1.0,
                                      child: Text(
                                        opt,
                                        style: TextStyle(
                                          color: appColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isUsed)
                                    Positioned(
                                      right: -4,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              for (final gapId
                                                  in selectedGapIds) {
                                                _selections[gapId] = '';
                                              }
                                            });
                                            setModalState(() {
                                              _saveProgress();
                                            });
                                            _checkIfAllGapsFilled();
                                          },
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 20,
                                              color: Colors.red
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExplanation(BuildContext context, QuizAnswer answer) {
    if (widget.onShowExplain != null) {
      final explanation = answer.explain.isNotEmpty
          ? answer.explain
          : '<p>No explanation available.</p>';
      widget.onShowExplain!(explanation);
    }
  }
}

class _DropdownTrigger extends StatelessWidget {
  const _DropdownTrigger({
    required this.value,
    required this.options,
    required this.onTap,
    required this.onClear,
    required this.appColors,
  });

  final String value;
  final List<String> options;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final AppColorsExtension appColors;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? 'Select...' : value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                appColors.primary.withValues(alpha: value.isEmpty ? 0.3 : 1.0),
            width: value.isEmpty ? 1 : 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Text(
              displayValue,
              style: TextStyle(
                color: value.isEmpty
                    ? appColors.textSecondary.withValues(alpha: 0.5)
                    : appColors.textPrimary,
                fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.red.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
