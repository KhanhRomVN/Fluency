import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RichTextParser {
  /// Parses the text content and builds a list of widgets.
  /// Supports tags: </gap id='...'>, </n>, <p>, <p style='...'>
  static List<Widget> buildRichText(
    BuildContext context,
    String content, {
    bool isQuestion = false,
    Widget? Function(String id)? onGapFound, // Callback to return gap widget
  }) {
    final List<Widget> widgets = [];
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final combinedRegex = RegExp(
      r"(</gap id='.*?'>)|(</n\s*?>)|(<p.*?>)|(</p>)",
      caseSensitive: false,
    );

    int lastIndex = 0;

    // Current style context
    bool isBold = false;
    bool isCenter = false;
    double? fontSize;

    // Debug logging for parser
    debugPrint('AG_LOG: RichTextParser input length: ${content.length}');
    // debugPrint('AG_LOG: RichTextParser input content: $content'); // Uncomment if needed, but it's long

    final matches = combinedRegex.allMatches(content);
    debugPrint('AG_LOG: RichTextParser found ${matches.length} matches');

    for (final match in matches) {
      if (match.start > lastIndex) {
        final text = content.substring(lastIndex, match.start);
        if (text.isNotEmpty) {
          _addText(
            widgets,
            text,
            isBold,
            isCenter,
            fontSize,
            appColors,
            context,
          );
        }
      }

      final tag = match.group(0)!;
      debugPrint('AG_LOG: Parsing tag: $tag at index ${match.start}');

      if (tag.toLowerCase().startsWith('</gap')) {
        if (isQuestion && onGapFound != null) {
          final idMatch = RegExp(r"id='(.*?)'").firstMatch(tag);
          final id = idMatch?.group(1);
          if (id != null) {
            final gapWidget = onGapFound(id);
            if (gapWidget != null) {
              widgets.add(gapWidget);
            }
          }
        }
      } else if (tag.toLowerCase().startsWith('</n')) {
        debugPrint('AG_LOG: Found Newline tag');
        _addNewline(widgets);
      } else if (tag.toLowerCase().startsWith('<p')) {
        isBold = tag.contains("bold");
        isCenter = tag.contains("center");

        if (isCenter) {
          _addNewline(widgets);
        }

        final fontSizeMatch = RegExp(r'\d+').firstMatch(tag);
        if (fontSizeMatch != null) {
          fontSize = double.tryParse(fontSizeMatch.group(0)!);
        }
      } else if (tag.toLowerCase() == '</p>') {
        isBold = false;
        isCenter = false;
        fontSize = null;
        if (!isCenter) {
          // Optional: Add break after paragraph?
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final text = content.substring(lastIndex);
      if (text.isNotEmpty) {
        _addText(
          widgets,
          text,
          isBold,
          isCenter,
          fontSize,
          appColors,
          context,
        );
      }
    }

    return widgets;
  }

  static void _addText(
    List<Widget> widgets,
    String text,
    bool isBold,
    bool isCenter,
    double? fontSize,
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
            fontSize: fontSize,
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

  static void _addNewline(List<Widget> widgets) {
    // Wrap doesn't like explicit line breaks easily unless we force a full width item.
    widgets.add(const SizedBox(width: double.infinity, height: 8));
  }
}
