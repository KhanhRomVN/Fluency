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
        'Chọn đáp án đúng nhất từ các lựa chọn được cung cấp. Nhấn Submit để kiểm tra câu trả lời của bạn.',
    'gap-fill-typing':
        'Điền từ thích hợp vào chỗ trống. Gõ câu trả lời và nhấn Submit khi hoàn thành.',
    'gap-fill-dropdown':
        'Chọn từ phù hợp từ menu dropdown để điền vào chỗ trống. Nhấn Submit để kiểm tra.',
    'listening-choice':
        'Nghe audio và chọn đáp án đúng. Bạn có thể nghe lại nhiều lần bằng cách nhấn nút play.',
    'matching-dropdown':
        'Ghép các cặp từ/cụm từ phù hợp với nhau bằng cách chọn từ dropdown.',
    'sentence-transformation':
        'Chuyển đổi câu theo yêu cầu. Nhập câu trả lời và nhấn Submit.',
    'builder': 'Sắp xếp các từ theo đúng thứ tự để tạo thành câu hoàn chỉnh.',
    'error-correction':
        'Tìm và sửa lỗi trong câu. Nhấp vào từ sai và chọn từ đúng.',
    'pronunciation-drill':
        'Luyện phát âm bằng cách đọc theo văn bản. Nhấn nút mic để ghi âm và kiểm tra.',
    'dictation-audio':
        'Nghe audio và viết lại những gì bạn nghe được. Nhấn Submit khi hoàn thành.',
    'speaking-essay':
        'Trả lời câu hỏi bằng giọng nói. Nhấn mic để bắt đầu ghi âm câu trả lời.',
    'writing-essay':
        'Viết bài luận ngắn theo chủ đề. Nhập câu trả lời và nhấn Submit.',
    'flashcard':
        'Xem từ vựng và nghĩa. Vuốt sang trái/phải để chuyển card. Nhấn vào card để lật.',
    'free-chat': 'Trò chuyện tự do với AI. Nói hoặc gõ câu trả lời của bạn.',
    'scripted-chat':
        'Thực hành hội thoại theo kịch bản. Đọc và trả lời theo vai trò được chỉ định.',
    'speech-builder':
        'Xây dựng câu bằng giọng nói. Nói từng phần và hệ thống sẽ ghép lại.',
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
                color: appColors.cardBackground,
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
                              'assets/icons/circle_dot_dashed.svg',
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
                              'assets/icons/x.svg',
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
