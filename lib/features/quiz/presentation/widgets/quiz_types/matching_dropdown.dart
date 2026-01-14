import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MatchingDropdown extends StatefulWidget {
  const MatchingDropdown({
    super.key,
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
    this.onShowExplain,
    this.onWordLongPress,
    this.onNext,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;

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
    final borderColor = Colors.grey.withOpacity(0.5);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruction
            if (widget.quiz.instruction.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16),
                  child: Text.rich(
                    TextSpan(
                      children: RichTextParser.buildTextSpans(
                        context,
                        widget.quiz.instruction,
                      ),
                    ),
                  ),
                ),
              ),

            // Dashed Border Card
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: borderColor,
                      strokeWidth: 2,
                      gap: 4,
                      borderRadius: 12,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ...matchings.map((matching) {
                          return _buildMatchingRow(
                              context, matching, appColors);
                        }),
                        // Provide space for floating buttons
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildActionButtons(appColors),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    if (_areAllAnswered && !widget.isChecked) {
      return ElevatedButton.icon(
        onPressed: widget.onCheck,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        icon: const Icon(Icons.check, size: 18),
        label: const Text("Check answers",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (widget.isChecked && widget.onNext != null) {
      return ElevatedButton.icon(
        onPressed: widget.onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text("Next question",
            style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMatchingRow(BuildContext context, MatchingItem matching,
      AppColorsExtension appColors) {
    final selectedKey = _selectedAnswers[matching.id] ?? '';
    final correctKey = _getCorrectOptionKey(matching.answer);
    final isCorrect = widget.isChecked && selectedKey == correctKey;
    final isWrong = widget.isChecked && !isCorrect;

    // Determine colors based on state
    Color borderColor;
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    if (widget.isChecked) {
      if (isCorrect) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        iconColor = Colors.green;
      } else {
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        iconColor = Colors.red;
      }
    } else {
      borderColor = selectedKey.isNotEmpty
          ? appColors.primary
          : appColors.border.withOpacity(0.8);
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
          Text.rich(
            TextSpan(
              children: RichTextParser.buildTextSpans(
                context,
                matching.question,
                onWordLongPress: widget.onWordLongPress,
              ),
            ),
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Dropdown Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48, // Slightly Taller for better touch target
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedKey.isNotEmpty ? selectedKey : null,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 300,
                      borderRadius: BorderRadius.circular(8),
                      dropdownColor: Colors.white,
                      hint: Text(
                        'Choose an answer',
                        style: TextStyle(
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      icon: Icon(
                        // Change icon color based on state
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
                              fontWeight: FontWeight
                                  .w600, // Slightly less broad than bold
                              fontSize: 16,
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
                                fontSize: 16,
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

              // Info Icon (if correct and has explanation) - Inline
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
                      size: 24,
                    ),
                    tooltip: 'Show Explanation',
                  ),
                ),
            ],
          ),

          // Correction Display (if wrong) - Below the dropdown
          if (isWrong)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () {
                  if (matching.explain.isNotEmpty) {
                    widget.onShowExplain?.call(matching.explain);
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        matching.answer, // Display correct answer text
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.gap = 5,
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final Path dashedPath = _dashPath(path, width: 8, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + width < metric.length)
            ? width
            : metric.length - distance;
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += width + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
