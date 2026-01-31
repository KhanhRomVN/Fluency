import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingDropdown extends StatefulWidget {
  const MatchingDropdown({
    required this.quiz,
    required this.lessonId,
    required this.onCheck,
    super.key,
    this.onShowExplain,
    this.onWordLongPress,
    this.onNext,
  });

  final Quiz quiz;
  final String lessonId;
  final VoidCallback onCheck;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;

  @override
  State<MatchingDropdown> createState() => _MatchingDropdownState();
}

class _MatchingDropdownState extends State<MatchingDropdown>
    with SingleTickerProviderStateMixin {
  Map<String, String> _selectedAnswers = {};
  bool _isChecked = false;

  // Animation variables
  late AnimationController _animController;
  double _dragOffset = 0;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _resetAnswers();
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

    // Load saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = screenWidth * 0.25;

    // MatchingDropdown might handle "Next" via button usually,
    // but we can add swipe to next if it makes sense contextually.
    // However, usually swipe to next happens after check.
    // If not checked, maybe prevent swipe or just partial logic?
    // Let's assume standard behavior: swipe changes question if applicable?
    // MatchingDropdown seems to be ONE question (the quiz has list of matching items).
    // But `quiz.matchings` is a list, displayed in a listview.
    // The widget `MatchingDropdown` usually represents ONE Quiz item which contains multiple matchings.
    // The `onNext` callback suggests there is a parent controller moving to next quiz.
    // So swipe left -> should trigger onNext if finished?

    // Logic:
    // Swipe Left (Next):
    //   If Checked -> trigger onNext
    //   If Not Checked -> maybe nothing (require check first?) OR if all answered, trigger check?
    // Swipe Right (Prev):
    //   Usually no prev action defined in callbacks (only onNext), so maybe just bounce back?

    // Let's implement:
    // Swipe Left: If Checked -> Next.

    var shouldChange = false;
    // Only support Next via swipe if checked?
    // Or if user insists.
    // Given the button logic:
    // If All Answered & !Checked -> Check
    // If Checked -> Next

    if (velocity < -1000 || _dragOffset < -threshold) {
      // Swipe Left
      if (_isChecked && widget.onNext != null) {
        shouldChange = true;
      }
    }

    if (shouldChange) {
      final endX = -screenWidth;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: endX).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );

      _animController.forward(from: 0).then((_) {
        // Trigger generic next
        widget.onNext?.call();
        // Reset (though widget might be replaced/rebuilt)
        setState(() {
          _dragOffset = 0; // If we stay on same widget instance for next quiz?
          // If widget is replaced, this doesn't matter much.
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

  @override
  void didUpdateWidget(MatchingDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id) {
      _resetAnswers();
      // Slide in animation?
      _dragOffset = MediaQuery.of(context).size.width;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward(from: 0);
    }
  }

  void _resetAnswers() {
    _selectedAnswers = {};
    _isChecked = false;
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final matchings = widget.quiz.matchings ?? [];
    final borderColor = Colors.grey.withValues(alpha: 0.5);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction

            // Dashed Border Card
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            // Provide space for floating buttons
                            const SizedBox(height: 80),
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

  Widget _buildActionButtons(AppColorsExtension appColors) {
    if (_areAllAnswered && !_isChecked) {
      return ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            _isChecked = true;
          });
          widget.onCheck();
          await _saveProgress();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        icon: const Icon(Icons.check, size: 18),
        label: const Text(
          'Check answers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isChecked && widget.onNext != null) {
      return ElevatedButton.icon(
        onPressed: widget.onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text(
          'Next question',
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
        borderColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        iconColor = Colors.green;
      } else {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        iconColor = Colors.red;
      }
    } else {
      borderColor = selectedKey.isNotEmpty
          ? appColors.primary
          : appColors.border.withValues(alpha: 0.8);
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
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.all(0),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        fixedSize: WidgetStateProperty.all(
                          Size.fromWidth(constraints.maxWidth),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: appColors.border.withValues(alpha: 0.5),
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
                              }
                            },
                      dropdownMenuEntries:
                          _options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final opt = entry.value;
                        final isLast = index == _options.length - 1;

                        return DropdownMenuEntry<String>(
                          value: opt.key,
                          label: opt.value,
                          labelWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
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
                              if (!isLast)
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
    _selectedAnswers.forEach((id, selectedKey) {
      final matching = widget.quiz.matchings?.firstWhere((m) => m.id == id);
      if (matching != null) {
        final correctKey = _getCorrectOptionKey(matching.answer);
        if (selectedKey == correctKey) {
          correctCount++;
        }
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
      },
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
