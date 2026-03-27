import 'dart:math';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MultipleChoice extends StatefulWidget {
  const MultipleChoice({
    required this.quiz,
    required this.lessonId,
    this.onCheck,
    this.onNext,
    this.onPrev,
    this.onShowExplain,
    this.onWordLongPress,
    this.targetQuestionIndex,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final int? targetQuestionIndex;
  final String? finalActionText;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  // Key: Question ID, Value: Set of selected option keys
  final Map<String, Set<String>> _selectedOptions = {};

  // Track submission status per question ID
  final Set<String> _submittedQuestions = {};

  final Map<String, bool> _questionCorrectness = {};

  // Current active question index
  int _currentQuestionIndex = 0;

  int get _firstUnsubmittedIndex {
    final questions = widget.quiz.questions;
    return questions.indexWhere((q) => !_submittedQuestions.contains(q.id));
  }

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentQuestionIndex);

    // Load saved progress
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
      // Restore submitted questions first
      final submittedIds =
          progress.data?['submittedQuestions'] as List<dynamic>?;
      if (submittedIds != null) {
        _submittedQuestions.addAll(submittedIds.cast<String>());
      }

      // Restore correctness
      final correctness =
          progress.data?['questionCorrectness'] as Map<String, dynamic>?;
      if (correctness != null) {
        correctness.forEach((key, value) {
          _questionCorrectness[key] = value as bool;
        });
      }

      // Restore selected options
      final selected =
          progress.data?['selectedOptions'] as Map<String, dynamic>?;
      if (selected != null) {
        selected.forEach((questionId, options) {
          _selectedOptions[questionId] =
              (options as List<dynamic>).cast<String>().toSet();
        });
      }

      // Find first unsubmitted question index
      final questions = widget.quiz.questions;
      int firstUnsubmitted = 0;
      for (int i = 0; i < questions.length; i++) {
        if (!_submittedQuestions.contains(questions[i].id)) {
          firstUnsubmitted = i;
          break;
        }
      }

      final savedIndex =
          progress.data?['currentQuestionIndex'] as int? ?? firstUnsubmitted;

      int indexToUse = savedIndex;

      // Hybrid logic: if we are at the end but have unsubmitted items, jump back to first unsubmitted
      if (savedIndex == questions.length - 1 &&
          firstUnsubmitted != -1 &&
          firstUnsubmitted < savedIndex) {
        indexToUse = firstUnsubmitted;
      }

      setState(() {
        _currentQuestionIndex = indexToUse;

        // Jump to saved page
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentQuestionIndex);
        }

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MultipleChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetQuestionIndex != null &&
        widget.targetQuestionIndex != oldWidget.targetQuestionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(widget.targetQuestionIndex!);
          setState(() {
            _currentQuestionIndex = widget.targetQuestionIndex!;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
    _saveProgress();
  }

  void _handleNext(int totalItems) {
    if (_currentQuestionIndex < totalItems - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no questions, show empty
    if (widget.quiz.questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final questions = widget.quiz.questions;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final isSubmitted = _submittedQuestions.contains(question.id);

        // Calculate background border color for the card based on state
        var borderColor = Colors.grey.withValues(alpha: 0.3);
        if (isSubmitted) {
          final isCorrect = _questionCorrectness[question.id] ?? false;
          borderColor = isCorrect
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5);
        }

        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
          child: Stack(
            children: [
              // Unconstrained Container (Removed Card UI)
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Card Header

                    // Card Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionContent(
                              context,
                              question,
                              appColors,
                              isSubmitted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Card Footer
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 0, right: 8.0, bottom: 8.0),
                      child: _buildActionButtons(
                        context,
                        question,
                        appColors,
                        isSubmitted,
                      ),
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

  Widget _buildQuestionContent(
    BuildContext context,
    QuizQuestion question,
    AppColorsExtension appColors,
    bool isSubmitted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Text
        Text(
          question.question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
                fontSize: 17,
              ),
        ),
        const SizedBox(height: 16),

        // Options List
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final optionText = entry.value;
          // Convention: options are A, B, C, D...
          final optionKey = String.fromCharCode(65 + index); // 'A' + 0 = 'A'

          return _buildOptionItem(
            context,
            question,
            optionKey,
            optionText,
            appColors,
            isSubmitted,
          );
        }),

        // Explain Button (if submitted and has explanation)
        if (isSubmitted && question.explain.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: InkWell(
              onTap: () => widget.onShowExplain?.call(question.explain),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 20, color: appColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Explain',
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

        // Spacing for floating buttons
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    QuizQuestion question,
    AppColorsExtension appColors,
    bool isSubmitted,
  ) {
    if (isSubmitted) {
      final isLast = _currentQuestionIndex == widget.quiz.questions.length - 1;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (question.explain.isNotEmpty)
            Expanded(
              child: InkWell(
                onTap: () => widget.onShowExplain?.call(question.explain),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: appColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Explain',
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
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  final uncompleted = _firstUnsubmittedIndex;
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
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primary.withValues(alpha: 0.15),
                foregroundColor: appColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                isLast
                    ? (_firstUnsubmittedIndex != -1
                        ? 'Review Uncompleted'
                        : (widget.finalActionText ?? 'Finish'))
                    : 'Next',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    final hasSelection = _selectedOptions[question.id]?.isNotEmpty ?? false;

    // Always show Submit Button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasSelection ? () => _submitAnswer(question) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          disabledBackgroundColor:
              appColors.textSecondary.withValues(alpha: 0.15),
          disabledForegroundColor: appColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child:
            const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    QuizQuestion question,
    String optionKey,
    String optionText,
    AppColorsExtension appColors,
    bool isSubmitted,
  ) {
    final selectedSet = _selectedOptions[question.id] ?? {};
    final isSelected = selectedSet.contains(optionKey);

    // Determine styles
    var borderColor = Colors.grey.withValues(alpha: 0.3);
    Color? backgroundColor; // Transparent default
    var textColor = appColors.textPrimary;
    Widget? icon;

    if (isSubmitted) {
      final isCorrectOption = question.validAnswers.contains(optionKey) ||
          question.validAnswers.contains(optionText);

      if (isCorrectOption) {
        // Must show green if it's the correct answer (whether selected or not sometimes?)
        // Usually we highlight the correct answer in Green
        borderColor = appColors.primary;
        backgroundColor = appColors.primary.withValues(alpha: 0.1);
        textColor = appColors.primary;
      } else if (isSelected && !isCorrectOption) {
        // Wrong selection -> Red
        borderColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
      }
    } else {
      // Not submitted yet
      if (isSelected) {
        borderColor = appColors.primary;
        backgroundColor = appColors.primary.withValues(alpha: 0.05);
        textColor = appColors.primary;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: isSubmitted ? null : () => _onOptionTap(question, optionKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOptionTap(QuizQuestion question, String optionKey) {
    setState(() {
      final isMultiSelect = question.validAnswers.length > 1;

      if (!_selectedOptions.containsKey(question.id)) {
        _selectedOptions[question.id] = {};
      }

      final set = _selectedOptions[question.id]!;

      if (isMultiSelect) {
        if (set.contains(optionKey)) {
          set.remove(optionKey);
        } else {
          set.add(optionKey);
        }
      } else {
        set
          ..clear()
          ..add(optionKey);
      }
    });
  }

  void _submitAnswer(QuizQuestion question) async {
    if (_selectedOptions[question.id]?.isEmpty ?? true) {
      // Don't submit if nothing selected
      return;
    }

    setState(() {
      _submittedQuestions.add(question.id);

      final selected = _selectedOptions[question.id] ?? {};
      // Logic from reference: Check if selected matches valid answers
      // Assuming validAnswers contains keys like 'A', 'B' or exact text.
      // Reference code checks: size match AND every selected is in valid.

      // We will normalize to check against keys.
      // The option list building assumed keys A, B, C...

      // Check if user got it right
      var isCorrect = false;
      // Simple check: do selected keys match any in validAnswers?
      // Since validAnswers might be ["goes"] (text) or ["B"] (key), we need to be careful.
      // The original code passed 'optionKey' (A, B..) to selection.
      // Let's assume validAnswers are keys or text.

      // Better logic: Match selected keys against indices of options that match valid answers.
      final validKeys = <String>{};
      question.options.asMap().forEach((idx, text) {
        final key = String.fromCharCode(65 + idx);
        if (question.validAnswers.contains(key) ||
            question.validAnswers.contains(text)) {
          validKeys.add(key);
        }
      });

      if (selected.length == validKeys.length &&
          selected.every(validKeys.contains)) {
        isCorrect = true;
      }

      _questionCorrectness[question.id] = isCorrect;

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (isCorrect) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }
    });

    // Save progress after submit
    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Prepare data to save
    final selectedOptionsData = <String, List<String>>{};
    _selectedOptions.forEach((key, value) {
      selectedOptionsData[key] = value.toList();
    });

    // Calculate achieved score
    final achievedScore = widget.quiz.questions
        .where((q) => _questionCorrectness[q.id] == true)
        .fold(0, (sum, q) => sum + q.score);

    // Calculate completed score
    final completedScore = widget.quiz.questions
        .where((q) => _submittedQuestions.contains(q.id))
        .fold(0, (sum, q) => sum + q.score);

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz.id,
      quizType: 'multiple-choice',
      completedItems: completedScore,
      totalItems: widget.quiz.totalScore,
      correctItems: achievedScore,
      data: {
        'currentQuestionIndex': _currentQuestionIndex,
        'submittedQuestions': _submittedQuestions.toList(),
        'questionCorrectness': _questionCorrectness,
        'selectedOptions': selectedOptionsData,
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painters
// -----------------------------------------------------------------------------
