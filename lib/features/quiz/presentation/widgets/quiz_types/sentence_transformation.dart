import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SentenceTransformation extends StatefulWidget {
  const SentenceTransformation({
    super.key,
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;

  @override
  State<SentenceTransformation> createState() => _SentenceTransformationState();
}

class _SentenceTransformationState extends State<SentenceTransformation> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canCheck => _controller.text.trim().isNotEmpty;

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
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                    ),
                  ),
                ),
                Divider(height: 32, color: appColors.border),
              ],

              // Original Sentence
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Sentence:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.quiz.question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transformation Input
              Text(
                'Transform the sentence:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 3,
                enabled: !widget.isChecked,
                decoration: InputDecoration(
                  hintText: 'Type your transformed sentence here...',
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
                    borderSide: BorderSide(color: appColors.primary, width: 2),
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: appColors.textPrimary,
                    ),
                onChanged: (_) => setState(() {}),
              ),

              // Example Answer (shown after check)
              if (widget.isChecked && widget.quiz.example != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Example Answer:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.quiz.example!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: appColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.quiz.audio != null && widget.quiz.audio!.isNotEmpty)
                const SizedBox(height: 120),
            ],
          ),
        ),

        // Check Button
        if (_canCheck && !widget.isChecked)
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
                onPressed: widget.onCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
