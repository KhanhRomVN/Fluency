import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class Flashcard extends StatefulWidget {
  const Flashcard({
    required this.quiz,
    super.key,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isAutoPlay = false;
  final Map<String, bool> _completedCards = {};
  final Map<String, bool> _cardCorrectness = {};

  // Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Swipe Animation
  double _swipeOffset = 0;
  late AnimationController _swipeController;
  Animation<double>? _swipeSlideAnimation;
  bool _isTransitioning = false;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeController.addListener(() {
      setState(() {
        if (_swipeSlideAnimation != null) {
          _swipeOffset = _swipeSlideAnimation!.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handleFlipRequest() {
    final currentCard = (widget.quiz.flashcards ?? [])[_currentIndex];

    if (_isFlipped) {
      _performFlip();
      return;
    }

    final hasOptions =
        (currentCard.options != null && currentCard.options!.isNotEmpty) ||
            (currentCard.optionsTrans != null &&
                currentCard.optionsTrans!.isNotEmpty);

    if (hasOptions && !(_completedCards[currentCard.id] ?? false)) {
      _showOptionsDrawer(currentCard);
    } else {
      _performFlip();
      if (!(_completedCards[currentCard.id] ?? false)) {
        _markAsCompleted(currentCard.id, true);
      }
    }
  }

  void _performFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _markAsCompleted(String cardId, bool isCorrect) {
    setState(() {
      _completedCards[cardId] = true;
      _cardCorrectness[cardId] = isCorrect;
    });
  }

  void _showOptionsDrawer(FlashcardItem card) {
    String? localSelectedOption;
    var isProcessing = false;

    // Determine correct option text
    String correctOptionText = '';
    if (card.optionsTrans != null && card.optionsTrans!.isNotEmpty) {
      correctOptionText = card.optionsTrans!
          .firstWhere((o) => o.isCorrect,
              orElse: () => const QuizOptionTrans(text: '', isCorrect: false))
          .text;
    } else {
      final back = card.back;
      correctOptionText = back is String
          ? back
          : (back is Map ? (back['mainDefinition']?.toString() ?? '') : '');
    }

    final displayCorrectOption =
        _stripHtml(correctOptionText).trim().toLowerCase();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return StatefulBuilder(
          builder: (context, setDrawerState) {
            final options = card.optionsTrans?.map((e) => e.text).toList() ??
                card.options ??
                [];

            return Container(
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.optionsTrans != null
                            ? 'Chọn định nghĩa đúng'
                            : 'Select the correct definition',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...options.map((option) {
                    final isSelected = localSelectedOption == option;
                    final isActuallyCorrect =
                        option.trim().toLowerCase() == displayCorrectOption;

                    var borderColor = appColors.border;
                    Color? bgColor;
                    Widget? trailingIcon;

                    if (isSelected) {
                      if (isActuallyCorrect) {
                        borderColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.1);
                        trailingIcon = const Icon(Icons.check,
                            color: Colors.green, size: 20);
                      } else {
                        borderColor = Colors.red;
                        bgColor = Colors.red.withValues(alpha: 0.1);
                        trailingIcon = const Icon(Icons.close,
                            color: Colors.red, size: 20);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isProcessing
                            ? null
                            : () async {
                                setDrawerState(() {
                                  localSelectedOption = option;
                                  isProcessing = true;
                                });

                                final isCorrect = isActuallyCorrect;
                                _markAsCompleted(card.id, isCorrect);

                                // Delay to let user see the result
                                await Future<void>.delayed(
                                    const Duration(milliseconds: 1500));
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _performFlip();
                                }
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(
                                color: borderColor, width: isSelected ? 2 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? (isActuallyCorrect
                                            ? Colors.green
                                            : Colors.red)
                                        : appColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (trailingIcon != null) ...[
                                const SizedBox(width: 12),
                                trailingIcon,
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp('<[^>]*>'), '');
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isTransitioning) return;
    setState(() {
      _swipeOffset += details.primaryDelta!;
      _swipeOffset = _swipeOffset.clamp(-100.0, 100.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;
    const threshold = 80.0;

    if (_swipeOffset < -threshold &&
        _currentIndex < (widget.quiz.flashcards?.length ?? 0) - 1) {
      _slideCard('left');
    } else if (_swipeOffset > threshold && _currentIndex > 0) {
      _slideCard('right');
    } else {
      _resetSwipe();
    }
  }

  void _slideCard(String direction) {
    setState(() {
      _isTransitioning = true;
    });

    final endOffset = direction == 'left' ? -400.0 : 400.0;
    _swipeSlideAnimation =
        Tween<double>(begin: _swipeOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    _swipeController.forward(from: 0).then((_) {
      setState(() {
        _isFlipped = false;
        _flipController.reset();
        _currentIndex += (direction == 'left' ? 1 : -1);
        _swipeOffset = (direction == 'left' ? 400.0 : -400.0);

        _swipeSlideAnimation =
            Tween<double>(begin: _swipeOffset, end: 0).animate(
          CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
        );
        _swipeController.forward(from: 0).then((_) {
          setState(() {
            _isTransitioning = false;
          });
        });
      });
    });
  }

  void _resetSwipe() {
    _swipeSlideAnimation = Tween<double>(begin: _swipeOffset, end: 0).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _swipeController.forward(from: 0);
  }

  Future<void> _playAudio(String? path) async {
    if (path == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('Error playing flashcard audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final cards = widget.quiz.flashcards ?? [];

    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No flashcards available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentCard = cards[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.quiz.instruction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              children: RichTextParser.buildRichText(
                context,
                widget.quiz.instruction,
                style: TextStyle(color: appColors.textPrimary, fontSize: 16),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Transform.translate(
                offset: Offset(_swipeOffset, 0),
                child: Transform.rotate(
                  angle: _swipeOffset * 0.0002,
                  child: Opacity(
                    opacity: (1 - (_swipeOffset.abs() / 400)).clamp(0.5, 1.0),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: appColors.primary,
                          strokeWidth: 2,
                          gap: 4,
                          borderRadius: 12,
                        ),
                        child: Column(
                          children: [
                            _buildInternalHeader(context, appColors, cards),
                            Expanded(
                              child: GestureDetector(
                                onTap: _handleFlipRequest,
                                child: AnimatedBuilder(
                                  animation: _flipAnimation,
                                  builder: (context, child) {
                                    final angle =
                                        _flipAnimation.value * math.pi;
                                    final isBack = angle > math.pi / 2;

                                    return Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(angle),
                                      child: isBack
                                          ? Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()
                                                ..rotateY(math.pi),
                                              child: _buildBack(context,
                                                  currentCard, appColors),
                                            )
                                          : _buildFront(
                                              context, currentCard, appColors),
                                    );
                                  },
                                ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildInternalHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<FlashcardItem> questions,
  ) {
    final completedCount = _completedCards.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentIndex + 1} / ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isAutoPlay = !_isAutoPlay;
                  });
                },
                icon: Icon(
                  _isAutoPlay ? Icons.volume_up : Icons.volume_off,
                  size: 20,
                  color: appColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
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
                          if (!(_completedCards[qId] ?? false)) return 0;
                          return (_cardCorrectness[qId] ?? true) ? 1 : 2;
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
        ],
      ),
    );
  }

  Widget _buildFront(
    BuildContext context,
    FlashcardItem item,
    AppColorsExtension appColors,
  ) {
    final front = item.front;
    String term = '';
    String? ipa;
    String? contextSentence;
    String? audio;

    if (front is Map) {
      term = front['term']?.toString() ?? '';
      ipa = front['ipa']?.toString();
      contextSentence = front['contextSentence']?.toString();
      audio = front['audio']?.toString() ?? item.frontAudio;
    } else {
      term = front?.toString() ?? '';
      audio = item.frontAudio;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  term,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (ipa != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ipa,
                    style: TextStyle(
                      color: appColors.textSecondary,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (audio != null) ...[
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => _playAudio(audio),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: appColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.volume_up,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
                if (contextSentence != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildContextSentence(
                        context, contextSentence, term, appColors),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rotate_right, size: 16, color: appColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    (item.options != null && item.options!.isNotEmpty) ||
                            (item.optionsTrans != null &&
                                item.optionsTrans!.isNotEmpty)
                        ? 'Tap to solve & flip'
                        : 'Click to flip',
                    style: TextStyle(
                      color: appColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildContextSentence(BuildContext context, String sentence,
      String term, AppColorsExtension appColors) {
    if (term.isEmpty) return Text(sentence);

    final pattern = RegExp(RegExp.escape(term), caseSensitive: false);
    final matches = pattern.allMatches(sentence);

    if (matches.isEmpty) {
      return Text(
        '"$sentence"',
        style: TextStyle(
          fontSize: 18,
          color: appColors.textPrimary.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }

    final spans = <InlineSpan>[];
    var lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans
            .add(TextSpan(text: sentence.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: sentence.substring(match.start, match.end),
        style: TextStyle(
          color: appColors.primary,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.normal,
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(lastMatchEnd)));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 18,
          color: appColors.textPrimary.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        children: [
          const TextSpan(text: '"'),
          ...spans,
          const TextSpan(text: '"'),
        ],
      ),
    );
  }

  Widget _buildBack(
    BuildContext context,
    FlashcardItem item,
    AppColorsExtension appColors,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appColors.cardBackground,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildBackContent(context, item, appColors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(
      BuildContext context, FlashcardItem item, AppColorsExtension appColors) {
    final back = item.back;
    final String term = (item.front is Map)
        ? (item.front['term']?.toString() ?? '')
        : (item.front?.toString() ?? '');

    if (back is String) {
      return Column(
        children: [
          Text(
            term,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: appColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            children: RichTextParser.buildRichText(
              context,
              back,
              style: TextStyle(fontSize: 20, color: appColors.textPrimary),
            ),
          ),
        ],
      );
    } else if (back is Map) {
      final map = back as Map<String, dynamic>;
      final images =
          (map['images'] as List?)?.map((e) => e.toString()).toList();
      final mainDefinition = map['mainDefinitionTrans']?.toString() ??
          map['mainDefinition']?.toString() ??
          map['definition']?.toString();
      final example = map['example']?.toString();
      final wordForms = map['wordForms'] as List?;
      final synonyms = map['synonyms'];
      final antonyms = map['antonyms'];
      final detailedDefinitions = map['detailedDefinitions'] as List?;
      final collocations = map['collocations'] as List?;
      final audio = map['audio']?.toString() ?? item.backAudio;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              term,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: appColors.primary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (images != null && images.isNotEmpty)
            Container(
              height: 160,
              padding: const EdgeInsets.only(bottom: 20),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[index],
                      height: 160,
                      width: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        width: 240,
                        color: appColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (mainDefinition != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: appColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: RichTextParser.buildRichText(
                      context,
                      mainDefinition,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (example != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            left:
                                BorderSide(color: appColors.primary, width: 2)),
                      ),
                      child: Wrap(
                        children: RichTextParser.buildRichText(
                          context,
                          '"$example"',
                          style: TextStyle(
                              color: appColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (wordForms != null && wordForms.isNotEmpty)
            _buildSectionHeader('Word Forms', appColors),
          if (wordForms != null && wordForms.isNotEmpty)
            ...wordForms.map(
                (f) => _buildFormItem(f as Map<dynamic, dynamic>, appColors)),
          if (synonyms != null) _buildSectionHeader('Synonyms', appColors),
          if (synonyms != null) _buildListLike(synonyms, appColors),
          if (antonyms != null) _buildSectionHeader('Antonyms', appColors),
          if (antonyms != null) _buildListLike(antonyms, appColors),
          if (detailedDefinitions != null && detailedDefinitions.isNotEmpty)
            _buildSectionHeader('Detailed Meanings', appColors),
          if (detailedDefinitions != null && detailedDefinitions.isNotEmpty)
            ...detailedDefinitions.map(
                (d) => _buildDetailItem(d as Map<dynamic, dynamic>, appColors)),
          if (collocations != null && collocations.isNotEmpty)
            _buildSectionHeader('Collocations', appColors),
          if (collocations != null && collocations.isNotEmpty)
            ...collocations.map((c) =>
                _buildCollocationItem(c as Map<dynamic, dynamic>, appColors)),
          if (audio != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: IconButton(
                  onPressed: () => _playAudio(audio),
                  icon: const Icon(Icons.volume_up, size: 28),
                  color: appColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: appColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const Divider(thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildFormItem(
      Map<dynamic, dynamic> form, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  form['label']?.toString().toUpperCase() ?? '',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                form['value']?.toString() ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          if (form['example'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'ex: ${form['example']}',
                style: TextStyle(
                    fontSize: 14,
                    color: appColors.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      Map<dynamic, dynamic> detail, AppColorsExtension appColors) {
    final pos = detail['partOfSpeech']?.toString().toLowerCase() ?? '';
    Color color = appColors.primary;
    if (pos.contains('verb')) color = Colors.blue;
    if (pos.contains('noun')) color = Colors.green;
    if (pos.contains('adj')) color = Colors.orange;
    if (pos.contains('adv')) color = Colors.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pos.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail['trans']?.toString() ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),
            ],
          ),
          if (detail['example'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'ex: ${detail['example']}',
                style: TextStyle(
                    fontSize: 14,
                    color: appColors.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollocationItem(
      Map<dynamic, dynamic> col, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              col['phrase']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            col['meaning']?.toString() ?? '',
            style: TextStyle(color: appColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildListLike(dynamic data, AppColorsExtension appColors) {
    if (data is String) return Text(data);
    if (data is List) {
      return Column(
        children: data.map((item) {
          if (item is Map) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['word']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(item['meaning']?.toString() ?? '',
                      style: TextStyle(
                          color: appColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return Text(item.toString());
        }).toList(),
      );
    }
    return Text(data.toString());
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
  final List<int> segmentStates;
  final Color primaryColor;
  final Color errorColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.toDouble()
      ..strokeCap = StrokeCap.butt;

    var startAngle = -math.pi / 2;
    const gap = 0.2;
    final totalGap = gap * totalSegments;
    final segmentAngle = (2 * math.pi - totalGap) / totalSegments;

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
