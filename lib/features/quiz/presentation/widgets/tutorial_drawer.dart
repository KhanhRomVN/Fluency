import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TutorialDrawer extends StatelessWidget {
  const TutorialDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.content,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String content;

  // Parse HTML-like content to TextSpans for inline rendering
  List<TextSpan> _parseContentToTextSpans(
      BuildContext context, String content) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final List<TextSpan> spans = [];

    // Remove line breaks first
    String processedContent = content.replaceAll('</n>', ' ');

    // Parse tags
    final tagRegex =
        RegExp(r"<p\s*(?:style='([^']*)')?>|</p>", caseSensitive: false);
    int lastIndex = 0;

    bool isBold = false;
    bool isItalic = false;

    for (final match in tagRegex.allMatches(processedContent)) {
      // Add text before this tag
      if (match.start > lastIndex) {
        final text = processedContent.substring(lastIndex, match.start);
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ));
        }
      }

      final tag = match.group(0)!;
      if (tag.startsWith('<p')) {
        final styleAttr = match.group(1);
        if (styleAttr != null) {
          isBold = styleAttr.contains('bold');
          isItalic = styleAttr.contains('italic');
        }
      } else if (tag == '</p>') {
        isBold = false;
        isItalic = false;
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < processedContent.length) {
      final text = processedContent.substring(lastIndex);
      if (text.isNotEmpty) {
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          ),
        ));
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: appColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: appColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'icons/circle_dot_dashed.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                appColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tutorial',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'icons/x.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                appColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: appColors.border.withValues(alpha: 0.5),
                    height: 1,
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: appColors.textPrimary,
                                    height: 1.6,
                                  ),
                          children: _parseContentToTextSpans(context, content),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
