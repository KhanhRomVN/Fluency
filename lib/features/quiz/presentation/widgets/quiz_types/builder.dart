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
            ? (isCorrect ?? false ? Colors.green : Colors.red)
            : Colors.grey.withValues(alpha: 0.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
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
                      // Card Header: Counter & Progress
                      _buildCardHeader(
                        context,
                        appColors,
                        questions,
                        index,
                      ),
                      const Divider(height: 1),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
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
                                constraints:
                                    const BoxConstraints(minHeight: 80),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isChecked
                                                    ? appColors.background
                                                    : appColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                options[idx],
                                                style: TextStyle(
                                                  color: isChecked
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            decoration:
                                                TextDecoration.underline,
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
                                  children:
                                      options.asMap().entries.map((entry) {
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
                                                      offset:
                                                          const Offset(0, 2),
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
                      if (isChecked || selected.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildFooterActions(appColors, item),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<QuizQuestion> questions,
    int index,
  ) {
    final completedCount = _isCheckedMap.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Counter
          Text(
            '${index + 1} / ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
            ),
          ),

          // Segmented Progress Circle
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
                      if (!(_isCheckedMap[qId] ?? false)) return 0; // Not done
                      return (_correctness[qId] ?? false)
                          ? 1
                          : 2; // 1: Correct, 2: Wrong
                    }),
                    primaryColor: appColors.primary,
                    errorColor: Colors.red,
                    emptyColor: appColors.border.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '$completedCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(AppColorsExtension appColors, QuizQuestion item) {
    final isChecked = _isCheckedMap[item.id] ?? false;
    final isCorrect = _correctness[item.id];
    final selected = _selectedIndices[item.id] ?? [];

    if (isChecked) {
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
        onPressed: () {
          if (_currentIndex < widget.quiz.questions.length - 1) {
            _animateToNextQuestion();
          } else {
            widget.onNext?.call();
          }
        },
        child:
            const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (!isChecked && selected.length == item.options.length) {
      return ElevatedButton(
        onPressed: _checkAnswer,
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
          'Check',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    if (!isChecked && isCorrect != true && selected.isNotEmpty) {
      return ElevatedButton(
        onPressed: () => _resetItem(item.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.textSecondary.withValues(alpha: 0.15),
          foregroundColor: appColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Reset',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
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
      ..strokeCap = StrokeCap.butt;

    var startAngle = -3.14159 / 2; // -pi/2
    final gap = (totalSegments > 1) ? 0.2 : 0;
    final totalGap = gap * totalSegments;
    final segmentAngle = (2 * 3.14159 - totalGap) / totalSegments;

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
    return oldDelegate.totalSegments != totalSegments ||
        oldDelegate.segmentStates != segmentStates;
  }
}
