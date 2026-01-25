import 'dart:math';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class ChattingSpeech extends StatefulWidget {
  const ChattingSpeech({
    required this.quiz,
    super.key,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<ChattingSpeech> createState() => _ChattingSpeechState();
}

class _ScoreData {
  _ScoreData({
    required this.score,
    required this.transcript,
    required this.feedback,
  });
  final int score;
  final String transcript;
  final List<_WordFeedback> feedback;
}

class _WordFeedback {
  // 'correct', 'incorrect', 'missing', 'extra'

  _WordFeedback(this.word, this.status);
  final String word;
  final String status;
}

class _ChattingSpeechState extends State<ChattingSpeech> {
  // Map<MessageID, isIpaVisible>
  final Map<String, bool> _ipaVisible = {};
  // Track active message for translation
  String? _activeMessageId;

  // Mock score data storage
  final Map<String, _ScoreData> _scores = {};

  // Mock functions
  void _speakText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing audio: "$text" (Mock)'),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _handleSimulateTest(String id, String targetText) {
    // Simulate API response
    final random = Random();
    final score = 40 + random.nextInt(60); // 40-99

    // Mock feedback generation based on target text
    final words = targetText.split(' ');
    final feedback = words.map((word) {
      final r = random.nextDouble();
      if (r > 0.8) return _WordFeedback(word, 'incorrect');
      if (r > 0.9) return _WordFeedback(word, 'missing');
      return _WordFeedback(word, 'correct');
    }).toList();

    // Mock transcript (slightly different if low score)
    var transcript = targetText;
    if (score < 80) {
      transcript = 'I think I said... $targetText';
    }

    setState(() {
      _scores[id] = _ScoreData(
        score: score,
        transcript: transcript,
        feedback: feedback,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recorded. Score: $score%'),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  String _extractTranslate(String? text) {
    if (text == null) return '';
    final exp = RegExp('translate="([^"]*)"');
    final match = exp.firstMatch(text);
    return match?.group(1) ?? '';
  }

  // Remove translation tags for clean text display
  String _cleanText(String? text) {
    if (text == null) return '';
    return text.replaceAll(RegExp('translate="[^"]*"'), '').trim();
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
                    child: Opacity(
                      opacity: 0.8,
                      child: RichTextParser.buildRichText(
                        context,
                        widget.quiz.instruction,
                        onWordLongPress: widget.onWordLongPress,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ).first,
                    ),
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
    BuildContext context,
    ChatMessage chat,
    AppColorsExtension appColors,
  ) {
    final isUser = chat.role.toLowerCase() == 'user' ||
        chat.role.toLowerCase() == 'student';

    final textContent =
        chat.content.isNotEmpty ? chat.content : (chat.question ?? '');
    final translateText = _extractTranslate(textContent).isEmpty
        ? (chat.question != null ? _extractTranslate(chat.question) : '')
        : _extractTranslate(textContent);

    // Clean text for speaking and feedback matching
    final targetText = _cleanText(textContent);

    final isActive = _activeMessageId == chat.id;
    final scoreData = _scores[chat.id];
    final isIpaShown = _ipaVisible[chat.id] ?? false;

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
                  fontWeight: FontWeight.w600, // font-semibold
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
                const SizedBox(width: 4),
                Text(
                  chat.time!,
                  style: TextStyle(
                    color: appColors.textSecondary, // muted-foreground
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
                if (_activeMessageId == chat.id) {
                  _activeMessageId = null;
                } else {
                  _activeMessageId = chat.id;
                }
              });
            },
            child: CustomPaint(
              painter: !isUser
                  ? _DashedBorderPainter(
                      color: appColors.primary,
                      strokeWidth: 2,
                      radius: 12,
                      bottomLeft: false, // rounded-bl-none
                    )
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUser ? appColors.cardBackground : Colors.transparent,
                  border: isUser
                      ? Border.all(
                          color: appColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : null, // Handled by painter
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft:
                        !isUser ? Radius.zero : const Radius.circular(12),
                    bottomRight:
                        isUser ? Radius.zero : const Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Content with Feedback or Standard RichText
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (scoreData != null)
                          _buildFeedbackText(scoreData.feedback, appColors)
                        else
                          // Only add interactive styling usually, but strict parity means simple text mostly
                          // React: select-text cursor-pointer hover:bg-primary/5
                          RichTextParser.buildRichText(
                            context,
                            textContent, // Contains <translate> tags possibly, parser handles?
                            // If parser handles tags by hiding them, great. If not we might need cleaned text.
                            // Assuming parser handles it as existing implementation was using it.
                            onWordLongPress: widget.onWordLongPress,
                            style: TextStyle(
                              fontSize: 14, // text-sm
                              color: appColors.textPrimary,
                              height: 1.5, // leading-relaxed
                            ),
                          ).first,

                        // Inline Translation
                        if (isActive && translateText.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: appColors.buttonSecondBg, // secondary
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: appColors.border),
                            ),
                            child: Text(
                              translateText,
                              style: TextStyle(
                                color: appColors
                                    .textPrimary, // secondary-foreground
                                fontSize: 12, // text-xs
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // IPA Display
                    if (isIpaShown && chat.ipa != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: appColors.cardBackground
                              .withValues(alpha: 0.5), // muted/30
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          chat.ipa!,
                          style: TextStyle(
                            fontSize: 12, // text-xs
                            fontFamily: 'monospace',
                            color: appColors.textSecondary,
                          ),
                        ),
                      ),

                    // Score Badge & IPA Toggle
                    if (scoreData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${scoreData.score}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getScoreColor(scoreData.score),
                              ),
                            ),
                            if (scoreData.score < 50 && chat.ipa != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _ipaVisible[chat.id] = !isIpaShown;
                                  });
                                },
                                child: Icon(
                                  Icons.help_outline,
                                  size: 14,
                                  color: appColors
                                      .textSecondary, // muted-foreground
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // User Transcript
          if (scoreData != null && isUser)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    appColors.cardBackground.withValues(alpha: 0.3), // muted/30
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: appColors.border,
                  style: BorderStyle.none, // Need dashed?
                  // Flutter BorderStyle.none means no border.
                  // Use CustomPaint again if we really want dashed.
                  // For simplicity in minor UI elements, solid with low opacity or omit dash is often acceptable,
                  // but for strict parity let's try to mimic or use the painter.
                  // The parser for the bubble used the painter. Let's reuse or just use solid for now as container is small.
                ),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: appColors.border,
                  radius: 4,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '"${scoreData.transcript}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(top: 8), // gap-2 -> 8px
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.volume_up,
                  onTap: () => _speakText(targetText),
                  appColors: appColors,
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.mic, // StepForward in TSX visualized as 'Test'
                    onTap: () => _handleSimulateTest(chat.id, targetText),
                    appColors: appColors,
                  ),
                ],
              ],
            ),
          ),

          // Explanation
          if (scoreData != null && chat.explain != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  // border: border-dashed border-border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: appColors.border,
                    radius: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: RichTextParser.buildRichText(
                      context,
                      chat.explain!,
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ).first,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          // hover:bg-muted handled by InkWell usually, but simple container here
        ),
        child: Icon(
          icon,
          size: 14,
          color: appColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFeedbackText(
    List<_WordFeedback> feedback,
    AppColorsExtension appColors,
  ) {
    return RichText(
      text: TextSpan(
        children: feedback.map((item) {
          if (item.status == 'extra') return const TextSpan();

          Color? color;
          if (item.status == 'correct') {
            color = appColors.primary;
          } else if (item.status == 'incorrect' || item.status == 'missing') {
            color = Colors.red;
          }

          return TextSpan(
            text: '${item.word} ', // Add space
            style: TextStyle(
              fontSize: 14,
              color: color ?? appColors.textPrimary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange; // yellow-500
    return Colors.red;
  }
}

class _DashedBorderPainter extends CustomPainter {
  // If false, corner is sharp (Radius.zero)

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.radius = 0,
    this.bottomLeft = true,
  });
  final Color color;
  final double strokeWidth;
  final double radius;
  final bool bottomLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(
        Offset(size.width - radius, size.height),
        radius: Radius.circular(radius),
      );

    // Bottom Left
    if (bottomLeft) {
      path
        ..lineTo(radius, size.height)
        ..arcToPoint(
          Offset(0, size.height - radius),
          radius: Radius.circular(radius),
        );
    } else {
      path.lineTo(0, size.height);
      // Sharp corner
    }

    path
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashArray = <double>[5, 5]; // 5px dash, 5px space
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = dashArray[draw ? 0 : 1];
        if (draw) {
          final extractPath = metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
