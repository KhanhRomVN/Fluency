import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingDropdown extends StatefulWidget {
  const MatchingDropdown({
    required this.quiz,
    required this.lessonId,
    required this.onCheck,
    this.onNext,
    this.onPrev,
    this.onShowExplain,
    this.onWordLongPress,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final VoidCallback onCheck;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<MatchingDropdown> createState() => _MatchingDropdownState();
}

class _MatchingDropdownState extends State<MatchingDropdown> {
  Map<String, String> _selectedAnswers = {};
  bool _isChecked = false;

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _resetAnswers();
    _pageController = PageController();

    // Load saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quiz.id,
    );

    if (progress != null && mounted) {
      setState(() {
        _isChecked = progress.data?['isChecked'] as bool? ?? false;

        // Restore selected answers
        final savedAnswers =
            progress.data?['selectedAnswers'] as Map<String, dynamic>?;
        if (savedAnswers != null) {
          _selectedAnswers = Map<String, String>.from(savedAnswers);
        }

        // If already checked, notify parent to show transcript/etc
        if (_isChecked) {
          widget.onCheck();
        }
      });
    }
  }

  @override
  void didUpdateWidget(MatchingDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id) {
      _resetAnswers();
    }
  }

  void _resetAnswers() {
    _selectedAnswers = {};
    _isChecked = false;
  }

  void _onClearSelected(String id) {
    setState(() {
      _selectedAnswers[id] = '';
    });
    _saveProgress();
  }

  List<MapEntry<String, String>> get _options {
    if (widget.quiz.options == null) return [];

    return widget.quiz.options!
        .asMap()
        .entries
        .map(
          (e) => MapEntry(
            String.fromCharCode(65 + e.key), // A, B, C...
            e.value,
          ),
        )
        .toList();
  }

  String? _getCorrectOptionKey(String correctAnswerText) {
    final normalized = correctAnswerText.trim().toLowerCase();
    final exact = _options.firstWhere(
      (o) => o.value.trim().toLowerCase() == normalized,
      orElse: () => const MapEntry('', ''),
    );
    return exact.key.isNotEmpty ? exact.key : null;
  }

  bool get _areAllAnswered {
    final matchings = widget.quiz.matchings ?? [];
    if (matchings.isEmpty) return true;
    return matchings.every(
      (m) =>
          _selectedAnswers[m.id] != null && _selectedAnswers[m.id]!.isNotEmpty,
    );
  }

  bool _allMatch() {
    final matchings = widget.quiz.matchings ?? [];
    for (final matching in matchings) {
      final selectedKey = _selectedAnswers[matching.id] ?? '';
      final correctKey = _getCorrectOptionKey(matching.answer);
      if (selectedKey != correctKey) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final matchings = widget.quiz.matchings ?? [];
    final borderColor = _isChecked
        ? (_allMatch()
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.red.withValues(alpha: 0.5))
        : Colors.grey.withValues(alpha: 0.3);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction

            // Dashed Border Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 8, top: 8, right: 16, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            ...matchings.map((matching) {
                              return _buildMatchingRow(
                                context,
                                matching,
                                appColors,
                              );
                            }),
                          ],
                        ),
                      ),
                      if (_isChecked || _areAllAnswered) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildActionButtons(appColors),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    if (_isChecked) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: widget.onNext,
        child: Text(widget.finalActionText ?? 'Next',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (_areAllAnswered && !_isChecked) {
      return ElevatedButton(
        onPressed: () async {
          setState(() {
            _isChecked = true;
          });

          // Check if all are correct to play sound
          bool allCorrect = true;
          final matchings = widget.quiz.matchings ?? [];
          for (final matching in matchings) {
            final selectedKey = _selectedAnswers[matching.id] ?? '';
            final correctKey = _getCorrectOptionKey(matching.answer);
            if (selectedKey != correctKey) {
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

          widget.onCheck();
          await _saveProgress();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Check answers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMatchingRow(
    BuildContext context,
    MatchingItem matching,
    AppColorsExtension appColors,
  ) {
    final selectedKey = _selectedAnswers[matching.id] ?? '';
    final correctKey = _getCorrectOptionKey(matching.answer);
    final isCorrect = _isChecked && selectedKey == correctKey;
    final isWrong = _isChecked && !isCorrect;

    // Determine colors based on state
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    if (_isChecked) {
      if (isCorrect) {
        borderColor = Colors.green.withValues(alpha: 0.5);
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        iconColor = Colors.green;
      } else {
        borderColor = Colors.red.withValues(alpha: 0.5);
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        iconColor = Colors.red;
      }
    } else {
      borderColor = selectedKey.isNotEmpty
          ? appColors.primary.withValues(alpha: 0.5)
          : appColors.border.withValues(alpha: 0.3);
      backgroundColor = appColors.background;
      textColor = selectedKey.isNotEmpty
          ? appColors.textPrimary
          : appColors.textSecondary;
      iconColor = appColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Text.rich(
            TextSpan(
              children: RichTextParser.buildTextSpans(
                context,
                matching.question,
                onWordLongPress: widget.onWordLongPress,
              ),
            ),
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Dropdown Row
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<String>(
                      width: constraints.maxWidth,
                      expandedInsets: EdgeInsets.zero,
                      initialSelection:
                          selectedKey.isNotEmpty ? selectedKey : null,
                      hintText: 'Choose an answer',
                      textStyle: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: backgroundColor,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        constraints: const BoxConstraints(maxHeight: 36),
                        isCollapsed: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor, width: 2),
                        ),
                        hintStyle: TextStyle(
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      menuStyle: MenuStyle(
                        backgroundColor:
                            WidgetStateProperty.all(appColors.inputBackground),
                        elevation: WidgetStateProperty.all(0),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        fixedSize: WidgetStateProperty.all(
                          Size.fromWidth(constraints.maxWidth),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: appColors.border,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      trailingIcon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: iconColor,
                        size: 24,
                      ),
                      onSelected: _isChecked
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedAnswers[matching.id] = value;
                                });
                                _saveProgress();
                              }
                            },
                      dropdownMenuEntries: _options.where((o) {
                        final isAlreadySelected =
                            _selectedAnswers.values.contains(o.key);
                        return !isAlreadySelected || o.key == selectedKey;
                      }).map((opt) {
                        return DropdownMenuEntry<String>(
                          value: opt.key,
                          label: opt.value,
                          labelWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  opt.value,
                                  style: TextStyle(
                                    color: appColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (opt.key != _options.last.key)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color:
                                      appColors.border.withValues(alpha: 0.5),
                                ),
                            ],
                          ),
                          style: MenuItemButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              if (selectedKey.isNotEmpty && !_isChecked) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _onClearSelected(matching.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Correction Display (if wrong) - Below the dropdown
          if (isWrong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () {
                  if (matching.explain.isNotEmpty) {
                    widget.onShowExplain?.call(matching.explain);
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        matching.answer, // Display correct answer text
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Explain Display (if correct and has explanation)
          if (isCorrect && matching.explain.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () {
                  widget.onShowExplain?.call(matching.explain);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Explain',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.green,
                        ),
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

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Calculate correct count
    var correctCount = 0;
    final Map<String, bool> correctness = {};
    _selectedAnswers.forEach((id, selectedKey) {
      final matching = widget.quiz.matchings?.firstWhere((m) => m.id == id);
      if (matching != null) {
        final correctKey = _getCorrectOptionKey(matching.answer);
        final isCorrect = selectedKey == correctKey;
        if (isCorrect) {
          correctCount++;
        }
        correctness[id] = isCorrect;
      }
    });

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz.id,
      quizType: 'matching-dropdown',
      completedItems: _selectedAnswers.length,
      totalItems: widget.quiz.matchings?.length ?? 0,
      correctItems: _isChecked ? correctCount : 0,
      data: {
        'isChecked': _isChecked,
        'selectedAnswers': _selectedAnswers,
        'correctCount': correctCount,
        'totalMatchings': widget.quiz.matchings?.length ?? 0,
        'correctness': correctness,
      },
    );
  }
}
