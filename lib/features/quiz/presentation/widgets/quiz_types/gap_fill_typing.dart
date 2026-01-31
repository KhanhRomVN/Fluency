import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GapFillTyping extends StatefulWidget {
  const GapFillTyping({
    required this.lessonId,
    required this.quizId,
    required this.question,
    required this.answers,
    this.title,
    this.instruction,
    this.onCheck,
    this.onShowExplain,
    this.hasAudio = false,
    this.onWordLongPress,
    this.onNext, // Support for next action if needed
    super.key,
  });

  final String lessonId;
  final String quizId;
  final String question;
  final List<QuizAnswer> answers;
  final String? title;
  final String? instruction;
  final VoidCallback? onCheck;
  final void Function(String explanation)? onShowExplain;
  final bool hasAudio;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;

  @override
  State<GapFillTyping> createState() => _GapFillTypingState();
}

class _GapFillTypingState extends State<GapFillTyping> {
  // Map of gap ID to text controller
  final Map<String, TextEditingController> _controllers = {};
  bool _isChecked = false;
  bool _areAllGapsFilled = false;

  @override
  void initState() {
    super.initState();
    _parseGaps();

    // Load saved progress
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

        // Restore user answers
        final savedAnswers =
            progress.data?['userAnswers'] as Map<String, dynamic>?;
        if (savedAnswers != null) {
          savedAnswers.forEach((key, value) {
            if (_controllers.containsKey(key)) {
              _controllers[key]!.text = value as String;
            }
          });
        }

        // Check if all filled based on restored data
        _checkIfAllGapsFilled();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GapFillTyping oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      // Reset state when question changes
      setState(() {
        _isChecked = false;
        _areAllGapsFilled = false;
      });
      _parseGaps();
    }
  }

  void _parseGaps() {
    _controllers.clear(); // Clear old controllers if re-parsing
    final regex = RegExp("</gap id='(.*?)'>");
    final matches = regex.allMatches(widget.question);
    for (final match in matches) {
      final id = match.group(1);
      if (id != null) {
        _controllers[id] = TextEditingController();
        _controllers[id]!.addListener(_checkIfAllGapsFilled);
      }
    }
    _checkIfAllGapsFilled();
  }

  void _checkIfAllGapsFilled() {
    final allFilled = _controllers.values.every((c) => c.text.isNotEmpty);
    if (allFilled != _areAllGapsFilled) {
      setState(() {
        _areAllGapsFilled = allFilled;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            // 1. Instruction (Fixed at top, outside text)

            // 2. Question Card (Takes remaining space)
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
                          // Spacing at bottom for scrolling past floating button
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

        // Floating Action Buttons
        Positioned(
          bottom: 28, // 20 + 8px padding của card
          right: 36, // 20 + 16px padding của card
          child: _buildActionButtons(appColors),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    // Check Button: Show when all gaps filled AND not checked yet
    if (_areAllGapsFilled && !_isChecked) {
      return ElevatedButton.icon(
        onPressed: () async {
          setState(() {
            _isChecked = true;
          });
          widget.onCheck?.call();
          await _saveProgress();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4, // Shadow for floating effect
        ),
        icon: const Icon(Icons.check, size: 18),
        label: const Text(
          'Check answers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    // Next Button: Show when checked AND onNext is provided (optional, based on GapFillTyping.tsx logic)
    // The previous implementation didn't strictly have a "Next" button inside GapFill,
    // likely relying on the parent or just staying in checked state.
    // However, the React code shows a "Next question" button.
    // We will support it if onNext is passed, basically acting as a "Finish" or "Next" trigger.
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

  /// Parses the question string and builds a list of widgets.
  Widget _buildContent(BuildContext context) {
    return _buildRichText(context, widget.question, isQuestion: true);
  }

  /// Parses the text content and builds a list of widgets.
  Widget _buildRichText(
    BuildContext context,
    String content, {
    bool isQuestion = false,
  }) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // Use buildTextSpans to get InlineSpans and wrap them in a single Text.rich
    // This allows natural text wrapping with inline widgets (gaps).
    final spans = RichTextParser.buildTextSpans(
      context,
      content,
      isQuestion: isQuestion,
      onGapFound: (id) => _createGapWidget(id, appColors, context),
      onWordLongPress: widget.onWordLongPress,
    );

    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.8, // Comfortable line height
            color: appColors.textPrimary,
          ),
    );
  }

  Widget _createGapWidget(
    String id,
    AppColorsExtension appColors,
    BuildContext context,
  ) {
    // Find the answer for this gap
    final answer = widget.answers.firstWhere(
      (a) => a.id == id,
      orElse: () => const QuizAnswer(id: '', answer: [], explain: ''),
    );
    final controller = _controllers[id]!;
    final userAnswer = controller.text;
    final isCorrect = answer.answer.any(
      (ans) => userAnswer.toLowerCase().trim() == ans.toLowerCase().trim(),
    );

    if (_isChecked) {
      Widget content;
      if (isCorrect) {
        // Correct case: Text in Primary Color
        content = Text(
          userAnswer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.primary,
                fontWeight: FontWeight.bold,
              ),
        );
      } else {
        // Incorrect case: User text red strikethrough + Correct text primary
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userAnswer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              answer.answer.firstOrNull ?? '',
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
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: content,
        ),
      );
    } else {
      // Normal Input Case
      return IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: TextField(
            controller: controller,
            // maxLength: maxLength, // Removed explicit maxLength to match React "auto-width" feel better visually
            maxLengthEnforcement: MaxLengthEnforcement.none,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) =>
                null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              hintText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: appColors.primary.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: appColors.primary,
                  width: 2,
                ),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
            onChanged: (val) {
              // Force rebuild to check input state for button visibility
              _checkIfAllGapsFilled();
            },
          ),
        ),
      );
    }
  }

  void _showExplanation(BuildContext context, QuizAnswer answer) {
    if (widget.onShowExplain != null) {
      // If callback provided, use it
      final explanation = answer.explain.isNotEmpty
          ? answer.explain
          : '<p>No explanation available.</p>';
      widget.onShowExplain!(explanation);
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Prepare data to save
    final userAnswers = <String, String>{};
    _controllers.forEach((key, controller) {
      userAnswers[key] = controller.text;
    });

    // Calculate correctness for progress
    // Count how many gaps are correct
    var correctCount = 0;
    if (_isChecked) {
      for (final answer in widget.answers) {
        final controller = _controllers[answer.id];
        if (controller != null) {
          final userAnswer = controller.text;
          final isCorrect = answer.answer.any(
            (ans) =>
                userAnswer.toLowerCase().trim() == ans.toLowerCase().trim(),
          );
          if (isCorrect) correctCount++;
        }
      }
    }

    final totalGaps = widget.answers.length;
    final filledGaps =
        _controllers.values.where((c) => c.text.isNotEmpty).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'gap-fill-typing',
      completedItems: filledGaps,
      totalItems: totalGaps,
      correctItems: correctCount,
      data: {
        'isChecked': _isChecked,
        'userAnswers': userAnswers,
        'correctCount': correctCount,
        'totalGaps': totalGaps,
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painters (Copied from MultipleChoice for consistency)
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
