import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class MatchingDropdown extends StatefulWidget {
  const MatchingDropdown({
    super.key,
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
    this.onShowExplain,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;

  @override
  State<MatchingDropdown> createState() => _MatchingDropdownState();
}

class _MatchingDropdownState extends State<MatchingDropdown> {
  Map<String, String> _selectedAnswers = {};

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
    _selectedAnswers = {};
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
    return matchings.every((m) =>
        _selectedAnswers[m.id] != null && _selectedAnswers[m.id]!.isNotEmpty);
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: RichTextParser.buildRichText(
                    context,
                    widget.quiz.instruction,
                    onWordLongPress: widget.onWordLongPress,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16),
                  ),
                ),
                Divider(height: 32, color: appColors.border),
              ],

              // Matchings List
              ...matchings.map((matching) {
                return _buildMatchingRow(context, matching, appColors);
              }),
              if (widget.quiz.audio != null && widget.quiz.audio!.isNotEmpty)
                const SizedBox(height: 120),
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
                top: BorderSide(
                  color: appColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Check answers',
                  style: TextStyle(
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

  Widget _buildMatchingRow(BuildContext context, MatchingItem matching,
      AppColorsExtension appColors) {
    final selectedKey = _selectedAnswers[matching.id] ?? '';
    final correctKey = _getCorrectOptionKey(matching.answer);
    final isCorrect = widget.isChecked && selectedKey == correctKey;
    final isWrong = widget.isChecked && !isCorrect;

    // Find the text for the selected option to display (mimicking the "Visual Display Layer")
    final selectedOption = _options.firstWhere(
      (o) => o.key == selectedKey,
      orElse: () => const MapEntry('', 'Choose an answer'),
    );

    // Determine colors based on state
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    if (widget.isChecked) {
      if (isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        iconColor = Colors.green;
      } else {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        iconColor = Colors.red;
      }
    } else {
      borderColor = selectedKey.isNotEmpty
          ? appColors.primary
          : appColors.border.withValues(alpha: 0.8); // Darker border
      backgroundColor = appColors.background;
      textColor = selectedKey.isNotEmpty
          ? appColors.textPrimary
          : appColors.textSecondary;
      iconColor = appColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            children: RichTextParser.buildRichText(
              context,
              matching.question,
              onWordLongPress: widget.onWordLongPress,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Dropdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42, // Reduced height
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8), // Reduced radius
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedKey.isNotEmpty ? selectedKey : null,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 300,
                      borderRadius: BorderRadius.circular(8),
                      dropdownColor: appColors.cardBackground,
                      hint: Text(
                        'Choose an answer',
                        style: TextStyle(
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16, // Increased font size
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: iconColor,
                        size: 24,
                      ),
                      onChanged: widget.isChecked
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedAnswers[matching.id] = value;
                                });
                              }
                            },
                      items: _options.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt.key,
                          child: Text(
                            opt.value,
                            style: TextStyle(
                              color: appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // Increased font size
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return _options.map((opt) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              opt.value,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Increased font size
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),

              // Info Icon (if correct and has explanation)
              if (widget.isChecked && isCorrect && matching.explain.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: () {
                      widget.onShowExplain?.call(matching.explain);
                    },
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: appColors.primary,
                    ),
                    tooltip: 'Show Explanation',
                  ),
                ),
            ],
          ),

          // Correction Display (if wrong)
          if (isWrong)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () {
                  if (matching.explain.isNotEmpty) {
                    widget.onShowExplain?.call(matching.explain);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        matching.answer, // Displaying correct answer text
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
