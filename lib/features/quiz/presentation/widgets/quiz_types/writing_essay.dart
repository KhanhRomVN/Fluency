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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.quiz.instruction.isNotEmpty) ...[
          RichTextParser.buildRichText(
            context,
            widget.quiz.instruction,
            onWordLongPress: widget.onWordLongPress,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          ).first,
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.quiz.question.isNotEmpty)
                Text(
                  widget.quiz.question,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                enabled: !_submitted,
                maxLines: 10,
                style: TextStyle(fontSize: 16, color: appColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type your essay here...',
                  filled: true,
                  fillColor: appColors.inputBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Words: $_wordCount${minWords > 0 ? ' / $minWords' : ''}',
                    style: TextStyle(
                      color: (minWords > 0 && !isEnoughWords)
                          ? Colors.red
                          : appColors.textSecondary,
                      fontWeight: (minWords > 0 && !isEnoughWords)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_submitted)
                ElevatedButton(
                  onPressed: (minWords > 0 && !isEnoughWords) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              else ...[
                if (_score != null)
                  Text(
                    'Score: $_score%',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Submitted successfully!',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
