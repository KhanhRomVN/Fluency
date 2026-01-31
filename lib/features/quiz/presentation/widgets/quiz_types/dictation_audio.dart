import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DictationAudio extends StatefulWidget {
  const DictationAudio({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    super.key,
    this.onWordLongPress,
    this.onCheck,
    this.onNext,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;

  @override
  State<DictationAudio> createState() => _DictationAudioState();
}

class _DictationAudioState extends State<DictationAudio>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<String, _DictationItemState> _itemStates = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

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

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _playingId = null;
          });
        }
      }
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
            progress.data?['itemStates'] as Map<String, dynamic>?;
        if (savedStates != null) {
          savedStates.forEach((key, value) {
            final data = value as Map<String, dynamic>;
            _itemStates[key] = _DictationItemState(
              score: data['score'] as int? ?? 0,
              passed: data['passed'] as bool? ?? false,
              attempts: data['attempts'] as int? ?? 0,
              wordInputs: (data['wordInputs'] as Map<String, dynamic>?)?.map(
                    (k, v) => MapEntry(int.parse(k), v as String),
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
    final statesMap = _itemStates.map((key, value) {
      return MapEntry(key, {
        'score': value.score,
        'passed': value.passed,
        'attempts': value.attempts,
        'wordInputs': value.wordInputs.map((k, v) => MapEntry(k.toString(), v)),
      });
    });

    final totalItems = widget.quiz.dictations?.length ?? 0;
    final completedItems =
        _itemStates.values.where((s) => s.attempts > 0).length;
    final correctItems = _itemStates.values.where((s) => s.passed).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: widget.quiz.type ?? 'dictation',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'currentIndex': _currentIndex,
        'itemStates': statesMap,
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
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
      if (widget.quiz.dictations != null &&
          _currentIndex < widget.quiz.dictations!.length - 1) {
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

  Future<void> _playAudio(DictationItem item) async {
    if (_playingId == item.id) {
      await _audioPlayer.stop();
      setState(() {
        _playingId = null;
      });
      return;
    }

    if (item.audio != null) {
      try {
        await _audioPlayer.play(DeviceFileSource(item.audio!));
        setState(() {
          _playingId = item.id;
        });
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
  }

  void _checkAnswer(DictationItem item) {
    if (_itemStates[item.id]?.passed ?? false) return;

    final state = _itemStates[item.id] ?? _DictationItemState();
    final correctText = item.transcript ?? item.text ?? '';
    final words = correctText.trim().split(RegExp(r'\s+'));

    var correctCount = 0;
    var allCorrect = true;

    for (var i = 0; i < words.length; i++) {
      // ... (logic remains same for check) ...
      // Re-implementing logic to match state handling
      final input = state.wordInputs[i] ?? '';

      // Basic normalization matching original logic
      final correct = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final user = input.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

      // Simple equality check
      if (user == correct) {
        correctCount++;
      } else {
        allCorrect = false;
      }
    }

    final score = (correctCount / words.length * 100).round();

    setState(() {
      _itemStates[item.id] = state.copyWith(
        score: score,
        passed: allCorrect,
        attempts: state.attempts + 1,
      );
      _saveProgress();
    });
  }

  void _retryCurrent() {
    final item = widget.quiz.dictations![_currentIndex];
    setState(() {
      _itemStates[item.id] = _DictationItemState();
      _saveProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final dictations = widget.quiz.dictations ?? [];

    if (dictations.isEmpty) {
      return Center(
        child: Text(
          'No dictation items available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentItem = dictations[_currentIndex];
    final currentState = _itemStates[currentItem.id] ?? _DictationItemState();
    final correctText = currentItem.transcript ?? currentItem.text ?? '';
    final words = correctText.trim().split(RegExp(r'\s+'));

    // Check completion
    var allFilled = true;
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final input = currentState.wordInputs[i] ?? '';
      if (input.length != w.length) {
        allFilled = false;
        break;
      }
    }

    final borderColor = Colors.grey.withValues(alpha: 0.5);

    return Column(
      children: [
        // 1. Instruction
        if (widget.quiz.instruction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: Opacity(
                opacity: 0.8,
                child: RichTextParser.buildRichText(
                  context,
                  widget.quiz.instruction,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: appColors.textPrimary,
                      ),
                  onWordLongPress: widget.onWordLongPress,
                ).first,
              ),
            ),
          ),

        // 2. Card Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Stack(
                  children: [
                    // Main Card Container
                    Container(
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
                            // HEADER (Matching multiple_choice.dart)
                            _buildCardHeader(
                              context,
                              appColors,
                              dictations,
                              currentItem,
                            ),
                            Divider(
                              height: 1,
                              color: appColors.border.withValues(alpha: 0.5),
                            ),

                            // BODY
                            Expanded(
                              child: Stack(
                                children: [
                                  // Speed & Attempt Info (Top Left of Body)
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (currentItem.speed != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              'Speed: ${currentItem.speed}x',
                                              style: TextStyle(
                                                color: appColors.textSecondary
                                                    .withValues(alpha: 0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          'Attempt ${currentState.attempts} / 3', // Assuming max 3
                                          style: TextStyle(
                                            color: appColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Centered Content
                                  Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        60,
                                        24,
                                        100,
                                      ), // Top padding to avoid overlap with info
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Score
                                          if (currentState.attempts > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 24),
                                              child: Text(
                                                '${currentState.score}%',
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: currentState.score >=
                                                          80
                                                      ? Colors.yellow[
                                                          700] // Match React yellow-500
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),

                                          // Word Inputs
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 16,
                                            alignment: WrapAlignment.center,
                                            children: List.generate(
                                                words.length, (index) {
                                              final word = words[index];
                                              final input = currentState
                                                      .wordInputs[index] ??
                                                  '';

                                              Color? textColor;
                                              if (currentState.attempts > 0 ||
                                                  currentState.passed) {
                                                // Simple clean match
                                                final cleanWord = word
                                                    .replaceAll(
                                                      RegExp(r'[^\w]'),
                                                      '',
                                                    )
                                                    .toLowerCase();
                                                final cleanInput = input
                                                    .replaceAll(
                                                      RegExp(r'[^\w]'),
                                                      '',
                                                    )
                                                    .toLowerCase();
                                                if (cleanInput == cleanWord) {
                                                  textColor = appColors.primary;
                                                } else {
                                                  textColor = Colors.red;
                                                }
                                              }

                                              return _WordInput(
                                                index: index,
                                                correctWord: word,
                                                currentInput: input,
                                                textColor: textColor,
                                                enabled: !currentState.passed,
                                                appColors: appColors,
                                                onChanged: (val) {
                                                  final newInputs =
                                                      Map<int, String>.from(
                                                    currentState.wordInputs,
                                                  );
                                                  newInputs[index] = val;
                                                  setState(() {
                                                    _itemStates[
                                                            currentItem.id] =
                                                        currentState.copyWith(
                                                      wordInputs: newInputs,
                                                    );
                                                  });
                                                },
                                              );
                                            }),
                                          ),

                                          // Reveal Answer
                                          if (currentState.passed) ...[
                                            const SizedBox(height: 32),
                                            Text(
                                              correctText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: appColors.primary,
                                              ),
                                            ),
                                            if (currentItem.ipa != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  currentItem.ipa!,
                                                  style: TextStyle(
                                                    color: appColors.primary,
                                                    fontFamily: 'monospace',
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            if (currentItem.translate != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  currentItem.translate!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        appColors.textSecondary,
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PLAY BUTTON (Centered at Bottom)
                    if (!currentState.passed && !allFilled)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _playAudio(currentItem),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _playingId == currentItem.id
                                    ? Colors.white
                                    : appColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_playingId == currentItem.id
                                            ? Colors.red
                                            : appColors.primary)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: _playingId == currentItem.id
                                    ? Border.all(
                                        color:
                                            Colors.red.withValues(alpha: 0.3),
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                Icons.graphic_eq,
                                color: _playingId == currentItem.id
                                    ? Colors.red
                                    : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ACTION BUTTONS (Bottom Right)
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!currentState.passed &&
                              allFilled &&
                              currentState.attempts < 3)
                            ElevatedButton.icon(
                              onPressed: () => _checkAnswer(currentItem),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(
                                currentState.attempts == 0
                                    ? 'Check Answer'
                                    : 'Retry',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          if (currentState.passed)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _retryCurrent,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: appColors.buttonSecondBg,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.refresh,
                                      color: appColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (_currentIndex < dictations.length - 1)
                                  GestureDetector(
                                    onTap: _animateToNextQuestion,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: appColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: appColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                else if (widget.onNext != null)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      widget.onCheck?.call();
                                      widget.onNext?.call();
                                    },
                                    icon: const Icon(Icons.arrow_forward,
                                        size: 18),
                                    label: const Text(
                                      'Next question',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: appColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header Builder Logic extracted from multiple_choice.dart
  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<DictationItem> items,
    DictationItem currentItem,
  ) {
    // Calculate total completed
    // We can count based on our _itemStates passed status
    final completedCount = _itemStates.values.where((s) => s.passed).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentIndex + 1} / ${items.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary, // Muted foreground
            ),
          ),
          InkWell(
            onTap: () {
              // Show Drawer logic if needed
            },
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(32, 32),
                    painter: _SegmentedProgressPainter(
                      totalSegments: items.length,
                      segmentStates: List.generate(items.length, (index) {
                        final item = items[index];
                        final state = _itemStates[item.id];
                        if (state == null || state.attempts == 0) {
                          return 0; // Not started
                        }
                        return state.passed
                            ? 1
                            : 2; // 1: Correct, 2: Wrong (conceptually)
                      }),
                      primaryColor: appColors.primary,
                      errorColor: Colors.red,
                      emptyColor: Colors.grey[300]!,
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
          ),
        ],
      ),
    );
  }
}

class _WordInput extends StatefulWidget {
  const _WordInput({
    required this.index,
    required this.correctWord,
    required this.currentInput,
    required this.textColor,
    required this.enabled,
    required this.appColors,
    required this.onChanged,
  });

  final int index;
  final String correctWord;
  final String currentInput;
  final Color? textColor;
  final bool enabled;
  final AppColorsExtension appColors;
  final ValueChanged<String> onChanged;

  @override
  State<_WordInput> createState() => _WordInputState();
}

class _WordInputState extends State<_WordInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentInput);
  }

  @override
  void didUpdateWidget(_WordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentInput != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.currentInput,
        selection: TextSelection.collapsed(offset: widget.currentInput.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React: width: `${correctWord.length * 12 + 4}px`
    final width = (widget.correctWord.length * 12.0) + 4.0;
    const minWidth = 20.0;

    return SizedBox(
      width: math.max(width, minWidth),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dashes Layer (Bottom)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 4,
            ), // align slightly up? React mt-[-2px] means input overlaps dashes
            // React dashes are 2px high.
            child: Row(
              children: List.generate(widget.correctWord.length, (i) {
                // Hide dash if character exists
                final hideDash = i < widget.currentInput.length;

                return Container(
                  width: 10, // React w-[10px]
                  height: 2,
                  margin: const EdgeInsets.only(right: 2), // React gap-[2px]
                  decoration: BoxDecoration(
                    color: hideDash
                        ? Colors.transparent
                        : (widget.textColor ??
                            widget.appColors.textSecondary
                                .withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),

          // Input Layer (Top)
          TextField(
            controller: _controller,
            onChanged: (val) {
              // Only notify if within limit (UI should block it via maxLength anyway)
              if (val.length <= widget.correctWord.length) {
                widget.onChanged(val);
              }
            },
            inputFormatters: [
              LengthLimitingTextInputFormatter(widget.correctWord.length),
            ],
            enabled: widget.enabled,
            textAlign: TextAlign.left, // React text-left
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 2, // Adjust to match dash spacing approx
              color: widget.textColor ?? widget.appColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              counterText: '', // Hide default counter
            ),
            maxLength: widget.correctWord.length,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
        ],
      ),
    );
  }
}

class _DictationItemState {
  _DictationItemState({
    this.score = 0,
    this.passed = false,
    this.attempts = 0,
    this.wordInputs = const {},
  });
  final int score;
  final bool passed;
  final int attempts;
  final Map<int, String> wordInputs;

  _DictationItemState copyWith({
    int? score,
    bool? passed,
    int? attempts,
    Map<int, String>? wordInputs,
  }) {
    return _DictationItemState(
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      wordInputs: wordInputs ?? this.wordInputs,
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
  final List<int> segmentStates; // 0: Empty, 1: Correct, 2: Wrong
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
    return true;
  }
}
