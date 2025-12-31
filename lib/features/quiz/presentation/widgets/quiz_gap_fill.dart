import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizGapFill extends StatefulWidget {
  const QuizGapFill({
    required this.question,
    required this.answers,
    super.key,
  });

  final String question;
  final List<QuizAnswer> answers;

  @override
  State<QuizGapFill> createState() => _QuizGapFillState();
}

class _QuizGapFillState extends State<QuizGapFill> {
  // Map of gap ID to text controller
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _parseGaps();
  }

  @override
  void didUpdateWidget(covariant QuizGapFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _parseGaps(); // Re-parse if question changes
    }
  }

  void _parseGaps() {
    final regex = RegExp(r"</gap id='(.*?)'>");
    final matches = regex.allMatches(widget.question);
    for (final match in matches) {
      final id = match.group(1);
      if (id != null && !_controllers.containsKey(id)) {
        _controllers[id] = TextEditingController();
      }
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,

          runSpacing: 4, // Reduced from 8
          children: _buildContent(context),
        ),
      ),
    );
  }

  /// Parses the question string and builds a list of widgets.
  /// Supported tags:
  /// - </gap id='...'>: Input field
  /// - </n>: Line break
  /// - <p>: Text block
  /// - <p style='...'>: Text block with style ('bold', 'center')
  List<Widget> _buildContent(BuildContext context) {
    final List<Widget> widgets = [];
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    // Regex to split by interesting tags: gaps, newlines, and paragraphs
    // Strategy:
    // 1. Split by <tags> or </tags> to identify parts.
    // However, regex split is tricky.
    // Better: Iterate through the string matching our known tags.
    //
    // Known patterns:
    // Gap: `</gap id='...'>`
    // Newline: `</n>`
    // Paragrah start: `<p...>` (greedy to capture attributes)
    // Paragraph end: `</p>`

    final combinedRegex = RegExp(
      r"(</gap id='.*?'>)|(</n>)|(<p.*?>)|(</p>)",
      caseSensitive: false,
    );

    int lastIndex = 0;
    // Current style context
    bool isBold = false;
    bool isCenter = false;

    final matches = combinedRegex.allMatches(widget.question);

    for (final match in matches) {
      // 1. Handle text BEFORE the match
      if (match.start > lastIndex) {
        final text = widget.question.substring(lastIndex, match.start);
        if (text.isNotEmpty) {
          _addText(widgets, text, isBold, isCenter, appColors, context);
        }
      }

      // 2. Handle the tag itself
      final tag = match.group(0)!;

      if (tag.toLowerCase().startsWith('</gap')) {
        // Parse ID
        final idMatch = RegExp(r"id='(.*?)'").firstMatch(tag);
        final id = idMatch?.group(1);
        if (id != null) {
          _addGap(widgets, id, appColors, context);
        }
      } else if (tag.toLowerCase() == '</n>') {
        _addNewline(widgets);
      } else if (tag.toLowerCase().startsWith('<p')) {
        // Parse style
        // Reset styles for new paragraph? HTML typically doesn't unless nested.
        // Assuming simple non-nested p tags for now based on example.
        isBold = tag.contains("bold");
        isCenter = tag.contains("center");

        // If 'center', we might want the whole line centered.
        // Wrap implementation makes true centering tricky if mixed with others.
        // If center is requested, force a full width container matching the alignment?
        // For 'Wrap', 'center' usually means alignment.
        // Ideally, <p> blocks should be separate Wrap/Columns, but here we are in a single flow.
        // If 'center' is detected, we could insert a request to break line before?
        if (isCenter) {
          _addNewline(widgets);
          // In a Wrap, centering text specifically is hard without checking full width.
          // A hack: use a full-width container for centered text if it's the whole line.
        }
      } else if (tag.toLowerCase() == '</p>') {
        // Reset styles
        isBold = false;
        // isCenter = false; // logic depends on if we treat p as block or span
        // Usually <p> implies block, so add newline after it
        if (!isCenter) {
          // If it was centered, we probably handled it.
          // But generally <p> ends with a line break.
          // Let's add a small break.
        }
        // Is user using </n> separately? Yes.
        // So maybe <p> is just span styling in this context aside from explicit </n>?
        // The example: <p ...>Transport survey</p></n> -> explicit \n is used.
        // So <p> might just be for styling span.
        isCenter = false;
      }

      lastIndex = match.end;
    }

    // Handle remaining text
    if (lastIndex < widget.question.length) {
      final text = widget.question.substring(lastIndex);
      if (text.isNotEmpty) {
        _addText(widgets, text, isBold, isCenter, appColors, context);
      }
    }

    return widgets;
  }

  void _addText(
    List<Widget> widgets,
    String text,
    bool isBold,
    bool isCenter,
    AppColorsExtension appColors,
    BuildContext context,
  ) {
    // If text is purely whitespace/newlines that we want to ignore?
    // user input might have \n chars.

    final widget = Text(
      text,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: appColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            height: 1.5,
          ),
    );

    if (isCenter) {
      // Force full width to center effectively in a Wrap if it's alone,
      // or just trust TextAlign if it spans.
      // Wrap doesn't respect TextAlign of children unless they fill width.
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: widget,
        ),
      );
    } else {
      widgets.add(widget);
    }
  }

  void _addNewline(List<Widget> widgets) {
    // Wrap doesn't like explicit line breaks easily unless we force a full width item.
    widgets.add(const SizedBox(width: double.infinity, height: 8));
  }

  void _addGap(
    List<Widget> widgets,
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

    widgets.add(
      IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: TextField(
            controller: _controllers[id],
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
      ),
    );
  }
}
