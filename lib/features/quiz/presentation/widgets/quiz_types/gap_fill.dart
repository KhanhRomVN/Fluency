import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GapFill extends StatefulWidget {
  const GapFill({
    required this.question,
    required this.answers,
    this.onCheck,
    super.key,
  });

  final String question;
  final List<QuizAnswer> answers;
  final VoidCallback? onCheck;

  @override
  State<GapFill> createState() => _GapFillState();
}

class _GapFillState extends State<GapFill> {
  // Map of gap ID to text controller
  final Map<String, TextEditingController> _controllers = {};
  bool _isChecked = false;
  bool _areAllGapsFilled = false;

  @override
  void initState() {
    super.initState();
    _parseGaps();
  }

  @override
  void didUpdateWidget(covariant GapFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _parseGaps(); // Re-parse if question changes
    }
  }

  void _parseGaps() {
    _controllers.clear(); // Clear old controllers if re-parsing
    final regex = RegExp(r"</gap id='(.*?)'>");
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
    // Using SingleChildScrollView if the content is long
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,

                runSpacing: 4, // Reduced from 8
                children: _buildContent(context),
              ),
            ),
          ),
        ),
        if (_areAllGapsFilled && !_isChecked)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isChecked = true;
                  });
                  debugPrint(
                      'AG_LOG: GapFill Check Answers pressed. Calling widget.onCheck');
                  widget.onCheck?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Check answers', // CONSIDER: Localize this
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Parses the question string and builds a list of widgets.
  /// Supported tags:
  /// - </gap id='...'>: Input field
  /// - </n>: Line break
  /// - <p>: Text block
  /// - <p style='...'>: Text block with style ('bold', 'center')
  List<Widget> _buildContent(BuildContext context) {
    return _buildRichText(context, widget.question, isQuestion: true);
  }

  /// Parses the text content and builds a list of widgets.
  /// Supports tags: </gap id='...'>, </n>, <p>, <p style='...'>
  List<Widget> _buildRichText(
    BuildContext context,
    String content, {
    bool isQuestion = false,
  }) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return RichTextParser.buildRichText(
      context,
      content,
      isQuestion: isQuestion,
      onGapFound: (id) => _createGapWidget(id, appColors, context),
    );
  }

  // _addText and _addNewline removed as they are handled by RichTextParser

  Widget _createGapWidget(
    String id,
    AppColorsExtension appColors,
    BuildContext context,
  ) {
    // Find the answer for this gap
    final answer = widget.answers.firstWhere(
      (a) => a.id == id,
      orElse: () => const QuizAnswer(id: '', answer: '', explain: ''),
    );
    final maxLength = answer.answer.isNotEmpty ? answer.answer.length : 20;
    final controller = _controllers[id]!;
    final userAnswer = controller.text;
    final isCorrect =
        userAnswer.toLowerCase().trim() == answer.answer.toLowerCase().trim();

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
              answer.answer,
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
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
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
                vertical: 0,
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
            ),
          ),
        ),
      );
    }
  }

  void _showExplanation(BuildContext context, QuizAnswer answer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: appColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Explanation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: _buildRichText(
                      context,
                      answer.explain.isNotEmpty
                          ? answer.explain
                          : '<p>No explanation available.</p>',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
