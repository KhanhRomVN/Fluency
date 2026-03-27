import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:provider/provider.dart';

class Flashcard extends StatefulWidget {
  const Flashcard({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onNext,
    this.onPrev,
    this.onWordLongPress,
    this.onCheck,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String word)? onWordLongPress;
  final String? finalActionText;

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<String, bool> _completedCards = {};
  final Map<String, bool> _cardCorrectness = {};

  int get _firstUncompletedIndex {
    final flashcards = widget.quiz.flashcards ?? [];
    return flashcards.indexWhere((c) => !(_completedCards[c.id] ?? false));
  }

  // Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Page Controller
  late PageController _pageController;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _speakTimer;
  bool _isNavigatingToNextQuiz = false;

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

    _pageController = PageController(initialPage: _currentIndex);

    // Load saved progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _loadProgress() async {
    try {
      debugPrint('Flashcard: _loadProgress called');
      final quizStateProvider = context.read<QuizStateProvider>();
      final progress = await quizStateProvider.loadQuizProgress(
        widget.lessonId,
        widget.quizId,
      );

      if (progress != null && mounted) {
        debugPrint('Flashcard: Progress found, restoring');
        setState(() {
          // Find first uncompleted card index instead of just taking saved currentIndex
          final flashcards = widget.quiz.flashcards ?? [];
          int firstUncompleted = 0;

          // Restore completed cards first
          final completed =
              progress.data?['completedCards'] as Map<String, dynamic>?;
          if (completed != null) {
            completed.forEach((key, value) {
              _completedCards[key] = value as bool;
            });
          }

          // Find the index
          for (int i = 0; i < flashcards.length; i++) {
            if (!(_completedCards[flashcards[i].id] ?? false)) {
              firstUncompleted = i;
              break;
            }
          }
          final savedIndex =
              progress.data?['currentIndex'] as int? ?? firstUncompleted;

          final totalItems = widget.quiz.flashcards?.length ?? 0;
          int indexToUse = savedIndex;

          // Hybrid logic: if we are at the end but have uncompleted items, jump back to first uncompleted
          if (savedIndex == totalItems - 1 &&
              firstUncompleted != -1 &&
              firstUncompleted < savedIndex) {
            indexToUse = firstUncompleted;
          }

          _currentIndex = indexToUse;

          // Restore card correctness
          final correctness =
              progress.data?['cardCorrectness'] as Map<String, dynamic>?;
          if (correctness != null) {
            correctness.forEach((key, value) {
              _cardCorrectness[key] = value as bool;
            });
          }
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }

        // If quiz is completed, notify parent
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      }

      // Auto-speak the current card after loading (whether progress exists or not)
      _checkAndMarkVisibleCard();
      debugPrint('Flashcard: About to speak, mounted=$mounted');
      if (mounted) {
        // Wait longer for TTS to initialize
        // Wait for TTS to initialize (poll for up to 5 seconds)
        final ttsProvider = context.read<TtsProvider>();
        if (!ttsProvider.isInitialized) {
          await ttsProvider.initService();
        }

        // Check one last time
        if (!ttsProvider.isInitialized) {
          debugPrint('Flashcard: TTS not initialized after 5s, skipping speak');
          return;
        }
        _speakCurrentCard();
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('Flashcard: Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final quizStateProvider = context.read<QuizStateProvider>();
      final totalItems = widget.quiz.flashcards?.length ?? 0;
      final completedItems = _completedCards.length;
      final correctItems = _cardCorrectness.values.where((v) => v).length;

      await quizStateProvider.saveQuizProgress(
        lessonId: widget.lessonId,
        quizId: widget.quizId,
        quizType: 'flashcard',
        completedItems: completedItems,
        totalItems: totalItems,
        correctItems: correctItems,
        data: {
          'currentIndex': _currentIndex,
          'completedCards': _completedCards,
          'cardCorrectness': _cardCorrectness,
          'correctness': _cardCorrectness,
        },
      );
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('Flashcard: Error saving progress: $e');
    }
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _flipController.dispose();
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      _flipController.reset();
    });
    _checkAndMarkVisibleCard();
    _saveProgress();

    // Debounce speaking to prevent lag during rapid swiping
    _speakTimer?.cancel();
    _speakTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _speakCurrentCard();
      }
    });
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
    _saveProgress();
  }

  void _checkAndMarkVisibleCard() {
    final flashcards = widget.quiz.flashcards ?? [];
    if (_currentIndex >= 0 && _currentIndex < flashcards.length) {
      final currentCard = flashcards[_currentIndex];
      final hasOptions =
          (currentCard.options != null && currentCard.options!.isNotEmpty) ||
              (currentCard.optionsTrans != null &&
                  currentCard.optionsTrans!.isNotEmpty);

      if (!hasOptions && !(_completedCards[currentCard.id] ?? false)) {
        _markAsCompleted(currentCard.id, true);
      }
    }
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: appColors.drawerBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Definition',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: appColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Choose the correct meaning for the term',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: appColors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: appColors.border.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...options.map((option) {
                          final isSelected = localSelectedOption == option;
                          final isActuallyCorrect =
                              option.trim().toLowerCase() ==
                                  displayCorrectOption;

                          var borderColor =
                              appColors.border.withValues(alpha: 0.3);
                          Color? bgColor;
                          Widget? trailingIcon;

                          if (localSelectedOption != null) {
                            if (isActuallyCorrect) {
                              borderColor = Colors.green.withValues(alpha: 0.5);
                              bgColor = Colors.green.withValues(alpha: 0.1);
                              trailingIcon = const Icon(Icons.check,
                                  color: Colors.green, size: 20);
                            } else if (isSelected) {
                              borderColor = Colors.red.withValues(alpha: 0.5);
                              bgColor = Colors.red.withValues(alpha: 0.1);
                              trailingIcon = const Icon(Icons.close,
                                  color: Colors.red, size: 20);
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
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

                                      // Play sound effect
                                      if (context.mounted) {
                                        final soundProvider =
                                            context.read<SoundEffectProvider>();
                                        if (isCorrect) {
                                          soundProvider.playCorrect();
                                        } else {
                                          soundProvider.playWrong();
                                        }
                                      }

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: bgColor ?? appColors.inputBackground,
                                  border: Border.all(
                                      color: borderColor,
                                      width: (isSelected ||
                                              (localSelectedOption != null &&
                                                  isActuallyCorrect))
                                          ? 2
                                          : 1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children:
                                              RichTextParser.buildTextSpans(
                                            context,
                                            option.trim(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: (localSelectedOption !=
                                                          null &&
                                                      isActuallyCorrect)
                                                  ? Colors.green
                                                  : (isSelected
                                                      ? Colors.red
                                                      : appColors.textPrimary
                                                          .withValues(
                                                              alpha: 0.9)),
                                            ),
                                          ),
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
                  ),
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

  // Swipe logic removed in favor of PageView

  Future<void> _speakCurrentCard() async {
    debugPrint('Flashcard: _speakCurrentCard START');
    try {
      final cards = widget.quiz.flashcards ?? [];
      debugPrint(
          'Flashcard: Total cards=${cards.length}, currentIndex=$_currentIndex');
      if (_currentIndex >= cards.length) {
        debugPrint('Flashcard: Index out of range, returning');
        return;
      }

      final currentCard = cards[_currentIndex];
      final front = currentCard.front;
      String term = '';

      if (front is Map) {
        term = front['term']?.toString() ?? '';
      } else {
        term = front?.toString() ?? '';
      }

      debugPrint('Flashcard: Extracted term="$term"');
      if (term.isNotEmpty) {
        final ttsProvider = context.read<TtsProvider>();
        debugPrint(
            'Flashcard: TtsProvider initialized=${ttsProvider.isInitialized}');
        if (ttsProvider.isInitialized) {
          debugPrint('Flashcard: Calling speak for term="$term"');
          // Use default/active voice instead of forcing male/switching
          await ttsProvider.speak(term);
          debugPrint('Flashcard: speak completed');
        }
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('TTS Error in flashcard: $e');
    }
  }

  Color _getBorderColor(String cardId) {
    if (!_completedCards.containsKey(cardId)) {
      return Colors.grey.withValues(alpha: 0.1);
    }
    return (_cardCorrectness[cardId] ?? false)
        ? Colors.green.withValues(alpha: 0.6)
        : Colors.red.withValues(alpha: 0.6);
  }

  Color _getTextColor(String cardId, {required Color defaultColor}) {
    if (!_completedCards.containsKey(cardId)) {
      return defaultColor;
    }
    return (_cardCorrectness[cardId] ?? false) ? Colors.green : Colors.red;
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isNavigatingToNextQuiz) return false;

        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.horizontal &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent &&
            notification.dragDetails != null &&
            notification.dragDetails!.primaryDelta! < -5) {
          if (_currentIndex == cards.length - 1) {
            _isNavigatingToNextQuiz = true;
            widget.onNext?.call();
            // Reset navigating flag after a delay to allow the animation to start
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                _isNavigatingToNextQuiz = false;
              }
            });
            return true;
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];

          return Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 24),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(card.id),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: index == _currentIndex ? _handleFlipRequest : null,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          // Only animate the active card
                          final angle = (index == _currentIndex)
                              ? _flipAnimation.value * math.pi
                              : 0.0;
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
                                    child: _buildBack(context, card, appColors,
                                        index, cards.length),
                                  )
                                : _buildFront(context, card, appColors, index,
                                    cards.length),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(
    BuildContext context,
    FlashcardItem item,
    AppColorsExtension appColors,
    int index,
    int total,
  ) {
    final isLast = index == total - 1;
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
        clipBehavior: Clip.none,
        children: [
          // Top Left: Audio Button
          Positioned(
            top: -12,
            left: -12,
            child: InkWell(
              onTap: () => _speakCurrentCard(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: appColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
          // Top Right: Badge
          Positioned(
            top: -12,
            right: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appColors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.quiz.flashcards?.length ?? 1}',
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Text(
                  term,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (ipa != null && ipa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ipa,
                    style: TextStyle(
                      color: _getTextColor(item.id,
                          defaultColor: appColors.textSecondary),
                      fontSize: 18,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
                if (contextSentence != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildContextSentence(
                        context,
                        contextSentence,
                        term,
                        appColors,
                        _getTextColor(item.id,
                            defaultColor:
                                appColors.textPrimary.withValues(alpha: 0.9))),
                  ),
                ],
                const Spacer(flex: 3),
              ],
            ),
          ),
          if (_completedCards[item.id] ?? false)
            Positioned(
              bottom: -12,
              right: -12,
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    if (_firstUncompletedIndex == -1 ||
                        widget.finalActionText != null) {
                      widget.onCheck?.call();
                      widget.onNext?.call();
                    } else {
                      final uncompleted = _firstUncompletedIndex;
                      _pageController.animateToPage(
                        uncompleted,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_cardCorrectness[item.id] ?? true)
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  foregroundColor: (_cardCorrectness[item.id] ?? true)
                      ? Colors.green
                      : Colors.red,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: (_cardCorrectness[item.id] ?? true)
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.red.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  isLast ? (widget.finalActionText ?? 'Finish') : 'Next',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContextSentence(BuildContext context, String sentence,
      String term, AppColorsExtension appColors, Color textColor) {
    if (term.isEmpty) return Text(sentence);

    final pattern = RegExp(RegExp.escape(term), caseSensitive: false);
    final matches = pattern.allMatches(sentence);

    if (matches.isEmpty) {
      return Text(
        '"$sentence"',
        style: TextStyle(
          fontSize: 18,
          color: textColor,
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
          color: textColor,
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
          color: appColors.textSecondary,
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
    int index,
    int total,
  ) {
    final isLast = index == total - 1;

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: () {
              final isWrong = (_completedCards[item.id] ?? false) &&
                  !(_cardCorrectness[item.id] ?? true);

              if (isWrong) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOptionsDrawer(item),
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text(
                          'Retry',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.15),
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            if (_firstUncompletedIndex == -1 ||
                                widget.finalActionText != null) {
                              widget.onCheck?.call();
                              widget.onNext?.call();
                            } else {
                              final uncompleted = _firstUncompletedIndex;
                              _pageController.animateToPage(
                                uncompleted,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          foregroundColor: Colors.grey,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isLast
                              ? (widget.finalActionText ?? 'Finish')
                              : 'Next',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Normal state (correct or not yet wrong)
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isLast && _firstUncompletedIndex != -1) ...[
                    OutlinedButton(
                      onPressed: () {
                        final uncompleted = _firstUncompletedIndex;
                        _pageController.animateToPage(
                          uncompleted,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: appColors.primary, width: 1),
                        foregroundColor: appColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Review Uncompleted',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        if (_firstUncompletedIndex == -1 ||
                            widget.finalActionText != null) {
                          widget.onCheck?.call();
                          widget.onNext?.call();
                        } else {
                          final uncompleted = _firstUncompletedIndex;
                          _pageController.animateToPage(
                            uncompleted,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      foregroundColor: Colors.green,
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                    ),
                    child: Text(
                      isLast ? (widget.finalActionText ?? 'Finish') : 'Next',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }(),
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
    final String? ipa =
        (item.front is Map) ? (item.front as Map)['ipa']?.toString() : null;

    if (back is String) {
      return Column(
        children: [
          Text(
            term,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (ipa != null && ipa.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ipa,
              style: TextStyle(
                fontSize: 16,
                color: _getTextColor(item.id,
                    defaultColor: appColors.textSecondary),
                fontFamily: 'NotoSans',
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            children: RichTextParser.buildRichText(
              context,
              back,
              style: TextStyle(
                fontSize: 20,
                color: appColors.textPrimary,
              ),
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
                  color: appColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          if (ipa != null && ipa.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                ipa,
                style: TextStyle(
                  fontSize: 16,
                  color: _getTextColor(item.id,
                      defaultColor: appColors.textSecondary),
                  fontFamily: 'NotoSans',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
                              color: _getTextColor(item.id,
                                  defaultColor: appColors.textSecondary),
                              fontStyle: FontStyle.italic,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (wordForms != null && wordForms.isNotEmpty) ...[
            _buildSectionHeader('Word Forms', appColors),
            ...wordForms.map(
                (f) => _buildFormItem(f as Map<dynamic, dynamic>, appColors)),
          ],
          if (synonyms != null &&
              ((synonyms is String && synonyms.isNotEmpty) ||
                  (synonyms is List && synonyms.isNotEmpty))) ...[
            _buildSectionHeader('Synonyms', appColors),
            _buildListLike(synonyms, appColors),
          ],
          if (antonyms != null &&
              ((antonyms is String && antonyms.isNotEmpty) ||
                  (antonyms is List && antonyms.isNotEmpty))) ...[
            _buildSectionHeader('Antonyms', appColors),
            _buildListLike(antonyms, appColors),
          ],
          if (detailedDefinitions != null &&
              detailedDefinitions.isNotEmpty) ...[
            _buildSectionHeader('Detailed Meanings', appColors),
            ...detailedDefinitions.map(
                (d) => _buildDetailItem(d as Map<dynamic, dynamic>, appColors)),
          ],
          if (collocations != null && collocations.isNotEmpty) ...[
            _buildSectionHeader('Collocations', appColors),
            ...collocations.map((c) =>
                _buildCollocationItem(c as Map<dynamic, dynamic>, appColors)),
          ],
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
              Expanded(
                child: Text(
                  form['value']?.toString() ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
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
          const SizedBox(height: 6),
          Text(
            detail['trans']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            col['phrase']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((item) {
          if (item is Map) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['word']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['meaning']?.toString() ?? '',
                    style: TextStyle(
                      color: appColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
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
