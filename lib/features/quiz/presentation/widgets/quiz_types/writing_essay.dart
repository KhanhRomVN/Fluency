import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class WritingEssay extends StatefulWidget {
  const WritingEssay({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<WritingEssay> createState() => _WritingEssayState();
}

class _WritingEssayState extends State<WritingEssay> {
  final TextEditingController _controller = TextEditingController();
  int _wordCount = 0;
  bool _submitted = false;
  int? _score;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateWordCount);
    _controller.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _controller.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  void _submit() {
    // Mock submit
    setState(() {
      _submitted = true;
      _score = 90; // Mock
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final minWords = widget.quiz.min ?? 0;
    final isEnoughWords = _wordCount >= minWords;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Display
                  if (widget.quiz.question.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: RichTextParser.buildRichText(
                          context,
                          widget.quiz.question,
                          onWordLongPress: widget.onWordLongPress,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: appColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                  // Expanded Input Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: appColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              enabled: !_submitted,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              style: TextStyle(
                                fontSize: 16,
                                color: appColors.textPrimary,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your essay here...',
                                hintStyle: TextStyle(
                                    color: appColors.textSecondary
                                        .withOpacity(0.7)),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Word Count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Words: $_wordCount${minWords > 0 ? ' / $minWords' : ''}',
                                style: TextStyle(
                                  color: appColors.textSecondary,
                                  fontWeight: (minWords > 0 && !isEnoughWords)
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Spacer for bottom controls
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_submitted && (minWords == 0 || isEnoughWords))
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  )
                else if (_submitted)
                  // Finished State / Next
                  ElevatedButton.icon(
                    onPressed: () {
                      // Finish logic
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
