import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SentenceTransformation extends StatefulWidget {
  const SentenceTransformation({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    super.key,
    this.onShowExplain,
    this.onWordLongPress,
    this.onNext,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;

  @override
  State<SentenceTransformation> createState() => _SentenceTransformationState();
}

class _SentenceTransformationState extends State<SentenceTransformation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Map<ItemID, CardState>
  final Map<String, _CardState> _cardStates = {};

  // Animation variables
  late AnimationController _animController;
  double _dragOffset = 0;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(() {
      setState(() {
        if (_slideAnimation != null) {
          _dragOffset = _slideAnimation!.value;
        }
      });
    });

    // Load saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      setState(() {
        _currentIndex = progress.data?['currentIndex'] as int? ?? 0;

        final savedStates =
            progress.data?['cardStates'] as Map<String, dynamic>?;
        if (savedStates != null) {
          savedStates.forEach((key, value) {
            final data = value as Map<String, dynamic>;
            _cardStates[key] = _CardState(
              isChecked: data['isChecked'] as bool? ?? false,
              isCorrect: data['isCorrect'] as bool?,
              gapInputs: (data['gapInputs'] as Map<String, dynamic>?)?.map(
                    (k, v) => MapEntry(k, v as String),
                  ) ??
                  {},
            );
          });
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Serialize states
    final statesMap = _cardStates.map((key, value) {
      return MapEntry(key, {
        'isChecked': value.isChecked,
        'isCorrect': value.isCorrect,
        'gapInputs': value.gapInputs,
      });
    });

    final totalItems = widget.quiz.sentenceTransformations?.length ?? 0;
    final completedItems = _cardStates.values.where((s) => s.isChecked).length;
    final correctItems =
        _cardStates.values.where((s) => s.isCorrect ?? false).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: widget.quiz.type ?? 'sentence-transformation',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'currentIndex': _currentIndex,
        'cardStates': statesMap,
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = screenWidth * 0.25;

    // Check if we should change question
    var shouldChange = false;
    var direction = 0; // -1: Next (Swipe Left), 1: Prev (Swipe Right)

    if (velocity < -1000 || _dragOffset < -threshold) {
      if (widget.quiz.sentenceTransformations != null &&
          _currentIndex < widget.quiz.sentenceTransformations!.length - 1) {
        shouldChange = true;
        direction = -1;
      }
    } else if (velocity > 1000 || _dragOffset > threshold) {
      if (_currentIndex > 0) {
        shouldChange = true;
        direction = 1;
      }
    }

    if (shouldChange) {
      final endX = direction == -1 ? -screenWidth : screenWidth;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: endX).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );

      _animController.forward(from: 0).then((_) {
        setState(() {
          if (direction == -1) {
            _currentIndex++;
          } else {
            _currentIndex--;
          }
          _dragOffset = direction == -1 ? screenWidth : -screenWidth;
          _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut),
          );
          _animController.forward(from: 0);
          _saveProgress();
        });
      });
    } else {
      _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward(from: 0);
    }
  }

  void _animateToNextQuestion() {
    final screenWidth = MediaQuery.of(context).size.width;
    _slideAnimation = Tween<double>(begin: 0, end: -screenWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex++;
        _dragOffset = screenWidth;
        _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
        _animController.forward(from: 0);
        _saveProgress();
      });
    });
  }

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
    if (_cardStates[itemId]?.isChecked ?? false) return;

    setState(() {
      final current = _cardStates[itemId] ?? _CardState();
      _cardStates[itemId] = current.copyWith(
        gapInputs: {...current.gapInputs, gapId: value},
      );
      _saveProgress();
    });
  }

  void _checkAnswer() {
    final item = _currentItem;
    if (item == null) return;

    final inputs = _currentState.gapInputs;

    // Build the user's sentence by replacing gaps with inputs
    final questionText = item.question ?? '';
    final userSentence = _buildUserSentence(questionText, inputs);
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
      _saveProgress();
    });
  }

  String _buildUserSentence(String template, Map<String, String> inputs) {
    // Replace </gap> or </gap id='xxx'> with corresponding input values
    var gapCount = 0;
    return template.replaceAllMapped(
      RegExp('</gap[^>]*>'),
      (match) {
        gapCount++;
        final gapId = _extractGapId(match.group(0) ?? '', gapCount);
        return inputs[gapId] ?? '';
      },
    );
  }

  String _extractGapId(String gapTag, int fallbackIndex) {
    // Try to extract id from gap tag like </gap id='gap1'> or </gap id="gap1">
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
    return html.replaceAll(RegExp('<[^>]*>'), '');
  }

  void _goToNext() {
    final items = widget.quiz.sentenceTransformations ?? [];
    if (_currentIndex < items.length - 1) {
      _animateToNextQuestion();
    } else {
      widget.onNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.sentenceTransformations ?? [];
    final borderColor = Colors.grey.withValues(alpha: 0.5);

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
                child: GestureDetector(
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final rotateAngle = _dragOffset * 0.001;
                      final opacity =
                          (1 - (_dragOffset.abs() / 500)).clamp(0.5, 1.0);
                      return Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: Transform.rotate(
                          angle: rotateAngle,
                          child: Opacity(opacity: opacity, child: child),
                        ),
                      );
                    },
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
                        child: Column(
                          children: [
                            // Card Header: Counter & Progress
                            _buildCardHeader(
                              context,
                              appColors,
                              items,
                            ),
                            const Divider(height: 1),

                            Expanded(
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
                                      child: Text.rich(
                                        TextSpan(
                                          children:
                                              RichTextParser.buildTextSpans(
                                            context,
                                            currentItem.require!,
                                            onWordLongPress:
                                                widget.onWordLongPress,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Original Sentence (bordered container)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: appColors.border),
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
                                          children:
                                              RichTextParser.buildTextSpans(
                                            context,
                                            currentItem.original ?? '',
                                            onWordLongPress:
                                                widget.onWordLongPress,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Gap-fill Input Area
                                  _buildGapFillArea(
                                    context,
                                    currentItem,
                                    currentState,
                                    appColors,
                                  ),

                                  // Result Display
                                  if (currentState.isChecked) ...[
                                    const SizedBox(height: 24),
                                    _buildResultDisplay(
                                      context,
                                      currentItem,
                                      currentState,
                                      appColors,
                                    ),
                                  ],

                                  // Spacing for floating buttons
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 28,
          right: 36,
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
                      horizontal: 20,
                      vertical: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(
                    'Check',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if (currentState.isChecked)
                ElevatedButton.icon(
                  onPressed: _goToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'Next question',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    final matches = RegExp('</gap[^>]*>').allMatches(question);
    var index = 0;
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
    final gapPattern = RegExp('</gap[^>]*>');
    final parts = questionText.split(gapPattern);
    final matches = gapPattern.allMatches(questionText).toList();

    final spans = <InlineSpan>[];
    var gapIndex = 0;

    for (var i = 0; i < parts.length; i++) {
      // Add text part (strip HTML tags)
      final textPart = _stripHtml(parts[i]).trim();
      if (textPart.isNotEmpty) {
        spans.add(
          TextSpan(
            text: '$textPart ',
            style: TextStyle(
              fontSize: 16,
              color: appColors.textPrimary,
            ),
          ),
        );
      }

      // Add gap input if there's a match after this part
      if (i < matches.length) {
        final match = matches[i];
        gapIndex++;
        final gapId = _extractGapId(match.group(0) ?? '', gapIndex);

        spans
          ..add(
            WidgetSpan(
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
            ),
          )
          ..add(const TextSpan(text: ' '));
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
    if (state.isCorrect ?? false) {
      return const Row(
        children: [
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                widget.onShowExplain?.call(item.explain!);
              },
              icon: Icon(
                Icons.info_outline,
                size: 16,
                color: appColors.primary,
              ),
              label: Text(
                'Explain Answer',
                style: TextStyle(
                  color: appColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<SentenceTransformationItem> questions,
  ) {
    // Count how many items are checked
    final completedCount = _cardStates.values.where((v) => v.isChecked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Counter
          Text(
            '${_currentIndex + 1} / ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
            ),
          ),

          // Segmented Progress Circle
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(32, 32),
                  painter: _SegmentedProgressPainter(
                    totalSegments: questions.length,
                    segmentStates: List.generate(questions.length, (index) {
                      final qId = questions[index].id;
                      final state = _cardStates[qId];
                      if (state == null || !state.isChecked)
                        return 0; // Not done
                      return (state.isCorrect ?? false)
                          ? 1
                          : 2; // 1: Correct, 2: Wrong
                    }),
                    primaryColor: appColors.primary,
                    errorColor: Colors.red,
                    emptyColor: appColors.border.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '$completedCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      if (isCorrect ?? false) {
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
  _CardState({
    this.gapInputs = const {},
    this.isCorrect,
    this.isChecked = false,
  });
  final Map<String, String> gapInputs;
  final bool? isCorrect;
  final bool isChecked;

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
  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.gap = 5,
    this.borderRadius = 0,
  });
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashedPath = _dashPath(path, width: 8, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = (distance + width < metric.length)
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

class _SegmentedProgressPainter extends CustomPainter {
  _SegmentedProgressPainter({
    required this.totalSegments,
    required this.segmentStates,
    required this.primaryColor,
    required this.errorColor,
    required this.emptyColor,
  });
  final int totalSegments;
  // 0: Empty, 1: Correct, 2: Wrong
  final List<int> segmentStates;
  final Color primaryColor;
  final Color errorColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 3.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -3.14159 / 2; // -pi/2
    final gap = (totalSegments > 1) ? 0.2 : 0;
    final totalGap = gap * totalSegments;
    final segmentAngle = (2 * 3.14159 - totalGap) / totalSegments;

    for (var i = 0; i < totalSegments; i++) {
      final state = (i < segmentStates.length) ? segmentStates[i] : 0;

      if (state == 1) {
        paint.color = primaryColor;
      } else if (state == 2) {
        paint.color = errorColor;
      } else {
        paint.color = emptyColor;
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        segmentAngle,
        false,
        paint,
      );

      startAngle += segmentAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) {
    return oldDelegate.totalSegments != totalSegments ||
        oldDelegate.segmentStates != segmentStates;
  }
}
