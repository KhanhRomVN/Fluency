import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({
    super.key,
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder> {
  List<String> _selectedWords = [];
  final List<String> _availableWords = [
    'The',
    'quick',
    'brown',
    'fox',
    'jumps',
    'over',
    'lazy',
    'dog',
  ];

  void _addWord(String word) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.add(word);
      });
    }
  }

  void _removeWord(int index) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.removeAt(index);
      });
    }
  }

  void _clearAll() {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.clear();
      });
    }
  }

  bool get _canCheck => _selectedWords.isNotEmpty;

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

              // Selected Words Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: appColors.border, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: appColors.cardBackground,
                ),
                child: _selectedWords.isEmpty
                    ? Text(
                        'Tap words below to build your sentence',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: appColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedWords.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _removeWord(entry.key),
                            child: Chip(
                              label: Text(entry.value),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeWord(entry.key),
                            ),
                          );
                        }).toList(),
                      ),
              ),

              if (_selectedWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                  ),
                ),

              const SizedBox(height: 24),

              // Available Words
              Text(
                'Available Words:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableWords.map((word) {
                  return ActionChip(
                    label: Text(word),
                    onPressed: () => _addWord(word),
                    backgroundColor: appColors.cardBackground,
                  );
                }).toList(),
              ),
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
