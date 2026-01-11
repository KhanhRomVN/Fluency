import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class ChattingSpeech extends StatefulWidget {
  const ChattingSpeech({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<ChattingSpeech> createState() => _ChattingSpeechState();
}

class _ChattingSpeechState extends State<ChattingSpeech> {
  // Map<MessageID, isIpaVisible>
  final Map<String, bool> _ipaVisible = {};
  // Track active message for translation (only one at a time usually, or per message)
  // TSX: `activeMessageId === chat.id` implies single active message for translation?
  String? _activeMessageId;

  // Mock score data storage
  // Map<MessageID, ScoreData>
  final Map<String, int> _scores = {}; // Just storing score % for now

  // Mock functions
  void _speakText(String text) {
    // Placeholder for TTS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing audio: "$text" (Mock)')),
    );
  }

  void _handleSimulateTest(String id, String text) {
    // Placeholder for pronunciation test
    // Simulate a random score
    final score = (DateTime.now().millisecond % 40) + 60; // 60-99
    setState(() {
      _scores[id] = score;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recorded: "$text". Score: $score% (Mock)')),
    );
  }

  String _extractTranslate(String? text) {
    if (text == null) return '';
    final RegExp exp = RegExp(r'translate="([^"]*)"');
    final match = exp.firstMatch(text);
    return match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final chats = widget.quiz.chats ?? [];

    if (chats.isEmpty) {
      return Center(
        child: Text(
          'No chat messages available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount:
                chats.length + (widget.quiz.instruction.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.quiz.instruction.isNotEmpty && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                      onWordLongPress: widget.onWordLongPress,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16),
                    ).first, // Wrap? // RichTextParser returns List<Widget> usually inside a Wrap
                  ),
                );
              }

              final chatIndex =
                  widget.quiz.instruction.isNotEmpty ? index - 1 : index;
              final chat = chats[chatIndex];
              return _buildBubble(context, chat, appColors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(
      BuildContext context, ChatMessage chat, AppColorsExtension appColors) {
    // Determine if it's user or bot.
    // TSX: `const isUserMessage = chat.isUser;` (derived from role? usually user role)
    // `course.dart`: role field.
    // Let's assume role 'user' or 'student' is user.
    final isUser = chat.role.toLowerCase() == 'user' ||
        chat.role.toLowerCase() == 'student';

    // Translation logic
    // If we have `chat.question` which effectively acts as content with possible translation embedded
    // or if we have new `chat.content`
    final content =
        chat.content.isNotEmpty ? chat.content : (chat.question ?? '');
    final translateText = _extractTranslate(content).isEmpty
        ? (chat.question != null ? _extractTranslate(chat.question) : '')
        : _extractTranslate(content);
    // Use proper fields if available and regex failed?
    // Actually the parser might be better but let's stick to TSX parity which parsed it manually

    final isActive = _activeMessageId == chat.id;
    final score = _scores[chat.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Role Name / Time
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Text(
                chat.role,
                style: TextStyle(
                  color: appColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (chat.name != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${chat.name})',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 12),
                ),
              ],
              if (chat.time != null) ...[
                const SizedBox(width: 8),
                Text(
                  chat.time!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Bubble Content
          GestureDetector(
            onTap: () {
              setState(() {
                // Toggle active state for translation
                if (_activeMessageId == chat.id) {
                  _activeMessageId = null;
                } else {
                  _activeMessageId = chat.id;
                }
              });
            },
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? appColors.cardBackground : Colors.transparent,
                border: isUser
                    ? Border.all(
                        color: appColors.primary.withValues(alpha: 0.3),
                        width: 2)
                    : Border.all(
                        color: appColors.primary,
                        width: 2,
                        style: BorderStyle.none), // TSX used dashed for bot?
                // Actually Flutter BorderStyle does not support dashed easily without custom painter.
                // Simplified: Solid for everyone, maybe different color/opacity.
                // TSX: User = solid border, Bot = dashed border (transparent bg).
                // Let's use `Border.all`.
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                ),
              ),
              // Use custom paint for dashed border if strictly needed?
              // For now solid is fine.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...RichTextParser.buildRichText(
                        context,
                        content,
                        onWordLongPress: widget.onWordLongPress,
                        style: TextStyle(
                          fontSize: 16,
                          color: appColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      // Inline Translation
                      if (isActive && translateText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: appColors.buttonSecondBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: appColors.border),
                          ),
                          child: Text(
                            translateText,
                            style: TextStyle(
                              color:
                                  appColors.textPrimary, // secondary-foreground
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // IPA
                  if ((_ipaVisible[chat.id] ?? false) && chat.ipa != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        chat.ipa!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: appColors.textSecondary,
                          backgroundColor: appColors.cardBackground, // muted/30
                        ),
                      ),
                    ),

                  // Score Badge
                  if (score != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            '$score%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: score >= 80
                                  ? Colors.green
                                  : (score >= 60 ? Colors.orange : Colors.red),
                            ),
                          ),
                          if (score < 50 && chat.ipa != null)
                            IconButton(
                              icon: const Icon(Icons.help_outline, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _ipaVisible[chat.id] =
                                      !(_ipaVisible[chat.id] ?? false);
                                });
                              },
                            )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 18),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _speakText(content),
                ),
                if (isUser)
                  IconButton(
                    icon: const Icon(Icons.mic,
                        size:
                            18), // StepForward icon in TSX? It was 'test' button.
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _handleSimulateTest(chat.id, content),
                  ),
              ],
            ),
          ),

          // Explanation
          if (score != null && chat.explain != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: appColors.border,
                      style: BorderStyle.none), // dashed in TSX
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichTextParser.buildRichText(
                  context,
                  chat.explain!,
                  style: TextStyle(
                      color: appColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 14),
                ).first, // Wrap
              ),
            ),
        ],
      ),
    );
  }
}
