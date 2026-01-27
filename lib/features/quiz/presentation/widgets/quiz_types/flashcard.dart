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
        currentCard.options != null && currentCard.options!.isNotEmpty;
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
    final correctOption = card.back is String
        ? card.back as String
        : (card.back as Map<String, dynamic>)['definition'] as String;

    String? localSelectedOption;
    var isProcessing = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        final displayCorrectOption =
            _stripHtml(correctOption).trim().toLowerCase();

        return StatefulBuilder(
          builder: (context, setDrawerState) {
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
                        'Select the correct definition',
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
                  ...card.options!.map((option) {
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
        // Instruction (Fixed height outside card)
        if (widget.quiz.instruction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Transform.translate(
                offset: Offset(_swipeOffset, 0),
                child: Transform.rotate(
                  angle: _swipeOffset * 0.0002, // subtle rotation during swipe
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
                            // Header INSIDE Card
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
    );
  }

  Widget _buildFront(
    BuildContext context,
    FlashcardItem item,
    AppColorsExtension appColors,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              'FRONT',
              style: TextStyle(
                color: appColors.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.image != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        item.image!,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: appColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                Text(
                  item.front,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (item.frontAudio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: InkWell(
                      onTap: () => _playAudio(item.frontAudio),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
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
                  Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: appColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.options != null && item.options!.isNotEmpty
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

  Widget _buildBack(
    BuildContext context,
    FlashcardItem item,
    AppColorsExtension appColors,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              'BACK',
              style: TextStyle(
                color: appColors.textSecondary.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildBackContent(context, item, appColors),
                  ),
                ),
              ),
              if (item.backAudio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: InkWell(
                    onTap: () => _playAudio(item.backAudio),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.buttonSecondBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volume_up,
                          color: appColors.textPrimary, size: 24),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent(
      BuildContext context, FlashcardItem item, AppColorsExtension appColors) {
    if (item.back is String) {
      return Center(
        child: RichTextParser.buildRichText(
          context,
          item.back as String,
          style: TextStyle(
            fontSize: 22,
            color: appColors.textPrimary,
          ),
          onWordLongPress: widget.onWordLongPress,
        ).first,
      );
    } else if (item.back is Map) {
      final map = item.back as Map<String, dynamic>;
      final definition = map['definition'] as String?;
      final example = map['example'] as String?;
      final synonyms = map['synonyms'] as String?;
      final antonyms = map['antonyms'] as String?;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (definition != null) ...[
            Text(
              'DEFINITION',
              style: TextStyle(
                fontSize: 12,
                color: appColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            RichTextParser.buildRichText(
              context,
              definition,
              style: TextStyle(
                fontSize: 22,
                color: appColors.textPrimary,
                height: 1.5,
              ),
              onWordLongPress: widget.onWordLongPress,
            ).first,
          ],
          if (example != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXAMPLE',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichTextParser.buildRichText(
                    context,
                    example,
                    style: TextStyle(
                      fontSize: 18,
                      color: appColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                    onWordLongPress: widget.onWordLongPress,
                  ).first,
                ],
              ),
            ),
          ],
          if (synonyms != null || antonyms != null) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (synonyms != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYNONYMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          synonyms,
                          style: TextStyle(
                            fontSize: 16,
                            color: appColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (antonyms != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANTONYMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          antonyms,
                          style: TextStyle(
                            fontSize: 16,
                            color: appColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
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
    final gap = (totalSegments > 1) ? 0.2 : 0;
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
