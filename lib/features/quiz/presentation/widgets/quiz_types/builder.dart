import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class QuizBuilder extends StatefulWidget {
  const QuizBuilder({
    required this.quiz,
    super.key,
    this.onCheck,
    this.onNext,
    this.onShowExplain,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;

  @override
  State<QuizBuilder> createState() => _QuizBuilderState();
}

class _QuizBuilderState extends State<QuizBuilder>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  // Key: Question ID, Value: List of selected indices from the options pool
  final Map<String, List<int>> _selectedIndices = {};
  // Map<QuestionID, isCorrect>
  final Map<String, bool?> _correctness = {};
  final Map<String, bool> _isCheckedMap = {};

  // Animation variables
  late AnimationController _animController;
  double _dragOffset = 0;
  Animation<double>? _slideAnimation;

  QuizQuestion? get _currentItem => widget.quiz.questions.isNotEmpty
      ? widget.quiz.questions[_currentIndex]
      : null;

  List<int> get _currentSelected => _selectedIndices[_currentItem?.id] ?? [];
  bool get _currentIsChecked => _isCheckedMap[_currentItem?.id] ?? false;
  bool? get _currentIsCorrect => _correctness[_currentItem?.id];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(() {
      setState(() {
        if (_slideAnimation != null) {
          _dragOffset = _slideAnimation!.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_currentIsChecked)
      return; // Optional: disable drag if checked? Or allow?
    setState(() {
      _dragOffset += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = screenWidth * 0.25;

    // Check if we should change question
    var shouldChange = false;
    var direction = 0; // -1: Next (Swipe Left), 1: Prev (Swipe Right)

    if (velocity < -1000 || _dragOffset < -threshold) {
      if (_currentIndex < widget.quiz.questions.length - 1) {
        shouldChange = true;
        direction = -1;
      }
    } else if (velocity > 1000 || _dragOffset > threshold) {
      if (_currentIndex > 0) {
        shouldChange = true;
        direction = 1;
      }
    }

    if (shouldChange) {
      // Animate out completely
      final endX = direction == -1 ? -screenWidth : screenWidth;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: endX).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );

      _animController.forward(from: 0).then((_) {
        // Change index
        setState(() {
          if (direction == -1) {
            _currentIndex++;
          } else {
            _currentIndex--;
          }
          // Reset for slide in
          _dragOffset = direction == -1 ? screenWidth : -screenWidth;
          _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut),
          );
          _animController.forward(from: 0);
        });
      });
    } else {
      // Snap back
      _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward(from: 0);
    }
  }

  void _animateToNextQuestion() {
    final screenWidth = MediaQuery.of(context).size.width;
    _slideAnimation = Tween<double>(begin: 0, end: -screenWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex++;
        _dragOffset = screenWidth;
        _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
        _animController.forward(from: 0);
      });
    });
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
    });

    widget.onCheck?.call();
  }

  void _resetCurrent() {
    final currentItem = _currentItem;
    if (currentItem == null) return;

    setState(() {
      _selectedIndices[currentItem.id] = [];
      _correctness[currentItem.id] = null;
      _isCheckedMap[currentItem.id] = false;
    });
  }

  String _getCorrectString() {
    final currentItem = _currentItem;
    if (currentItem == null) return '';
    return currentItem.validAnswers.firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final questions = widget.quiz.questions;
    final borderColor = Colors.grey.withValues(alpha: 0.5);

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

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Instruction (Fixed at top, outside text)
            if (widget.quiz.instruction.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16),
                  child: Wrap(
                    children: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                      onWordLongPress: widget.onWordLongPress,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ),

            // 2. Question Card (Takes remaining space)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final rotateAngle = _dragOffset * 0.001;
                      final opacity =
                          (1 - (_dragOffset.abs() / 500)).clamp(0.5, 1.0);
                      return Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: Transform.rotate(
                          angle: rotateAngle,
                          child: Opacity(opacity: opacity, child: child),
                        ),
                      );
                    },
                    child: Container(
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
                            // Card Header: Counter & Progress
                            _buildCardHeader(
                              context,
                              appColors,
                              widget.quiz.questions,
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
                                        color: _currentIsChecked
                                            ? (_currentIsCorrect ?? false
                                                ? Colors.green
                                                    .withValues(alpha: 0.1)
                                                : Colors.red
                                                    .withValues(alpha: 0.1))
                                            : appColors.cardBackground,
                                        border: Border.all(
                                          color: _currentIsChecked
                                              ? (_currentIsCorrect ?? false
                                                  ? Colors.green
                                                  : Colors.red)
                                              : appColors.primary
                                                  .withValues(alpha: 0.5),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _currentSelected.isEmpty
                                          ? Center(
                                              child: Text(
                                                'Tap blocks below to build',
                                                style: TextStyle(
                                                  color:
                                                      appColors.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children:
                                                  _currentSelected.map((index) {
                                                return GestureDetector(
                                                  onTap: () =>
                                                      _handleItemClick(index),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _currentIsChecked
                                                          ? appColors.background
                                                          : appColors.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      options[index],
                                                      style: TextStyle(
                                                        color: _currentIsChecked
                                                            ? appColors
                                                                .textPrimary
                                                            : Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    ),

                                    // Correct Answer (shown after check if wrong)
                                    if (_currentIsChecked &&
                                        _currentIsCorrect == false) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withValues(alpha: 0.1),
                                          border:
                                              Border.all(color: Colors.green),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                              _getCorrectString(),
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
                                    if (_currentIsChecked &&
                                        currentItem.explain.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: InkWell(
                                          onTap: () {
                                            widget.onShowExplain
                                                ?.call(currentItem.explain);
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
                                        children: options
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final word = entry.value;
                                          final isSelected =
                                              _currentSelected.contains(index);

                                          return GestureDetector(
                                            onTap: () =>
                                                _handleItemClick(index),
                                            child: AnimatedOpacity(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              opacity: isSelected ||
                                                      _currentIsChecked
                                                  ? 0.5
                                                  : 1.0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? appColors.background
                                                      : appColors
                                                          .cardBackground,
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
                                                                    alpha:
                                                                        0.05),
                                                            blurRadius: 2,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                ),
                                                child: Text(
                                                  word,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? appColors
                                                            .textSecondary
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
                                    const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 28,
          right: 36,
          child: _buildActionButtons(appColors),
        ),
      ],
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<QuizQuestion> questions,
  ) {
    final completedCount = _isCheckedMap.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Counter
          Text(
            '${_currentIndex + 1} / ${questions.length}',
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

  Widget _buildActionButtons(AppColorsExtension appColors) {
    if (_currentIsChecked) {
      return ElevatedButton.icon(
        onPressed: () {
          if (_currentIndex < widget.quiz.questions.length - 1) {
            _animateToNextQuestion();
          } else {
            widget.onCheck?.call();
            widget.onNext?.call();
          }
        },
        icon: const Icon(Icons.chevron_right, size: 20),
        label: const Text(
          'Next question',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      );
    }

    if (_currentSelected.length == _currentItem?.options.length) {
      return ElevatedButton.icon(
        onPressed: _checkAnswer,
        icon: const Icon(Icons.check, size: 20),
        label: const Text(
          'Check',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      );
    }

    if (_currentIsCorrect != true && _currentSelected.isNotEmpty) {
      return ElevatedButton.icon(
        onPressed: _resetCurrent,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text(
          'Reset',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: appColors.textSecondary,
          backgroundColor: appColors.cardBackground,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
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
