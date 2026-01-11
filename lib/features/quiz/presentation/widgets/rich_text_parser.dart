import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RichTextParser {
  /// Parses the text content and builds a list of widgets.
  /// Supports tags: </gap id='...'>, </n>, <p>, <p style='...'>
  static List<Widget> buildRichText(
    BuildContext context,
    String content, {
    bool isQuestion = false,
    Widget? Function(String id)? onGapFound,
    void Function(String word)? onWordLongPress, // Callback for dictionary
    TextStyle? style,
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

    final matches = combinedRegex.allMatches(content);
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
            onWordLongPress: onWordLongPress,
            textStyle: style,
          );
        }
      }

      final tag = match.group(0)!;

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
          onWordLongPress: onWordLongPress,
          textStyle: style,
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
    BuildContext context, {
    void Function(String word)? onWordLongPress,
    TextStyle? textStyle,
  }) {
    final style =
        (textStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
      color: appColors.textPrimary,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: fontSize,
      height: 1.5,
    );

    // If no interaction needed or centered text (usually titles), just render text
    if (onWordLongPress == null || isCenter) {
      final widget = Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: style,
      );

      if (isCenter) {
        widgets.add(
          SizedBox(
            width: double.infinity,
            child: widget,
          ),
        );
      } else {
        widgets.add(widget);
      }
      return;
    }

    // Split by space but keep delimiters or handle carefully
    // Simple approach: split by space, wrapped in Wrap/RichText is tricky
    // Better approach: Use RichText with TextSpans for each word

    // We are adding to a list of widgets that will likely be in a Wrap.
    // If we return a single RichText, it might not wrap correctly with previous siblings if they are separate widgets?
    // RichTextParser.buildRichText returns List<Widget>.

    // Let's split the text into words using regex to keep punctuation separate or part of word?
    // Users interact with "words". Punctuation shouldn't be long-pressed usually.

    // Regex to match words and non-words
    final RegExp tokenRegex = RegExp(r"(\w+)|([^\w\s]+)|(\s+)");
    final List<InlineSpan> spans = [];

    for (final match in tokenRegex.allMatches(text)) {
      final token = match.group(0)!;
      final isWord = match.group(1) != null;

      if (isWord) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onLongPress: () => onWordLongPress(token),
              child: Text(
                token,
                style: style,
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: style));
      }
    }

    widgets.add(Text.rich(TextSpan(children: spans)));
  }

  static void _addNewline(List<Widget> widgets) {
    // Wrap doesn't like explicit line breaks easily unless we force a full width item.
    widgets.add(const SizedBox(width: double.infinity, height: 8));
  }

  /// Parses content into a list of InlineSpans for use in Text.rich or RichText.
  /// Better for inline flow than buildRichText (which returns separate Widgets).
  static List<InlineSpan> buildTextSpans(
    BuildContext context,
    String content, {
    bool isQuestion = false,
    Widget? Function(String id)? onGapFound,
    void Function(String word)? onWordLongPress,
  }) {
    final List<InlineSpan> spans = [];
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final combinedRegex = RegExp(
      r"(</gap id='.*?'>)|(</n\s*?>)|(<p.*?>)|(</p>)",
      caseSensitive: false,
    );

    int lastIndex = 0;

    // Current style context
    bool isBold = false;
    double? fontSize;

    void addTextSpan(String text) {
      final style = TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: fontSize,
        color: appColors.textPrimary,
      );

      if (onWordLongPress == null) {
        spans.add(TextSpan(text: text, style: style));
      } else {
        final RegExp tokenRegex = RegExp(r"(\w+)|([^\w\s]+)|(\s+)");
        for (final match in tokenRegex.allMatches(text)) {
          final token = match.group(0)!;
          final isWord = match.group(1) != null;

          if (isWord) {
            spans.add(
              TextSpan(
                text: token,
                style: style,
                recognizer: LongPressGestureRecognizer()
                  ..onLongPress = () => onWordLongPress(token),
              ),
            );
          } else {
            spans.add(TextSpan(text: token, style: style));
          }
        }
      }
    }

    final matches = combinedRegex.allMatches(content);
    for (final match in matches) {
      if (match.start > lastIndex) {
        final text = content.substring(lastIndex, match.start);
        if (text.isNotEmpty) {
          addTextSpan(text);
        }
      }

      final tag = match.group(0)!;

      if (tag.toLowerCase().startsWith('</gap')) {
        if (isQuestion && onGapFound != null) {
          final idMatch = RegExp(r"id='(.*?)'").firstMatch(tag);
          final id = idMatch?.group(1);
          if (id != null) {
            final gapWidget = onGapFound(id);
            if (gapWidget != null) {
              spans.add(
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: gapWidget,
                ),
              );
            }
          }
        }
      } else if (tag.toLowerCase().startsWith('</n')) {
        spans.add(const TextSpan(text: '\n'));
      } else if (tag.toLowerCase().startsWith('<p')) {
        isBold = tag.contains("bold");
        final fontSizeMatch = RegExp(r'\d+').firstMatch(tag);
        if (fontSizeMatch != null) {
          fontSize = double.tryParse(fontSizeMatch.group(0)!);
        }
      } else if (tag.toLowerCase() == '</p>') {
        isBold = false;
        fontSize = null;
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final text = content.substring(lastIndex);
      if (text.isNotEmpty) {
        addTextSpan(text);
      }
    }

    return spans;
  }
}
