import 'dart:math';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
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
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  // Key: Question ID, Value: Set of selected option keys
  final Map<String, Set<String>> _selectedOptions = {};

  // Track submission status per question ID
  final Set<String> _submittedQuestions = {};

  // Track correctness per question ID (true if correct)
  final Map<String, bool> _questionCorrectness = {};

  // Current active question index
  int _currentQuestionIndex = 0;

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
      setState(() {
        // Restore current question index
        _currentQuestionIndex =
            progress.data?['currentQuestionIndex'] as int? ?? 0;

        // Restore submitted questions
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

  void _animateToNextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
    final currentQuestion = questions[_currentQuestionIndex];
    final isSubmitted = _submittedQuestions.contains(currentQuestion.id);

    // Calculate background border color for the card based on state
    var borderColor = Colors.grey.withValues(alpha: 0.5);
    if (isSubmitted) {
      final isCorrect = _questionCorrectness[currentQuestion.id] ?? false;
      borderColor = isCorrect ? appColors.primary : Colors.red;
    }

    return NotificationListener<ScrollNotification>(
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
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final isSubmitted = _submittedQuestions.contains(question.id);

          // Calculate background border color for the card based on state
          var borderColor = Colors.grey.withValues(alpha: 0.5);
          if (isSubmitted) {
            final isCorrect = _questionCorrectness[question.id] ?? false;
            borderColor = isCorrect ? appColors.primary : Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              children: [
                // The Card
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: borderColor,
                      strokeWidth: 2,
                      gap: 4,
                      borderRadius: 12,
                    ),
                    child: Column(
                      children: [
                        // Card Header
                        _buildCardHeader(
                          context,
                          appColors,
                          questions,
                          question,
                          index,
                        ),
                        const Divider(height: 1),

                        // Card Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
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
                      ],
                    ),
                  ),
                ),
                // Floating Action Buttons
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildActionButtons(
                    context,
                    question,
                    appColors,
                    isSubmitted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<QuizQuestion> questions,
    QuizQuestion currentQuestion,
    int index,
  ) {
    final isSubmitted = _submittedQuestions.contains(currentQuestion.id);
    final isCorrect = _questionCorrectness[currentQuestion.id] ?? false;

    // Check total completed count
    final completedCount = _submittedQuestions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Question Counter
          Text(
            '${index + 1} / ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),

          Row(
            children: [
              // Score badge (shown if correct)
              if (isSubmitted && isCorrect)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+10 pts', // Default score placeholder
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appColors.primary,
                    ),
                  ),
                ),

              // Circular Segmented Progress
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(32, 32),
                      painter: _SegmentedProgressPainter(
                        totalSegments: questions.length,
                        segmentStates: List.generate(questions.length, (index) {
                          final qId = questions[index].id;
                          if (!_submittedQuestions.contains(qId)) {
                            return 0; // Not done
                          }
                          return (_questionCorrectness[qId] ?? false)
                              ? 1
                              : 2; // 1: Correct, 2: Wrong
                        }),
                        primaryColor: appColors.primary,
                        errorColor: Colors.red,
                        emptyColor: Colors.grey[300]!,
                      ),
                    ),
                    Text(
                      '$completedCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
    final hasSelection = _selectedOptions[question.id]?.isNotEmpty ?? false;

    // Submit Button
    if (!isSubmitted && hasSelection) {
      return ElevatedButton.icon(
        onPressed: () => _submitAnswer(question),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        icon: const Icon(Icons.check, size: 16),
        label:
            const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return const SizedBox.shrink();

    return const SizedBox.shrink();
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
        icon = const Icon(Icons.check, size: 16, color: Colors.white);
      } else if (isSelected && !isCorrectOption) {
        // Wrong selection -> Red
        borderColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        icon = const Icon(Icons.close, size: 16, color: Colors.white);
      }
    } else {
      // Not submitted yet
      if (isSelected) {
        borderColor = appColors.primary;
        backgroundColor = appColors.primary.withValues(alpha: 0.05);
        textColor = appColors.primary;
        icon = const Icon(Icons.check, size: 16, color: Colors.white);
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
              // Radio/Checkbox Circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isSubmitted && (icon != null))
                      ? (textColor == Colors.red
                          ? Colors.red
                          : appColors.primary) // Fill for status
                      : (isSelected ? appColors.primary : Colors.transparent),
                  border: Border.all(
                    color: (isSubmitted && (icon != null))
                        ? (textColor == Colors.red
                            ? Colors.red
                            : appColors.primary)
                        : (isSelected
                            ? appColors.primary
                            : Colors.grey.withValues(alpha: 0.5)),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: (isSubmitted && icon != null)
                      ? icon
                      : (isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null),
                ),
              ),
              const SizedBox(width: 16),
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

    // Calculate correct items
    final correctCount = _questionCorrectness.values.where((e) => e).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz.id,
      quizType: 'multiple-choice',
      completedItems: _submittedQuestions.length,
      totalItems: widget.quiz.questions.length,
      correctItems: correctCount,
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

class _SegmentedProgressPainter extends CustomPainter {
  _SegmentedProgressPainter({
    required this.totalSegments,
    required this.segmentStates,
    required this.primaryColor,
    required this.errorColor,
    required this.emptyColor,
  });
  final int totalSegments;
  // 0: Empty, 1: Correct, 2: Wrong
  final List<int> segmentStates;
  final Color primaryColor;
  final Color errorColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 3.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Butt cap for segments

    // Start from -90 degrees (top)
    var startAngle = -pi / 2;
    // Gap between segments in radians
    final gap = (totalSegments > 1) ? 0.2 : 0;
    final totalGap = gap * totalSegments;
    final segmentAngle = (2 * pi - totalGap) / totalSegments;

    for (var i = 0; i < totalSegments; i++) {
      final state = (i < segmentStates.length) ? segmentStates[i] : 0;

      if (state == 1) {
        paint.color = primaryColor;
      } else if (state == 2) {
        paint.color = errorColor;
      } else {
        paint.color = emptyColor;
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        segmentAngle,
        false,
        paint,
      );

      startAngle += segmentAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) {
    // Basic optimization
    return true;
  }
}
