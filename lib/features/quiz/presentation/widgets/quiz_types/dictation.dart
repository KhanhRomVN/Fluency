import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:provider/provider.dart';

class Dictation extends StatefulWidget {
  const Dictation({
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
  State<Dictation> createState() => _DictationState();
}

class _DictationState extends State<Dictation> {
  int _currentIndex = 0;
  final Map<String, _DictationItemState> _itemStates = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;
  final Map<String, Map<String, FocusNode>> _focusNodesByItem = {};
  final Map<String, String> _selectedVoiceByItem = {};

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
    try {
      final quizStateProvider = context.read<QuizStateProvider>();
      final progress = await quizStateProvider.loadQuizProgress(
        widget.lessonId,
        widget.quizId,
      );

      if (progress != null && mounted) {
        final savedStates =
            progress.data?['itemStates'] as Map<String, dynamic>?;
        if (savedStates != null) {
          savedStates.forEach((key, value) {
            final data = value as Map<String, dynamic>;
            _itemStates[key] = _DictationItemState(
              score: data['score'] as int? ?? 0,
              passed: data['passed'] as bool? ?? false,
              attempts: data['attempts'] as int? ?? 0,
              gapInputs: (data['gapInputs'] as Map<String, dynamic>? ??
                      data['wordInputs'] as Map<String, dynamic>? ??
                      {})
                  .map((k, v) => MapEntry(k, v as String)),
              correctGaps: (data['correctGaps'] as Map<String, dynamic>? ??
                      data['correctWords'] as Map<String, dynamic>? ??
                      {})
                  .map((k, v) => MapEntry(k, v as bool)),
            );
          });
        }

        // Find first unpassed item index
        final dictations = widget.quiz.dictations ?? [];
        int firstUnpassed = 0;
        for (int i = 0; i < dictations.length; i++) {
          if (!(_itemStates[dictations[i].id]?.passed ?? false)) {
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
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('Dictation: Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final quizStateProvider = context.read<QuizStateProvider>();

      // Serialize states
      final statesMap = _itemStates.map((key, value) {
        return MapEntry(key, {
          'score': value.score,
          'passed': value.passed,
          'attempts': value.attempts,
          'gapInputs': value.gapInputs,
          'correctGaps': value.correctGaps,
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
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('Dictation: Error saving progress: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    // Dispose all focus nodes
    for (final nodeMap in _focusNodesByItem.values) {
      for (final node in nodeMap.values) {
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
    final rawText = item.transcript ?? item.text ?? '';
    final correctText = _cleanTextForSpeech(rawText);
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
      } catch (e, s) {
        MonitoringService.captureError(e, stackTrace: s);
        debugPrint('Error playing TTS: $e');
        setState(() {
          _playingId = null;
        });
      }
    }
  }

  String _cleanTextForSpeech(String text) {
    if (text.isEmpty) return '';

    // 1. Replace <gap id='...'>content</gap> with content
    var cleaned = text.replaceAllMapped(
      RegExp(r"<gap id='[^']*?'>(.*?)</gap>"),
      (match) => match.group(1) ?? '',
    );

    // 2. Remove other tags: <gap .../>, </gap ...>, <p ...>, </p>, <br/>, <b>, </b>, etc.
    cleaned = cleaned.replaceAll(RegExp(r'</?[a-zA-Z][^>]*>'), '');

    // 3. Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  Map<String, String> _getGapsFromText(String text) {
    if (text.isEmpty) return {};
    final gaps = <String, String>{};
    final regex = RegExp("<gap id='(.*?)'>(.*?)</gap>");
    final matches = regex.allMatches(text);
    for (final match in matches) {
      final id = match.group(1);
      final word = match.group(2);
      if (id != null && word != null) {
        gaps[id] = word;
      }
    }

    // Fallback: if no gaps found, split text into words and treat each as a gap
    if (gaps.isEmpty) {
      final words = text.trim().split(RegExp(r'\s+'));
      for (var i = 0; i < words.length; i++) {
        gaps['g$i'] = words[i];
      }
    }
    return gaps;
  }

  void _checkAnswer(DictationItem item) {
    if (_itemStates[item.id]?.passed ?? false) return;

    final state = _itemStates[item.id] ?? _DictationItemState();
    final gaps = _getGapsFromText(item.text ?? item.transcript ?? '');
    if (gaps.isEmpty) return;

    var correctCount = 0;
    var allCorrect = true;

    final correctGapsMap = <String, bool>{};
    final newGapInputs = Map<String, String>.from(state.gapInputs);

    gaps.forEach((id, correctAnswer) {
      final input = state.gapInputs[id] ?? '';

      // Basic normalization matching original logic
      final correct = correctNorm(correctAnswer);
      final user = correctNorm(input);

      final isCorrect = user == correct;
      correctGapsMap[id] = isCorrect;

      if (isCorrect) {
        correctCount++;
      } else {
        allCorrect = false;
      }

      // Auto-fill correct gaps for next attempt
      if (isCorrect && !allCorrect) {
        newGapInputs[id] = correctAnswer;
      }
    });

    final score = (correctCount / gaps.length * 100).round();

    setState(() {
      _itemStates[item.id] = state.copyWith(
        score: score,
        passed: allCorrect,
        attempts: state.attempts + 1,
        correctGaps: correctGapsMap,
        gapInputs: allCorrect ? state.gapInputs : newGapInputs,
      );

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (allCorrect) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }

      _saveProgress();
    });
  }

  void _handleNext(int totalItems) {
    if (_currentIndex < totalItems - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNext?.call();
    }
  }

  void _handleRetry(DictationItem item) {
    final state = _itemStates[item.id];
    if (state == null) return;

    final newGapInputs = Map<String, String>.from(state.gapInputs);
    final newCorrectGaps = Map<String, bool>.from(state.correctGaps);

    state.correctGaps.forEach((id, isCorrect) {
      if (!isCorrect) {
        newGapInputs[id] = ''; // Clear incorrect ones
        newCorrectGaps.remove(id); // Stop showing red
      }
    });

    setState(() {
      _itemStates[item.id] = state.copyWith(
        gapInputs: newGapInputs,
        correctGaps: newCorrectGaps,
      );
    });

    _saveProgress();
  }

  String correctNorm(String text) {
    return text.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
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
              final gaps = _getGapsFromText(item.text ?? item.transcript ?? '');
              var allFilled = gaps.isNotEmpty;
              gaps.forEach((id, correctAnswer) {
                final input = state.gapInputs[id] ?? '';
                if (input.length != correctAnswer.length) {
                  allFilled = false;
                }
              });

              final borderColor = state.passed
                  ? Colors.green
                  : (state.attempts > 0
                      ? Colors.red
                      : Colors.grey.withValues(alpha: 0.5));

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
                                          // Word Inputs (Using RichTextParser)
                                          _buildDictationContent(
                                            context,
                                            item,
                                            state,
                                            appColors,
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
                                            if (item.ipa != null)
                                              Text(
                                                item.ipa!,
                                                style: TextStyle(
                                                  color: appColors.primary,
                                                  fontSize: 16,
                                                  fontFamily: 'NotoSans',
                                                ),
                                              ),
                                            if (item.translate != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
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
                            if (state.passed ||
                                (allFilled && state.attempts < 3)) ...[
                              Divider(
                                height: 1,
                                color: appColors.border.withValues(alpha: 0.5),
                              ),
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
                                      index,
                                      dictations.length,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<DictationItem> items,
    DictationItem currentItem,
    int index,
  ) {
    final state = _itemStates[currentItem.id] ?? _DictationItemState();
    final isPassed = state.passed;

    // Check total completed count
    final completedCount =
        _itemStates.values.where((s) => s.attempts > 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Item Counter
          Text(
            '${index + 1} / ${items.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
            ),
          ),

          Row(
            children: [
              // Score badge (shown if passed)
              if (isPassed)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${state.score} pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: appColors.primary,
                    ),
                  ),
                ),

              // Circular Segmented Progress
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(32, 32),
                      painter: _SegmentedProgressPainter(
                        totalSegments: items.length,
                        segmentStates: List.generate(items.length, (idx) {
                          final item = items[idx];
                          final s =
                              _itemStates[item.id] ?? _DictationItemState();
                          if (s.attempts == 0) return 0;
                          return s.passed ? 1 : 2;
                        }),
                        primaryColor: appColors.primary,
                        errorColor: Colors.red,
                        emptyColor: appColors.border,
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

  Widget _buildFooterActions(
    DictationItem item,
    _DictationItemState state,
    AppColorsExtension appColors,
    bool allFilled,
    int index,
    int totalItems,
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
            onPressed: () => _handleNext(totalItems),
            child: Text(index < totalItems - 1 ? 'Next' : 'Finish',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (!state.passed && allFilled && state.attempts < 3) {
      final hasErrors = state.correctGaps.values.any((v) => v == false);

      return ElevatedButton(
        onPressed:
            hasErrors ? () => _handleRetry(item) : () => _checkAnswer(item),
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
          !hasErrors ? 'Check Answer' : 'Retry(${state.attempts})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDictationContent(
    BuildContext context,
    DictationItem item,
    _DictationItemState state,
    AppColorsExtension appColors,
  ) {
    final text = item.text ?? item.transcript ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final gapsMap = _getGapsFromText(text);
    final gapIds = gapsMap.keys.toList();

    final spans = RichTextParser.buildTextSpans(
      context,
      text,
      isQuestion: true,
      onGapFound: (gapId) {
        final idx = gapIds.indexOf(gapId);
        final nextGapId = idx < gapIds.length - 1 ? gapIds[idx + 1] : null;

        final correctWord = gapsMap[gapId] ?? '';
        final currentInput = state.gapInputs[gapId] ?? '';
        final isCorrect = state.correctGaps[gapId] ?? false;

        // Create focus nodes if not exists
        if (!_focusNodesByItem.containsKey(item.id)) {
          _focusNodesByItem[item.id] = {};
        }
        final itemFocusNodes = _focusNodesByItem[item.id]!;
        if (!itemFocusNodes.containsKey(gapId)) {
          itemFocusNodes[gapId] = FocusNode();
        }

        final nextFocusNode =
            nextGapId != null ? itemFocusNodes[nextGapId] : null;

        return _WordInput(
          index: idx,
          correctWord: correctWord,
          currentInput: currentInput,
          showColors: state.attempts > 0 || state.passed,
          isCorrect: isCorrect,
          enabled: !state.passed && !isCorrect,
          appColors: appColors,
          focusNode: itemFocusNodes[gapId],
          nextFocusNode: nextFocusNode,
          onChanged: (val) {
            final newInputs = Map<String, String>.from(state.gapInputs);
            newInputs[gapId] = val;
            setState(() {
              _itemStates[item.id] = state.copyWith(
                gapInputs: newInputs,
              );
            });
          },
        );
      },
    );

    // If gaps were found, use spans. Otherwise fall back (should be handled by _getGapsFromText fallback)
    // but RichTextParser only handles <gap> tags.
    // So if the text doesn't have gaps, we should handle it specially.
    if (!text.contains('<gap')) {
      // Fallback: wrap everything in a Wrap (old behavior but using _buildDictationContent logic)
      final words = text.trim().split(RegExp(r'\s+'));
      return Wrap(
        spacing: 8,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(words.length, (idx) {
          final gapId = 'g$idx';
          final word = words[idx];
          final input = state.gapInputs[gapId] ?? '';
          final isCorrect = state.correctGaps[gapId] ?? false;

          if (!_focusNodesByItem.containsKey(item.id)) {
            _focusNodesByItem[item.id] = {};
          }
          final itemFocusNodes = _focusNodesByItem[item.id]!;
          if (!itemFocusNodes.containsKey(gapId)) {
            itemFocusNodes[gapId] = FocusNode();
          }

          final nextFocusNode = idx < words.length - 1
              ? (itemFocusNodes['g${idx + 1}'] ??= FocusNode())
              : null;

          return _WordInput(
            index: idx,
            correctWord: word,
            currentInput: input,
            showColors: state.attempts > 0 || state.passed,
            isCorrect: isCorrect,
            enabled: !state.passed && !isCorrect,
            appColors: appColors,
            focusNode: itemFocusNodes[gapId],
            nextFocusNode: nextFocusNode,
            onChanged: (val) {
              final newInputs = Map<String, String>.from(state.gapInputs);
              newInputs[gapId] = val;
              setState(() {
                _itemStates[item.id] = state.copyWith(
                  gapInputs: newInputs,
                );
              });
            },
          );
        }),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        height: 1.8,
        color: appColors.textPrimary,
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
    this.focusNode,
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
  final FocusNode? focusNode;
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
    _focusNode = widget.focusNode ?? FocusNode();
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
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React: width: `${correctWord.length * 12 + 4}px`
    final width = (widget.correctWord.length * 12.0) + 12.0;
    const minWidth = 20.0;

    return Container(
      width: math.max(width, minWidth),
      decoration: BoxDecoration(
        color: widget.appColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                        : widget.appColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),

          // Character Display Layer (with colors)
          if (widget.showColors && widget.currentInput.isNotEmpty)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(
                    bottom: 2), // Match TextField visual baseline
                child: Text.rich(
                  TextSpan(
                    children: List.generate(widget.currentInput.length, (i) {
                      final inputChar = widget.currentInput[i].toLowerCase();
                      final correctChar = i < widget.correctWord.length
                          ? widget.correctWord[i].toLowerCase()
                          : '';
                      final charColor = inputChar == correctChar
                          ? widget.appColors.primary
                          : Colors.red;

                      return TextSpan(
                        text: widget.currentInput[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: charColor,
                        ),
                      );
                    }),
                  ),
                  style: const TextStyle(
                    letterSpacing: 2,
                  ),
                ),
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
              height: 1.2,
              color: widget.showColors
                  ? Colors
                      .transparent // Hide text when showing colored characters
                  : widget.appColors.primary,
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
    this.gapInputs = const {},
    this.correctGaps = const {},
  });
  final int score;
  final bool passed;
  final int attempts;
  final Map<String, String> gapInputs;
  final Map<String, bool> correctGaps;

  _DictationItemState copyWith({
    int? score,
    bool? passed,
    int? attempts,
    Map<String, String>? gapInputs,
    Map<String, bool>? correctGaps,
  }) {
    return _DictationItemState(
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      gapInputs: gapInputs ?? this.gapInputs,
      correctGaps: correctGaps ?? this.correctGaps,
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
