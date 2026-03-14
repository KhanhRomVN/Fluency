import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TutorialDrawer extends StatelessWidget {
  const TutorialDrawer({
    required this.isOpen,
    required this.onClose,
    required this.content,
    required this.quizType,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String content;
  final String quizType;

  // Map quiz types to general instructions
  static const Map<String, String> _quizTypeInstructions = {
    'multiple-choice':
        'Select the best answer from the provided options. Press Submit to check your answer.',
    'gap-fill-typing':
        'Fill in the blanks with the appropriate words. Type your answers and press Submit when finished.',
    'gap-fill-dropdown':
        'Choose the correct word from the dropdown menu to fill in the blank. Press Submit to check.',
    'listening-choice':
        'Listen to the audio and select the correct answer. You can replay the audio by pressing the play button.',
    'matching-dropdown':
        'Match the corresponding pairs of words or phrases by selecting from the dropdown menu.',
    'sentence-transformation':
        'Transform the sentence as required. Enter your answer and press Submit.',
    'builder':
        'Arrange the words in the correct order to form a complete sentence.',
    'error-correction':
        'Find and correct the error in the sentence. Click the incorrect word and choose the corrected version.',
    'pronunciation-drill':
        'Practice pronunciation by reading out loud. Press the mic button to record and check.',
    'dictation-audio':
        'Listen to the audio and write down what you hear. Press Submit when finished.',
    'speaking-essay':
        'Answer the question using your voice. Press the mic to start recording your response.',
    'writing-essay':
        'Write a short essay based on the topic. Enter your response and press Submit.',
    'flashcard':
        'Review words and their meanings. Swipe left/right to move through cards. Tap the card to flip.',
    'free-chat': 'Chat freely with the AI. Speak or type your response.',
    'scripted-chat':
        'Practice conversation based on a script. Read and respond according to your assigned role.',
    'speech-builder':
        'Build sentences using your voice. Speak each part and the system will combine them.',
  };

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tutorial',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: appColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Learn how to complete this quiz',
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
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: appColors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: appColors.border.withValues(alpha: 0.4),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Question Instruction
                          if (content.isNotEmpty) ...[
                            _buildSectionLabel(
                              context,
                              appColors,
                              'Question Instruction',
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildInstructionCard(
                              context,
                              appColors,
                              content,
                              sectionColor: Colors.green,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section 2: Quiz Type Guide
                          _buildSectionLabel(
                            context,
                            appColors,
                            'How to Complete This Quiz',
                            Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionCard(
                            context,
                            appColors,
                            _quizTypeInstructions[quizType] ??
                                'Làm theo hướng dẫn và nhấn Submit khi hoàn thành.',
                            sectionColor: Colors.orange,
                          ),
                        ],
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

  Widget _buildSectionLabel(
    BuildContext context,
    AppColorsExtension appColors,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: appColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard(
    BuildContext context,
    AppColorsExtension appColors,
    String text, {
    required Color sectionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sectionColor.withValues(alpha: 0.3),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.textPrimary,
                height: 1.6,
              ),
          children: _parseContentToTextSpans(context, text),
        ),
      ),
    );
  }
}
