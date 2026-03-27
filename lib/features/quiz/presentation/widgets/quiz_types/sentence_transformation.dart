import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SentenceTransformation extends StatefulWidget {
  const SentenceTransformation({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onNext,
    this.onPrev,
    this.onCheck,
    this.onShowExplain,
    this.onWordLongPress,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<SentenceTransformation> createState() => _SentenceTransformationState();
}

class _SentenceTransformationState extends State<SentenceTransformation> {
  int _currentIndex = 0;

  // Map<ItemID, CardState>
  final Map<String, _CardState> _cardStates = {};

  int get _firstUnpassedIndex {
    final items = widget.quiz.sentenceTransformations ?? [];
    return items
        .indexWhere((item) => !(_cardStates[item.id]?.isChecked ?? false));
  }

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

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
      final savedStates = progress.data?['cardStates'] as Map<String, dynamic>?;
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

      // Find first unpassed item index
      final items = widget.quiz.sentenceTransformations ?? [];
      int firstUnpassed = 0;
      for (int i = 0; i < items.length; i++) {
        if (!(_cardStates[items[i].id]?.isChecked ?? false)) {
          firstUnpassed = i;
          break;
        }
      }

      setState(() {
        _currentIndex = firstUnpassed;

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
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
      quizType: widget.quiz.type,
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
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveProgress();
  }

  void _animateToNextQuestion() {
    if (_currentIndex <
        (widget.quiz.sentenceTransformations?.length ?? 0) - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (isCorrect) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }

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

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final state = _cardStates[item.id] ?? _CardState();

        final borderColor = state.isChecked
            ? (state.isCorrect == true
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5))
            : appColors.border.withValues(alpha: 0.3);

        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, right: 16, bottom: 8),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Card Header: Counter & Progress

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Original Sentence (bordered container)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: appColors.primary,
                                  width: 4,
                                ),
                              ),
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
                                    item.original ?? '',
                                    onWordLongPress: widget.onWordLongPress,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Gap-fill Input Area
                          _buildGapFillArea(
                            context,
                            item,
                            state,
                            appColors,
                          ),

                          // Result Display
                          if (state.isChecked) ...[
                            const SizedBox(height: 24),
                            _buildResultDisplay(
                              context,
                              item,
                              state,
                              appColors,
                            ),
                          ],

                          // Spacing for floating buttons
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    if (state.isChecked || _isInputComplete(item)) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildFooterActions(
                              context,
                              item,
                              state,
                              appColors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildFooterActions(
    BuildContext context,
    SentenceTransformationItem item,
    _CardState state,
    AppColorsExtension appColors,
  ) {
    if (state.isChecked) {
      final isLast = _currentIndex ==
          (widget.quiz.sentenceTransformations?.length ?? 0) - 1;
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          if (isLast) {
            final unpassed = _firstUnpassedIndex;
            if (unpassed != -1) {
              _pageController.animateToPage(
                unpassed,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              widget.onCheck?.call();
              widget.onNext?.call();
            }
          } else {
            _goToNext();
          }
        },
        child: Text(
          isLast
              ? (_firstUnpassedIndex != -1
                  ? 'Review Uncompleted'
                  : (widget.finalActionText ?? 'Finish'))
              : 'Next',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    if (!state.isChecked && _isInputComplete(item)) {
      return ElevatedButton(
        onPressed: _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Check',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
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
        borderColor = Colors.green.withValues(alpha: 0.5);
        textColor = Colors.green;
      } else {
        borderColor = Colors.red.withValues(alpha: 0.5);
        textColor = Colors.red;
      }
    } else {
      borderColor = appColors.primary.withValues(alpha: 0.3);
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
