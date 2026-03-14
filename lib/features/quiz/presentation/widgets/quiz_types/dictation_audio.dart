import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DictationAudio extends StatefulWidget {
  const DictationAudio({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onNext,
    this.onPrev,
    this.onWordLongPress,
    this.onCheck,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  @override
  State<DictationAudio> createState() => _DictationAudioState();
}

class _DictationAudioState extends State<DictationAudio> {
  int _currentIndex = 0;
  final Map<String, _DictationItemState> _itemStates = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;
  final Map<String, List<FocusNode>> _focusNodesByItem =
      {}; // FocusNodes for each item
  final Map<String, String> _selectedVoiceByItem =
      {}; // Cache selected voice for each item

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

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
              correctWords:
                  (data['correctWords'] as Map<String, dynamic>?)?.map(
                        (k, v) => MapEntry(int.parse(k), v as bool),
                      ) ??
                      {},
            );
          });
        }

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
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
        'correctWords':
            value.correctWords.map((k, v) => MapEntry(k.toString(), v)),
      });
    });

    final totalItems = widget.quiz.dictations?.length ?? 0;
    final completedItems =
        _itemStates.values.where((s) => s.attempts > 0).length;
    final correctItems = _itemStates.values.where((s) => s.passed).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: widget.quiz.type,
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
    _audioPlayer.dispose();
    _pageController.dispose();
    // Dispose all focus nodes
    for (final nodes in _focusNodesByItem.values) {
      for (final node in nodes) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveProgress();
  }

  Future<void> _playAudio(DictationItem item) async {
    // Stop if already playing
    if (_playingId == item.id) {
      final ttsProvider = context.read<TtsProvider>();
      await ttsProvider.ttsService?.stop();
      setState(() {
        _playingId = null;
      });
      return;
    }

    // Use TTS to speak the text
    final correctText = item.transcript ?? item.text ?? '';
    if (correctText.isNotEmpty) {
      try {
        final ttsProvider = context.read<TtsProvider>();

        // Initialize TTS if needed
        if (!ttsProvider.isInitialized) {
          await ttsProvider.initService();
        }

        if (ttsProvider.isInitialized) {
          setState(() {
            _playingId = item.id;
          });

          // Handle voice selection for Piper
          String? voiceToUse;
          if (ttsProvider.activeEngine == 'Piper') {
            // Check if we already selected a voice for this item
            if (_selectedVoiceByItem.containsKey(item.id)) {
              voiceToUse = _selectedVoiceByItem[item.id];
            } else {
              // First time: randomly select between male and female voice
              final random = math.Random();
              final useMaleVoice = random.nextBool(); // 50/50 chance

              voiceToUse = useMaleVoice
                  ? ttsProvider.defaultMaleVoice
                  : ttsProvider.defaultFemaleVoice;

              // Cache the selected voice
              if (voiceToUse != null) {
                _selectedVoiceByItem[item.id] = voiceToUse;
              }
            }

            // Use the selected voice
            if (voiceToUse != null) {
              final gender =
                  voiceToUse.contains('male') && !voiceToUse.contains('female')
                      ? 'male'
                      : 'female';
              await ttsProvider.speakWithGender(correctText, gender: gender);
            } else {
              await ttsProvider.speakWithGender(correctText);
            }
          } else {
            // System TTS: just speak normally
            await ttsProvider.speakWithGender(correctText);
          }

          // Reset playing state after completion
          if (mounted) {
            setState(() {
              _playingId = null;
            });
          }
        }
      } catch (e) {
        debugPrint('Error playing TTS: $e');
        setState(() {
          _playingId = null;
        });
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

    // Track which words are correct for auto-fill on retry
    final correctWordsMap = <int, bool>{};
    final newWordInputs = Map<int, String>.from(state.wordInputs);

    for (var i = 0; i < words.length; i++) {
      final input = state.wordInputs[i] ?? '';
      final correct = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final user = input.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

      final isCorrect = user == correct;
      correctWordsMap[i] = isCorrect;

      // Auto-fill correct words for next attempt
      if (isCorrect && !allCorrect) {
        newWordInputs[i] = words[i]; // Keep the correct word
      }
    }

    setState(() {
      _itemStates[item.id] = state.copyWith(
        score: score,
        passed: allCorrect,
        attempts: state.attempts + 1,
        correctWords: correctWordsMap,
        wordInputs: allCorrect ? state.wordInputs : newWordInputs,
      );
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
        // 1. Instruction (Hidden)
        // if (widget.quiz.instruction.isNotEmpty) ...

        // 2. Card Area
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            itemCount: dictations.length,
            itemBuilder: (context, index) {
              final item = dictations[index];
              final state = _itemStates[item.id] ?? _DictationItemState();
              final correctText = item.transcript ?? item.text ?? '';
              final words = correctText.trim().split(RegExp(r'\s+'));

              // Check completion
              var allFilled = true;
              for (var i = 0; i < words.length; i++) {
                final w = words[i];
                final input = state.wordInputs[i] ?? '';
                if (input.length != w.length) {
                  allFilled = false;
                  break;
                }
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Stack(
                  children: [
                    // Main Card Container
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
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
                            // HEADER
                            _buildCardHeader(
                              context,
                              appColors,
                              dictations,
                              item,
                              index,
                            ),
                            Divider(
                              height: 1,
                              color: appColors.border.withValues(alpha: 0.5),
                            ),

                            // BODY
                            Expanded(
                              child: Stack(
                                children: [
                                  // Speed & Attempt Info
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Text(
                                      'Attempt ${state.attempts} / 3',
                                      style: TextStyle(
                                        color: appColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Score
                                          if (state.attempts > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 24),
                                              child: Text(
                                                '${state.score}%',
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: state.score >= 80
                                                      ? Colors.yellow[700]
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
                                                words.length, (idx) {
                                              final word = words[idx];
                                              final input =
                                                  state.wordInputs[idx] ?? '';

                                              // Create focus nodes if not exists
                                              if (!_focusNodesByItem
                                                  .containsKey(item.id)) {
                                                _focusNodesByItem[item.id] =
                                                    List.generate(
                                                  words.length,
                                                  (_) => FocusNode(),
                                                );
                                              }

                                              final focusNodes =
                                                  _focusNodesByItem[item.id]!;
                                              final nextFocusNode =
                                                  idx < words.length - 1
                                                      ? focusNodes[idx + 1]
                                                      : null;

                                              // Check if this word is already correct
                                              final isCorrect =
                                                  state.correctWords[idx] ??
                                                      false;

                                              return _WordInput(
                                                index: idx,
                                                correctWord: word,
                                                currentInput: input,
                                                showColors:
                                                    state.attempts > 0 ||
                                                        state.passed,
                                                isCorrect: isCorrect,
                                                enabled:
                                                    !state.passed && !isCorrect,
                                                appColors: appColors,
                                                nextFocusNode: nextFocusNode,
                                                onChanged: (val) {
                                                  final newInputs =
                                                      Map<int, String>.from(
                                                    state.wordInputs,
                                                  );
                                                  newInputs[idx] = val;
                                                  setState(() {
                                                    _itemStates[item.id] =
                                                        state.copyWith(
                                                      wordInputs: newInputs,
                                                    );
                                                  });
                                                },
                                              );
                                            }),
                                          ),

                                          // Play Button in body
                                          if (!state.passed && !allFilled)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 32),
                                              child: GestureDetector(
                                                onTap: () => _playAudio(item),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    color: _playingId == item.id
                                                        ? appColors.primary
                                                            .withValues(
                                                                alpha: 0.15)
                                                        : Colors.grey
                                                            .withValues(
                                                                alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.volume_up,
                                                    color: _playingId == item.id
                                                        ? appColors.primary
                                                        : Colors.grey,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // IPA and Translation (shown when passed)
                                          if (state.passed) ...[
                                            const SizedBox(height: 32),
                                            if (item.ipa != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  item.ipa!,
                                                  style: TextStyle(
                                                    color: appColors.primary,
                                                    fontSize: 16,
                                                    fontFamily: 'NotoSans',
                                                  ),
                                                ),
                                              ),
                                            if (item.translate != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                  item.translate!,
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
                    // Footer
                    if (state.passed || (allFilled && state.attempts < 3)) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildFooterActions(
                              item,
                              state,
                              appColors,
                              allFilled,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions(
    DictationItem item,
    _DictationItemState state,
    AppColorsExtension appColors,
    bool allFilled,
  ) {
    if (state.passed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.primary.withValues(alpha: 0.15),
              foregroundColor: appColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: widget.onNext,
            child: const Text('Next',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (!state.passed && allFilled && state.attempts < 3) {
      return ElevatedButton(
        onPressed: () => _checkAnswer(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          state.attempts == 0 ? 'Check Answer' : 'Retry',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Header Builder Logic extracted from multiple_choice.dart
  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<DictationItem> items,
    DictationItem currentItem,
    int index,
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
            '${index + 1} / ${items.length}',
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
    required this.showColors,
    required this.isCorrect,
    required this.enabled,
    required this.appColors,
    required this.onChanged,
    this.nextFocusNode,
  });

  final int index;
  final String correctWord;
  final String currentInput;
  final bool showColors;
  final bool isCorrect;
  final bool enabled;
  final AppColorsExtension appColors;
  final ValueChanged<String> onChanged;
  final FocusNode? nextFocusNode; // Focus node of next input

  @override
  State<_WordInput> createState() => _WordInputState();
}

class _WordInputState extends State<_WordInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentInput);
    _focusNode = FocusNode();
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
    _focusNode.dispose();
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
            ),
            child: Row(
              children: List.generate(widget.correctWord.length, (i) {
                final hideDash = i < widget.currentInput.length;

                return Container(
                  width: 10,
                  height: 2,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: hideDash
                        ? Colors.transparent
                        : widget.appColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),

          // Character Display Layer (with colors)
          if (widget.showColors && widget.currentInput.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 0,
              child: Row(
                children: List.generate(widget.currentInput.length, (i) {
                  final inputChar = widget.currentInput[i].toLowerCase();
                  final correctChar = i < widget.correctWord.length
                      ? widget.correctWord[i].toLowerCase()
                      : '';

                  // Determine color for this character
                  final charColor = inputChar == correctChar
                      ? widget.appColors.primary
                      : Colors.red;

                  return Container(
                    width: 12,
                    alignment: Alignment.center,
                    child: Text(
                      widget.currentInput[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: charColor,
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Input Layer (Top) - transparent when showing colors
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (val) {
              if (val.length <= widget.correctWord.length) {
                widget.onChanged(val);

                if (val.length == widget.correctWord.length &&
                    widget.nextFocusNode != null) {
                  Future.delayed(const Duration(milliseconds: 50), () {
                    widget.nextFocusNode?.requestFocus();
                  });
                }
              }
            },
            inputFormatters: [
              LengthLimitingTextInputFormatter(widget.correctWord.length),
            ],
            enabled: widget.enabled,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              color: widget.showColors
                  ? Colors
                      .transparent // Hide text when showing colored characters
                  : widget.appColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              counterText: '',
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
    this.correctWords = const {}, // Track which words are correct
  });
  final int score;
  final bool passed;
  final int attempts; // Number of times answer was checked
  final Map<int, String> wordInputs;
  final Map<int, bool> correctWords; // Map of word index -> is correct

  _DictationItemState copyWith({
    int? score,
    bool? passed,
    int? attempts,
    Map<int, String>? wordInputs,
    Map<int, bool>? correctWords,
  }) {
    return _DictationItemState(
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      wordInputs: wordInputs ?? this.wordInputs,
      correctWords: correctWords ?? this.correctWords,
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
