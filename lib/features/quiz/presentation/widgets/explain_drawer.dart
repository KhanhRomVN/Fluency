import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExplainDrawer extends StatefulWidget {
  const ExplainDrawer({
    required this.isOpen,
    required this.onClose,
    required this.explanation,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String explanation;

  @override
  State<ExplainDrawer> createState() => _ExplainDrawerState();
}

class _ExplainDrawerState extends State<ExplainDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ExplainDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Parse HTML-like content to TextSpans for inline rendering
  List<TextSpan> _parseContentToTextSpans(
    BuildContext context,
    String content,
  ) {
    final spans = <TextSpan>[];

    // Remove line breaks first
    final processedContent = content.replaceAll('</n>', ' ');

    // Parse tags
    final tagRegex =
        RegExp(r"<p\s*(?:style='([^']*)')?>|</p>", caseSensitive: false);
    var lastIndex = 0;

    var isBold = false;
    var isItalic = false;

    for (final match in tagRegex.allMatches(processedContent)) {
      // Add text before this tag
      if (match.start > lastIndex) {
        final text = processedContent.substring(lastIndex, match.start);
        if (text.isNotEmpty) {
          spans.add(
            TextSpan(
              text: text,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          );
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
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    // Only build if open or animating, otherwise hide completely
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0 && !widget.isOpen) {
          return const SizedBox.shrink();
        }

        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        final content = widget.explanation.trim().isEmpty
            ? 'No explanation available.'
            : widget.explanation;

        return Stack(
          children: [
            // Backdrop with Fade
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Drawer with Slide
            SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.70,
                    decoration: BoxDecoration(
                      color: appColors.drawerBackground,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: appColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Detailed analysis of the content',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: appColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: widget.onClose,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: appColors.inputBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: appColors.border
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/x.svg',
                                      width: 14,
                                      height: 14,
                                      colorFilter: ColorFilter.mode(
                                        appColors.textSecondary,
                                        BlendMode.srcIn,
                                      ),
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: appColors.textPrimary,
                                        height: 1.6,
                                        fontSize: 16,
                                      ),
                                  children: _parseContentToTextSpans(
                                    context,
                                    content,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
