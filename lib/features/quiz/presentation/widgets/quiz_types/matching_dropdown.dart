import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';

class MatchingDropdown extends StatefulWidget {
  const MatchingDropdown({
    super.key,
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;

  @override
  State<MatchingDropdown> createState() => _MatchingDropdownState();
}

class _MatchingDropdownState extends State<MatchingDropdown> {
  Map<String, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _resetAnswers();
  }

  @override
  void didUpdateWidget(MatchingDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz.id != widget.quiz.id) {
      _resetAnswers();
    }
  }

  void _resetAnswers() {
    selectedAnswers = {};
  }

  List<MapEntry<String, String>> get _options {
    if (widget.quiz.options == null) return [];

    return widget.quiz.options!
        .asMap()
        .entries
        .map((e) => MapEntry(
              String.fromCharCode(65 + e.key), // A, B, C...
              e.value,
            ))
        .toList();
  }

  String? _getCorrectOptionKey(String correctAnswerText) {
    final normalized = correctAnswerText.trim().toLowerCase();
    final exact = _options.firstWhere(
      (o) => o.value.trim().toLowerCase() == normalized,
      orElse: () => const MapEntry('', ''),
    );
    return exact.key.isNotEmpty ? exact.key : null;
  }

  bool get _areAllAnswered {
    final matchings = widget.quiz.matchings ?? [];
    if (matchings.isEmpty) return true;
    return matchings.every((m) => selectedAnswers[m.id] != null);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final matchings = widget.quiz.matchings ?? [];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instruction
              if (widget.quiz.instruction.isNotEmpty) ...[
                Text(
                  widget.quiz.instruction,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: appColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
              ],

              // Matchings List
              ...matchings.map((matching) {
                final selectedKey = selectedAnswers[matching.id] ?? '';
                final correctKey = _getCorrectOptionKey(matching.answer);
                final isCorrect = widget.isChecked && selectedKey == correctKey;
                final isWrong = widget.isChecked && !isCorrect;

                final selectedOption = _options.firstWhere(
                  (o) => o.key == selectedKey,
                  orElse: () => const MapEntry('', 'Choose an answer'),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Text(
                        matching.question,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: appColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.isChecked
                                ? (isCorrect ? Colors.green : Colors.red)
                                : (selectedKey.isNotEmpty
                                    ? appColors.primary
                                    : appColors.border),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: widget.isChecked
                              ? (isCorrect
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1))
                              : appColors.background,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedKey.isNotEmpty ? selectedKey : null,
                            isExpanded: true,
                            hint: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Choose an answer',
                                style:
                                    TextStyle(color: appColors.textSecondary),
                              ),
                            ),
                            items: _options.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt.key,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    opt.value,
                                    style: TextStyle(
                                      color: appColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: widget.isChecked
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedAnswers[matching.id] = value;
                                      });
                                    }
                                  },
                            selectedItemBuilder: (context) {
                              return _options.map((opt) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  child: Text(
                                    opt.value,
                                    style: TextStyle(
                                      color: widget.isChecked
                                          ? (isCorrect
                                              ? Colors.green
                                              : Colors.red)
                                          : appColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),

                      // Correction Display (when wrong)
                      if (isWrong) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                matching.answer,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Check Button
        if (_areAllAnswered && !widget.isChecked)
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
                  'Check answers',
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
