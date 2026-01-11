import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SentenceTransformation extends StatefulWidget {
  const SentenceTransformation({
    super.key,
    required this.quiz,
    this.onShowExplain,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.sentenceTransformations ?? [];

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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                ],

                // Requirement text (in secondary color)
                if (currentItem.require != null &&
                    currentItem.require!.isNotEmpty) ...[
                  Text(
                    _stripHtml(currentItem.require!),
                    style: TextStyle(
                      fontSize: 16,
                      color: appColors.textSecondary,
                    ),
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
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: RichTextParser.buildRichText(
                      context,
                      currentItem.original ?? '',
                      onWordLongPress: widget.onWordLongPress,
                      style: TextStyle(
                        fontSize: 16,
                        color: appColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Gap-fill Input Area (inline inputs) - uses question field
                _buildGapFillArea(
                    context, currentItem, currentState, appColors),

                // Result Display
                if (currentState.isChecked) ...[
                  const SizedBox(height: 24),
                  _buildResultDisplay(
                      context, currentItem, currentState, appColors),
                ],
              ],
            ),
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            children: [
              if (!currentState.isChecked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Check'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (currentState.isChecked && _currentIndex < items.length - 1)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _goToNext,
                    icon: const Text('Next'),
                    label: const Icon(Icons.chevron_right, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Text(
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
            color: Colors.green.withValues(alpha: 0.1),
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
                          color: Colors.green.withValues(alpha: 0.2),
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
          InkWell(
            onTap: () {
              widget.onShowExplain?.call(item.explain!);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: appColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Explain',
                  style: TextStyle(
                    color: appColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
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
      borderColor = appColors.primary.withValues(alpha: 0.5);
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
