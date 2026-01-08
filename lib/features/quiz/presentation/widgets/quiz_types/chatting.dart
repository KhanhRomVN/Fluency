import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class Chatting extends StatelessWidget {
  const Chatting({
    super.key,
    required this.quiz,
  });

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final chats = quiz.chats ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Instruction
        if (quiz.instruction.isNotEmpty) ...[
          DefaultTextStyle(
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              children: RichTextParser.buildRichText(
                context,
                quiz.instruction,
              ),
            ),
          ),
          Divider(height: 32, color: appColors.border),
        ],

        // Chat Messages
        ...chats.map((chat) {
          final isUser = chat.role == 'user';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isUser ? appColors.primary : appColors.cardBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      chat.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                isUser ? Colors.white : appColors.textPrimary,
                            height: 1.5,
                            fontSize: 16,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
