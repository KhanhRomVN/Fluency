import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class Writing extends StatefulWidget {
  const Writing({
    required this.quiz,
    super.key,
  });

  final Quiz quiz;

  @override
  State<Writing> createState() => _WritingState();
}

class _WritingState extends State<Writing> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitted = false;

  int get _wordCount {
    final text = _controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int get _minWords => widget.quiz.min ?? 150;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instruction
              if (widget.quiz.instruction.isNotEmpty) ...[
                DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16),
                  child: Wrap(
                    children: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                    ),
                  ),
                ),
                Divider(height: 32, color: appColors.border),
              ],

              // Word Count Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Minimum words: $_minWords',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.textSecondary,
                        ),
                  ),
                  Text(
                    'Word count: $_wordCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _wordCount >= _minWords
                              ? Colors.green
                              : appColors.textSecondary,
                          fontWeight: _wordCount >= _minWords
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input Area
              if (_isSubmitted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appColors.border),
                  ),
                  child: Text(
                    _controller.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appColors.textPrimary,
                          height: 1.6,
                        ),
                  ),
                )
              else
                TextField(
                  controller: _controller,
                  maxLines: 12,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    hintStyle: TextStyle(color: appColors.textSecondary),
                    filled: true,
                    fillColor: appColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: appColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: appColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: appColors.primary, width: 2),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appColors.textPrimary,
                      ),
                ),

              // Sample Answer (shown after submit)
              if (_isSubmitted && widget.quiz.example != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Sample Answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appColors.border),
                  ),
                  child: Text(
                    widget.quiz.example!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appColors.textPrimary,
                          height: 1.6,
                          fontSize: 16,
                        ),
                  ),
                ),
              ],
              if (widget.quiz.audio != null && widget.quiz.audio!.isNotEmpty)
                const SizedBox(height: 120),
            ],
          ),
        ),

        // Submit Button
        if (!_isSubmitted && _wordCount >= _minWords)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.background,
              border: Border(
                top: BorderSide(color: appColors.border),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
