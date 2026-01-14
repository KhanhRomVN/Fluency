import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SentenceTransformation extends StatefulWidget {
  const SentenceTransformation({
    super.key,
    required this.quiz,
    this.onShowExplain,
    this.onWordLongPress,
    this.onNext,
  });

  final Quiz quiz;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;

  @override
  State<SentenceTransformation> createState() => _SentenceTransformationState();
}

class _SentenceTransformationState extends State<SentenceTransformation> {
  int _currentIndex = 0;

  // Map<ItemID, CardState>
  final Map<String, _CardState> _cardStates = {};

  SentenceTransformationItem? get _currentItem {
    final items = widget.quiz.sentenceTransformations ?? [];
    if (items.isEmpty || _currentIndex >= items.length) return null;
    return items[_currentIndex];
  }

  _CardState get _currentState {
    final item = _currentItem;
    if (item == null) return _CardState();
    return _cardStates[item.id] ?? _CardState();
  }

  void _handleInputChange(String itemId, String gapId, String value) {
    if (_cardStates[itemId]?.isChecked == true) return;

    setState(() {
      final current = _cardStates[itemId] ?? _CardState();
      _cardStates[itemId] = current.copyWith(
        gapInputs: {...current.gapInputs, gapId: value},
      );
    });
  }

  void _checkAnswer() {
    final item = _currentItem;
    if (item == null) return;

    final inputs = _currentState.gapInputs;

    // Build the user's sentence by replacing gaps with inputs
    String questionText = item.question ?? '';
    String userSentence = _buildUserSentence(questionText, inputs);
    final normalizedUser = _stripHtml(userSentence)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final isCorrect = item.answer.any((ans) {
      final normalizedAns =
          _stripHtml(ans).toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      return normalizedAns == normalizedUser;
    });

    setState(() {
      _cardStates[item.id] = _currentState.copyWith(
        isCorrect: isCorrect,
        isChecked: true,
      );
    });
  }

  String _buildUserSentence(String template, Map<String, String> inputs) {
    // Replace </gap> or </gap id='xxx'> with corresponding input values
    int gapCount = 0;
    return template.replaceAllMapped(
      RegExp(r'</gap[^>]*>'),
      (match) {
        gapCount++;
        final gapId = _extractGapId(match.group(0) ?? '', gapCount);
        return inputs[gapId] ?? '';
      },
    );
  }

  String _extractGapId(String gapTag, int fallbackIndex) {
    // Try to extract id from gap tag like </gap id='gap1'> or </gap id="gap1">
    // Using simple string manipulation instead of complex regex
    final idIndex = gapTag.indexOf('id=');
    if (idIndex == -1) return 'gap-$fallbackIndex';

    final afterId = gapTag.substring(idIndex + 3);
    if (afterId.isEmpty) return 'gap-$fallbackIndex';

    // Get the quote character (either ' or ")
    final quoteChar = afterId[0];
    if (quoteChar != "'" && quoteChar != '"') return 'gap-$fallbackIndex';

    final endQuote = afterId.indexOf(quoteChar, 1);
    if (endQuote == -1) return 'gap-$fallbackIndex';

    return afterId.substring(1, endQuote);
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _goToNext() {
    final items = widget.quiz.sentenceTransformations ?? [];
    if (_currentIndex < items.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.onNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.sentenceTransformations ?? [];
    final borderColor = Colors.grey.withOpacity(0.5);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No sentence transformation items.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentItem = _currentItem!;
    final currentState = _currentState;

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
                        onWordLongPress: widget.onWordLongPress,
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
                        // Requirement text
                        if (currentItem.require != null &&
                            currentItem.require!.isNotEmpty) ...[
                          DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 16,
                              color: appColors.textSecondary,
                            ),
                            child: Text.rich(TextSpan(
                                children: RichTextParser.buildTextSpans(
                                    context, currentItem.require!,
                                    onWordLongPress: widget.onWordLongPress))),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Original Sentence (bordered container)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: appColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 16,
                              color: appColors.textPrimary,
                              height: 1.5,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: RichTextParser.buildTextSpans(
                                  context,
                                  currentItem.original ?? '',
                                  onWordLongPress: widget.onWordLongPress,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Gap-fill Input Area
                        _buildGapFillArea(
                            context, currentItem, currentState, appColors),

                        // Result Display
                        if (currentState.isChecked) ...[
                          const SizedBox(height: 24),
                          _buildResultDisplay(
                              context, currentItem, currentState, appColors),
                        ],

                        // Spacing for floating buttons
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
          bottom: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!currentState.isChecked && _isInputComplete(currentItem))
                ElevatedButton.icon(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Check",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              if (currentState.isChecked)
                ElevatedButton.icon(
                  onPressed: _goToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                      _currentIndex < items.length - 1
                          ? "Next question"
                          : "Finish",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isInputComplete(SentenceTransformationItem item) {
    final question = item.question ?? '';
    final requiredIds = _getRequiredGapIds(question);
    final inputs = _currentState.gapInputs;

    return requiredIds.every((id) => (inputs[id] ?? '').trim().isNotEmpty);
  }

  Set<String> _getRequiredGapIds(String question) {
    final matches = RegExp(r'</gap[^>]*>').allMatches(question);
    int index = 0;
    return matches.map((m) {
      index++;
      return _extractGapId(m.group(0) ?? '', index);
    }).toSet();
  }

  Widget _buildGapFillArea(
    BuildContext context,
    SentenceTransformationItem item,
    _CardState state,
    AppColorsExtension appColors,
  ) {
    // Use the question field which contains </gap> tags
    final questionText = item.question ?? '';

    if (questionText.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split by </gap...> tags and create inline widgets
    final gapPattern = RegExp(r'</gap[^>]*>');
    final parts = questionText.split(gapPattern);
    final matches = gapPattern.allMatches(questionText).toList();

    List<InlineSpan> spans = [];
    int gapIndex = 0;

    for (int i = 0; i < parts.length; i++) {
      // Add text part (strip HTML tags)
      final textPart = _stripHtml(parts[i]).trim();
      if (textPart.isNotEmpty) {
        spans.add(TextSpan(
          text: '$textPart ',
          style: TextStyle(
            fontSize: 16,
            color: appColors.textPrimary,
          ),
        ));
      }

      // Add gap input if there's a match after this part
      if (i < matches.length) {
        final match = matches[i];
        gapIndex++;
        final gapId = _extractGapId(match.group(0) ?? '', gapIndex);

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _GapInputField(
            gapId: gapId,
            value: state.gapInputs[gapId] ?? '',
            isChecked: state.isChecked,
            isCorrect: state.isCorrect,
            onChanged: (value) => _handleInputChange(item.id, gapId, value),
            appColors: appColors,
          ),
        ));

        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 16,
        color: appColors.textPrimary,
        height: 1.8,
      ),
    );
  }

  Widget _buildResultDisplay(
    BuildContext context,
    SentenceTransformationItem item,
    _CardState state,
    AppColorsExtension appColors,
  ) {
    if (state.isCorrect == true) {
      return Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text(
            'Correct!',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Correct answer container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Correct answer:',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...item.answer.asMap().entries.map((entry) {
                final index = entry.key;
                final answer = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stripHtml(answer),
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Explain button
        if (item.explain != null && item.explain!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  widget.onShowExplain?.call(item.explain!);
                },
                icon: Icon(Icons.info_outline,
                    size: 16, color: appColors.primary),
                label: Text(
                  'Explain Answer',
                  style: TextStyle(
                    color: appColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ))
        ],
      ],
    );
  }
}

class _GapInputField extends StatelessWidget {
  const _GapInputField({
    required this.gapId,
    required this.value,
    required this.isChecked,
    required this.isCorrect,
    required this.onChanged,
    required this.appColors,
  });

  final String gapId;
  final String value;
  final bool isChecked;
  final bool? isCorrect;
  final ValueChanged<String> onChanged;
  final AppColorsExtension appColors;

  @override
  Widget build(BuildContext context) {
    // Calculate width based on content
    const minWidth = 60.0;
    const charWidth = 10.0;
    final width = (value.length * charWidth).clamp(minWidth, 200.0);

    Color borderColor;
    Color textColor;

    if (isChecked) {
      if (isCorrect == true) {
        borderColor = Colors.green;
        textColor = Colors.green;
      } else {
        borderColor = Colors.red;
        textColor = Colors.red;
      }
    } else {
      borderColor = appColors.primary.withOpacity(0.5);
      textColor = appColors.textPrimary;
    }

    return SizedBox(
      width: width,
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.collapsed(offset: value.length),
        enabled: !isChecked,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: appColors.primary, width: 2),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
        ),
      ),
    );
  }
}

class _CardState {
  final Map<String, String> gapInputs;
  final bool? isCorrect;
  final bool isChecked;

  _CardState({
    this.gapInputs = const {},
    this.isCorrect,
    this.isChecked = false,
  });

  _CardState copyWith({
    Map<String, String>? gapInputs,
    bool? isCorrect,
    bool? isChecked,
  }) {
    return _CardState(
      gapInputs: gapInputs ?? this.gapInputs,
      isCorrect: isCorrect ?? this.isCorrect,
      isChecked: isChecked ?? this.isChecked,
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
