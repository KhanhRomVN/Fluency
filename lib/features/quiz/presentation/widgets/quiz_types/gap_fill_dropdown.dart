import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GapFillDropdown extends StatefulWidget {
  const GapFillDropdown({
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
    super.key,
  });

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

  @override
  State<GapFillDropdown> createState() => _GapFillDropdownState();
}

class _GapFillDropdownState extends State<GapFillDropdown> {
  // Map of gap ID to selected value
  final Map<String, String> _selections = {};
  bool _isChecked = false;
  bool _areAllGapsFilled = false;

  @override
  void initState() {
    super.initState();
    _initializeSelections();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
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
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    final totalGaps = widget.answers.length;
    final filledGaps = _selections.values.where((v) => v.isNotEmpty).length;

    int correctGaps = 0;
    if (_isChecked) {
      for (final answer in widget.answers) {
        final selectedValue = _selections[answer.id] ?? '';
        final isCorrect = answer.answer.any(
          (ans) =>
              selectedValue.toLowerCase().trim() == ans.toLowerCase().trim(),
        );
        if (isCorrect) {
          correctGaps++;
        }
      }
    }

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'gap-fill-dropdown',
      completedItems: filledGaps,
      totalItems: totalGaps,
      correctItems: correctGaps,
      data: {
        'isChecked': _isChecked,
        'selections': _selections,
      },
    );
  }

  @override
  void didUpdateWidget(covariant GapFillDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      setState(() {
        _isChecked = false;
        _areAllGapsFilled = false;
      });
      _initializeSelections();
    }
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
    _checkIfAllGapsFilled();
  }

  void _checkIfAllGapsFilled() {
    final allFilled = _selections.values.every((val) => val.isNotEmpty);
    if (allFilled != _areAllGapsFilled) {
      setState(() {
        _areAllGapsFilled = allFilled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final borderColor = Colors.grey.withValues(alpha: 0.5);

    return Stack(
      children: [
        // Main Content Area
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Action Buttons
        Positioned(
          bottom: 28,
          right: 36,
          child: _buildActionButtons(appColors),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    if (_areAllGapsFilled && !_isChecked) {
      return ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isChecked = true;
          });
          _saveProgress();
          widget.onCheck?.call();
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

    // Use options from answer object if available, otherwise fallback to possible answers
    final options =
        answer.options.isNotEmpty ? answer.options : possibleAnswers;

    return _DropdownTrigger(
      value: selectedValue,
      options: options,
      onChanged: (val) {
        setState(() {
          _selections[id] = val;
        });
        _checkIfAllGapsFilled();
        _saveProgress();
      },
      appColors: appColors,
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
    required this.onChanged,
    required this.appColors,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final AppColorsExtension appColors;

  @override
  Widget build(BuildContext context) {
    // Determine width based on longest option or current value
    final displayValue = value.isEmpty ? 'Select...' : value;

    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: Colors.white,
      ),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        offset: const Offset(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => options
            .map(
              (opt) => PopupMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: TextStyle(
                    color: value == opt
                        ? appColors.primary
                        : appColors.textPrimary,
                    fontWeight:
                        value == opt ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: appColors.primary
                    .withValues(alpha: value.isEmpty ? 0.3 : 1.0),
                width: value.isEmpty ? 1 : 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayValue,
                style: TextStyle(
                  color: value.isEmpty
                      ? appColors.textSecondary.withValues(alpha: 0.5)
                      : appColors.textPrimary,
                  fontWeight:
                      value.isEmpty ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: appColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painters (Copied for consistency)
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
