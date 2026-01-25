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

class _FlashcardState extends State<Flashcard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;

  // Animation
  late AnimationController _controller;
  late Animation<double> _animation;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  // We track playing audio to toggle icon or stop

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Reset flip when index changes logic is handled in _next/_prev
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _next() {
    if (widget.quiz.flashcards != null &&
        _currentIndex < widget.quiz.flashcards!.length - 1) {
      if (_isFlipped) {
        _controller.reverse();
        setState(() => _isFlipped = false);
        // Delay next until card flips back?
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() => _currentIndex++);
        });
      } else {
        setState(() => _currentIndex++);
      }
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      if (_isFlipped) {
        _controller.reverse();
        setState(() => _isFlipped = false);
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() => _currentIndex--);
        });
      } else {
        setState(() => _currentIndex--);
      }
    }
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
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    // 3D Flip effect
                    final angle = _animation.value * math.pi;
                    final isBack = angle > math.pi / 2;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(angle),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateY(
                                  math.pi,
                                ), // Correct mirroring for back
                              child:
                                  _buildBack(context, currentCard, appColors),
                            )
                          : _buildFront(context, currentCard, appColors),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appColors.background,
            border: Border(top: BorderSide(color: appColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _currentIndex > 0 ? _prev : null,
                icon: const Icon(Icons.chevron_left),
                color: appColors.textPrimary,
                disabledColor: appColors.textSecondary.withValues(alpha: 0.3),
                style: IconButton.styleFrom(
                  backgroundColor: appColors.buttonSecondBg,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              Text(
                '${_currentIndex + 1} / ${cards.length}',
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _currentIndex < cards.length - 1 ? _next : null,
                icon: const Icon(Icons.chevron_right),
                color: Colors.white,
                disabledColor: appColors.primary.withValues(alpha: 0.3),
                style: IconButton.styleFrom(
                  backgroundColor: appColors.primary,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ],
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
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appColors.primary.withValues(alpha: 0.05),
            appColors.primary.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              'FRONT',
              style: TextStyle(
                color: appColors.primary,
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
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.image!, // Or asset
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                Text(
                  item.front,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (item.frontAudio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: IconButton(
                      onPressed: () {
                        // Stop propagation handled by GestureDetector not wrapping this strictly?
                        // GestureDetector for flip is parent.
                        // We need to stop event propagation? Flutter doesn't have stopPropagation easily in widget tree without specialized widgets.
                        // But GestureDetector handles taps unless child handles it.
                        // If IconButton handles tap, parent won't see it? Yes usually.
                        _playAudio(item.frontAudio);
                      },
                      icon: const Icon(Icons.volume_up),
                      style: IconButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: appColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Click to flip',
                    style: TextStyle(
                      color: appColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 14,
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
    // Parse back content
    Widget backContent;
    if (item.back is String) {
      backContent = RichTextParser.buildRichText(
        context,
        item.back as String,
        style: TextStyle(fontSize: 18, color: appColors.textPrimary),
        onWordLongPress: widget.onWordLongPress,
      ).first;
    } else if (item.back is Map) {
      final map = item.back as Map<String, dynamic>;
      final definition = map['definition'] as String?;
      final example = map['example'] as String?;
      final synonyms = map['synonyms'] as String?;
      final antonyms = map['antonyms'] as String?;

      backContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (definition != null)
            RichTextParser.buildRichText(
              context,
              definition,
              style: TextStyle(fontSize: 18, color: appColors.textPrimary),
              onWordLongPress: widget.onWordLongPress,
            ).first,
          if (example != null) ...[
            const SizedBox(height: 12),
            Text(
              'EXAMPLE',
              style: TextStyle(
                fontSize: 10,
                color: appColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            RichTextParser.buildRichText(
              context,
              example,
              style: TextStyle(
                fontSize: 16,
                color: appColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
              onWordLongPress: widget.onWordLongPress,
            ).first,
          ],
          if (synonyms != null || antonyms != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                if (synonyms != null)
                  RichText(
                    text: TextSpan(
                      text: 'Syn: ',
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: synonyms,
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (antonyms != null)
                  RichText(
                    text: TextSpan(
                      text: 'Ant: ',
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: antonyms,
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.normal,
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
    } else {
      backContent =
          const Text('Invalid content', style: TextStyle(color: Colors.red));
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              'BACK',
              style: TextStyle(
                color: appColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    backContent,
                    if (item.backAudio != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: IconButton(
                          onPressed: () => _playAudio(item.backAudio),
                          icon: const Icon(Icons.volume_up),
                          style: IconButton.styleFrom(
                            backgroundColor: appColors.buttonSecondBg,
                            foregroundColor: appColors.textPrimary,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper extension for RichText shortcut
