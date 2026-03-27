import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuizBuilder extends StatefulWidget {
  const QuizBuilder({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onCheck,
    this.onNext,
    this.onPrev,
    this.onShowExplain,
    this.onWordLongPress,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final String? finalActionText;

  @override
  State<QuizBuilder> createState() => _QuizBuilderState();
}

class _QuizBuilderState extends State<QuizBuilder> {
  int _currentIndex = 0;
  // Key: Question ID, Value: List of selected indices from the options pool
  final Map<String, List<int>> _selectedIndices = {};
  final Map<String, bool?> _correctness = {};
  final Map<String, bool> _isCheckedMap = {};

  int get _firstUncheckedIndex {
    final questions = widget.quiz.questions;
    return questions.indexWhere((q) => !(_isCheckedMap[q.id] ?? false));
  }

  // Animation variables
  late PageController _pageController;

  QuizQuestion? get _currentItem => widget.quiz.questions.isNotEmpty
      ? widget.quiz.questions[_currentIndex]
      : null;

  List<int> get _currentSelected => _selectedIndices[_currentItem?.id] ?? [];
  bool get _currentIsChecked => _isCheckedMap[_currentItem?.id] ?? false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      final savedIndices =
          progress.data?['selectedIndices'] as Map<String, dynamic>?;
      if (savedIndices != null) {
        savedIndices.forEach((key, value) {
          _selectedIndices[key] = (value as List<dynamic>).cast<int>();
        });
      }

      final savedCorrectness =
          progress.data?['correctness'] as Map<String, dynamic>?;
      if (savedCorrectness != null) {
        savedCorrectness.forEach((key, value) {
          _correctness[key] = value as bool?;
        });
      }

      final savedChecked =
          progress.data?['isCheckedMap'] as Map<String, dynamic>?;
      if (savedChecked != null) {
        savedChecked.forEach((key, value) {
          _isCheckedMap[key] = value as bool;
        });
      }

      // Find first unpassed item index
      final questions = widget.quiz.questions;
      int firstUnpassed = 0;
      for (int i = 0; i < questions.length; i++) {
        if (!(_isCheckedMap[questions[i].id] ?? false)) {
          firstUnpassed = i;
          break;
        }
      }

      setState(() {
        _currentIndex = firstUnpassed;

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final totalItems = widget.quiz.questions.length;
    final completedItems = _isCheckedMap.values.where((v) => v).length;
    final correctItems = _correctness.values.where((v) => v == true).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'builder',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'currentIndex': _currentIndex,
        'selectedIndices': _selectedIndices,
        'correctness': _correctness,
        'isCheckedMap': _isCheckedMap,
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveProgress();
  }

  void _animateToNextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (isCorrect) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }

      _saveProgress();

      if (isCorrect) {
        // Auto-next logic:
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted &&
              _currentIndex == widget.quiz.questions.indexOf(currentItem)) {
            _animateToNextQuestion();
          }
        });
      }
    });

    if (_isCheckedMap.length == widget.quiz.questions.length) {
      widget.onCheck?.call();
    }
  }

  void _resetItem(String itemId) {
    setState(() {
      _selectedIndices[itemId] = [];
      _correctness[itemId] = null;
      _isCheckedMap[itemId] = false;
    });
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
    final hint = currentItem.question;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final item = questions[index];
        final options = item.options;
        final hint = item.question;
        final isChecked = _isCheckedMap[item.id] ?? false;
        final isCorrect = _correctness[item.id];
        final selected = _selectedIndices[item.id] ?? [];

        final borderColor = isChecked
            ? (isCorrect == true
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5))
            : appColors.border.withValues(alpha: 0.3);

        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 12, right: 8, bottom: 8),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Context Hint
                            if (hint.isNotEmpty) ...[
                              Text(
                                hint,
                                style: TextStyle(
                                  color: appColors.textSecondary,
                                  fontSize: 14,
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
                                color: isChecked
                                    ? (isCorrect ?? false
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1))
                                    : appColors.cardBackground,
                                border: Border.all(
                                  color: isChecked
                                      ? (isCorrect ?? false
                                          ? Colors.green
                                          : Colors.red)
                                      : selected.isEmpty
                                          ? appColors.border
                                              .withValues(alpha: 0.3)
                                          : appColors.primary
                                              .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: selected.isEmpty
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
                                      children: selected.map((idx) {
                                        return GestureDetector(
                                          onTap: isChecked
                                              ? null
                                              : () => _handleItemClick(idx),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isChecked
                                                  ? appColors.background
                                                  : appColors.cardBackground,
                                              border: Border.all(
                                                color: appColors.border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              // Add shadow to match Available words (optional, but makes them "similar")
                                              boxShadow: isChecked
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.05),
                                                        blurRadius: 2,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Text(
                                              options[idx],
                                              style: TextStyle(
                                                color: appColors.textPrimary,
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
                            if (isChecked && isCorrect == false) ...[
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
                                      item.validAnswers.firstOrNull ?? '',
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
                            if (isChecked && item.explain.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    widget.onShowExplain?.call(item.explain);
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
                                  final idx = entry.key;
                                  final word = entry.value;
                                  final isSelected = selected.contains(idx);

                                  return GestureDetector(
                                    onTap: () => _handleItemClick(idx),
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      opacity:
                                          isSelected || isChecked ? 0.5 : 1.0,
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: isSelected
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.05),
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
                            // Spacing at bottom for scrolling past floating button
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 0, right: 8.0, bottom: 8.0),
                      child: _buildFooterActions(appColors, item),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterActions(AppColorsExtension appColors, QuizQuestion item) {
    final isChecked = _isCheckedMap[item.id] ?? false;
    final selected = _selectedIndices[item.id] ?? [];

    if (isChecked) {
      final isLast = _currentIndex == widget.quiz.questions.length - 1;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColors.primary.withValues(alpha: 0.15),
            foregroundColor: appColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () {
            if (isLast) {
              final uncompleted = _firstUncheckedIndex;
              if (uncompleted != -1) {
                _pageController.animateToPage(
                  uncompleted,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                widget.onCheck?.call();
                widget.onNext?.call();
              }
            } else {
              _animateToNextQuestion();
            }
          },
          child: Text(
            isLast
                ? (_firstUncheckedIndex != -1
                    ? 'Review Uncompleted'
                    : (widget.finalActionText ?? 'Finish'))
                : 'Next',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (selected.isNotEmpty) ...[
          OutlinedButton(
            onPressed: () => _resetItem(item.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: appColors.textSecondary,
              side: BorderSide(color: appColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed:
                selected.length == item.options.length ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.primary.withValues(alpha: 0.15),
              foregroundColor: appColors.primary,
              disabledBackgroundColor:
                  appColors.textSecondary.withValues(alpha: 0.15),
              disabledForegroundColor: appColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
