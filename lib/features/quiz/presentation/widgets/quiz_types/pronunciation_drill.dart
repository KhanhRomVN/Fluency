import 'dart:async';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';

class PronunciationDrill extends StatefulWidget {
  const PronunciationDrill({
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
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<PronunciationDrill> createState() => _PronunciationDrillState();
}

class _PronunciationDrillState extends State<PronunciationDrill> {
  int _currentIndex = 0;
  bool _isRecording = false;
  SttService? _sttService;
  bool _speechEnabled = false;
  String? _sttError;
  bool _isRetryingItem = false;
  StreamSubscription<String>? _sttStatusSub;
  bool _isPlayingAudio = false;

  // Map<ItemID, State>
  final Map<String, _PronunciationDrillItemState> _itemStates = {};

  int get _firstUnpassedIndex {
    final drills = widget.quiz.pronunciations ?? [];
    return drills.indexWhere((d) => !(_itemStates[d.id]?.passed ?? false));
  }

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  Future<void> _initSpeech() async {
    try {
      debugPrint('PronunciationDrill: Initializing STT (system)...');

      _sttService = SystemSttService();

      final available = await _sttService!.initialize();
      if (available) {
        _sttStatusSub = _sttService!.statusStream.listen((status) {
          if (mounted && (status == 'notListening' || status == 'done')) {
            if (_isRecording) {
              setState(() {
                _isRecording = false;
              });
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          _speechEnabled = available;
          if (!available) {
            _sttError = 'Speech recognition not available on this device';
          }
        });
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('PronunciationDrill Error initializing speech: $e');
      if (mounted) {
        setState(() {
          _speechEnabled = false;
          _sttError = 'Speech recognition not available on this device';
        });
      }
    }
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
            _itemStates[key] = _PronunciationDrillItemState(
              score: data['score'] as int? ?? 0,
              bestScore: data['bestScore'] as int? ?? 0,
              passed: data['passed'] as bool? ?? false,
              attempts: data['attempts'] as int? ?? 0,
              transcript: data['transcript'] as String?,
              attemptResults: (data['attemptResults'] as List?)
                      ?.map((e) => e as bool)
                      .toList() ??
                  [],
            );
          });
        }

        // Find first unpassed item index
        final drills = widget.quiz.pronunciations ?? [];
        int firstUnpassed = 0;
        for (int i = 0; i < drills.length; i++) {
          if (!(_itemStates[drills[i].id]?.passed ?? false)) {
            firstUnpassed = i;
            break;
          }
        }

        final savedIndex =
            progress.data?['currentIndex'] as int? ?? firstUnpassed;

        int indexToUse = savedIndex;

        // Hybrid logic: if we are at the end but have unpassed items, jump back to first unpassed
        if (savedIndex == drills.length - 1 &&
            firstUnpassed != -1 &&
            firstUnpassed < savedIndex) {
          indexToUse = firstUnpassed;
        }

        setState(() {
          _currentIndex = indexToUse;
        });

        // Sync PageView with restored index
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }

        // If quiz is completed, notify parent to show transcript/etc
        if (progress.isCompleted) {
          widget.onCheck?.call();
        }
      }

      // Auto-speak like Flashcard
      if (mounted) {
        final ttsProvider = context.read<TtsProvider>();
        if (!ttsProvider.isInitialized) {
          await ttsProvider.initService();
        }

        if (ttsProvider.isInitialized) {
          _speakCurrentWord();
        }
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('PronunciationDrill Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final quizStateProvider = context.read<QuizStateProvider>();

      // Serialize states
      final statesMap = _itemStates.map((key, value) {
        return MapEntry(key, {
          'score': value.score,
          'bestScore': value.bestScore,
          'passed': value.passed,
          'attempts': value.attempts,
          'transcript': value.transcript,
          'attemptResults': value.attemptResults,
        });
      });

      final totalItems = widget.quiz.pronunciations?.length ?? 0;
      // Completed if passed (correct) OR attempts > 0 (tried)
      final completedItems =
          _itemStates.values.where((s) => s.attempts >= 3 || s.passed).length;
      final correctItems = _itemStates.values.where((s) => s.passed).length;

      await quizStateProvider.saveQuizProgress(
        lessonId: widget.lessonId,
        quizId: widget.quizId,
        quizType: 'pronunciation-drill',
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
      debugPrint('PronunciationDrill Error saving progress: $e');
    }
  }

  @override
  void dispose() {
    _sttStatusSub?.cancel();
    _pageController.dispose();
    _sttService?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isRetryingItem = false;
    });
    _saveProgress();
    _speakCurrentWord();
  }

  Future<void> _speakCurrentWord() async {
    if (_isPlayingAudio) return;
    if (mounted) setState(() => _isPlayingAudio = true);
    try {
      final ttsProvider = context.read<TtsProvider>();
      if (!ttsProvider.isInitialized) {
        await ttsProvider.initService();
      }

      final item = (widget.quiz.pronunciations ?? [])[_currentIndex];
      final text = _getTextContent(item.text);

      if (text.isNotEmpty) {
        await ttsProvider.ttsService?.speak(text);
        await Future<void>.delayed(const Duration(
            milliseconds:
                1500)); // Ensure UI stays mapped to playing status even if TTS is too fast
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('PronunciationDrill Error speaking word: $e');
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  String _getTextContent(String? html) {
    if (html == null) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
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

  void _startRecording(PronunciationItem item) async {
    if (_isRecording || !_speechEnabled || _sttService == null) return;

    // Get STT settings from provider
    String localeId = 'en_US'; // default

    try {
      await _sttService!.startListening(
        onResult: (text, isFinal) => _onSpeechResult(text, isFinal, item),
        localeId: localeId,
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('Error starting STT: $e');
    }
  }

  void _stopRecording(PronunciationItem item) async {
    if (!_isRecording || _sttService == null) return;
    await _sttService!.stopListening();
    setState(() {
      _isRecording = false;
    });
  }

  void _onSpeechResult(String text, bool isFinal, PronunciationItem item) {
    debugPrint('STT Result: "$text" (Final: $isFinal)');

    // For System STT, we define "final" by the callback
    // For other STT services, similar logic.
    // If it's final, we process score.

    if (isFinal) {
      final transcript = text;
      debugPrint('STT Final Transcript for ${item.id}: "$transcript"');
      final targetText = _getTextContent(item.text);
      final score = _calculateScore(transcript, targetText);
      final passed = score >= 60;

      if (mounted) {
        setState(() {
          _isRecording = false;
          final current =
              _itemStates[item.id] ?? _PronunciationDrillItemState();
          final newAttemptResults = List<bool>.from(current.attemptResults)
            ..add(passed);

          _itemStates[item.id] = current.copyWith(
            score: score,
            bestScore: score > current.bestScore ? score : current.bestScore,
            passed: passed || current.passed,
            attempts: current.attempts + 1,
            transcript: transcript,
            attemptResults: newAttemptResults,
          );
          _isRetryingItem = false;

          // Play sound effect
          if (mounted) {
            final soundProvider = context.read<SoundEffectProvider>();
            if (passed) {
              soundProvider.playCorrect();
            } else {
              soundProvider.playWrong();
            }
          }

          _saveProgress();
        });
      }
    }
  }

  int _calculateScore(String spoken, String target) {
    final spokenLower = spoken.toLowerCase().trim();
    final targetLower = target.toLowerCase().trim();

    if (spokenLower == targetLower) return 100;

    final spokenWords = spokenLower.split(RegExp(r'\s+'));
    final targetWords = targetLower.split(RegExp(r'\s+'));

    var matches = 0;
    for (final word in targetWords) {
      if (spokenWords.any((sw) => sw.contains(word) || word.contains(sw))) {
        matches++;
      }
    }

    return ((matches / targetWords.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final drills = widget.quiz.pronunciations ?? [];

    if (drills.isEmpty) {
      return Center(
        child: Text(
          'No pronunciation drills available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentItem = drills[_currentIndex];
    final currentState =
        _itemStates[currentItem.id] ?? _PronunciationDrillItemState();

    // Calculate completed count
    final completedCount = _itemStates.values.where((s) => s.passed).length;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
// Instruction removed

            // Dashed Border Card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const ClampingScrollPhysics(),
                itemCount: drills.length,
                itemBuilder: (context, index) {
                  final item = drills[index];
                  final state =
                      _itemStates[item.id] ?? _PronunciationDrillItemState();

                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 12, top: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          // Content (Flex to fill available space)
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Score Display
                                          if (state.attempts > 0 &&
                                              !_isRecording)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 24,
                                              ),
                                              child: SizedBox(
                                                width: 80,
                                                height: 80,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 80,
                                                      height: 80,
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: state.bestScore /
                                                            100,
                                                        strokeWidth: 8,
                                                        backgroundColor:
                                                            appColors
                                                                .textSecondary
                                                                .withValues(
                                                                    alpha:
                                                                        0.25),
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          _getScoreColor(
                                                              state.bestScore,
                                                              state.attempts,
                                                              appColors),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${state.bestScore}%',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: _getScoreColor(
                                                            state.bestScore,
                                                            state.attempts,
                                                            appColors),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                          // Attempt Tracker (Dots)
                                          _buildAttemptUI(state, appColors),
                                          const SizedBox(height: 24),

                                          // Main Text
                                          _buildFormattedText(
                                            context,
                                            item.text,
                                            state.passed,
                                            appColors,
                                          ),

                                          const SizedBox(height: 12),

                                          // IPA
                                          if (item.ipa != null &&
                                              item.ipa!.isNotEmpty)
                                            Text(
                                              item.ipa!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _isRecording
                                                    ? Colors.amber
                                                    : _getScoreColor(
                                                        state.bestScore,
                                                        state.attempts,
                                                        appColors),
                                                fontSize: 18,
                                                fontFamily: 'NotoSans',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),

                                          // Translation
                                          if (item.translate != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                item.translate!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      appColors.textSecondary,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),

                                          // Transcript (Feedback)
                                          if (state.transcript != null &&
                                              !_isRecording)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(height: 24),
                                                Text(
                                                  'You said:',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        appColors.textSecondary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: _getScoreColor(
                                                            state.bestScore,
                                                            state.attempts,
                                                            appColors)
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: _getScoreColor(
                                                              state.bestScore,
                                                              state.attempts,
                                                              appColors)
                                                          .withValues(
                                                              alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    state.transcript!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: _getScoreColor(
                                                          state.bestScore,
                                                          state.attempts,
                                                          appColors),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Footer Actions
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              children: [
                                if (_sttError != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.red
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'This device does not support speech-to-text service.',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                _buildFooterActions(
                                  state,
                                  item,
                                  appColors,
                                  drills,
                                  index,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (!_isRecording)
          Positioned(
            top: 16,
            left: 16,
            child: InkWell(
              onTap: _isPlayingAudio ? null : _speakCurrentWord,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (_isPlayingAudio
                          ? appColors.primary
                          : appColors.textSecondary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: _isPlayingAudio
                      ? appColors.primary
                      : appColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        // Top Right: Badge
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: appColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_currentIndex + 1}/${drills.length}',
              style: TextStyle(
                color: appColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Custom formatted text builder to handle <p hide='true'> and other tags
  Widget _buildFormattedText(
    BuildContext context,
    String content,
    bool isRevealed,
    AppColorsExtension appColors,
  ) {
    // Check if simple text without tags
    if (!content.contains('<p')) {
      return Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: appColors.textPrimary,
          height: 1.3,
        ),
      );
    }

    final spans = <InlineSpan>[];
    final regex = RegExp(
      '(<p[^>]*>)(.*?)(</p>)',
      caseSensitive: false,
    ); // Simple tag parser

    var lastIndex = 0;
    // We iterate matches. If text is between tags, we add it too.
    for (final match in regex.allMatches(content)) {
      if (match.start > lastIndex) {
        final text = content.substring(lastIndex, match.start);
        if (text.trim().isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
      }

      final startTag = match.group(1)!;
      final innerText = match.group(2)!;

      // Check attributes
      final isHidden =
          startTag.contains("hide='true'") || startTag.contains('hide="true"');

      if (isHidden && !isRevealed) {
        // Render Gap (Dashed lines)
        spans.add(
          TextSpan(
            text: '_______', // Placeholder for gap
            style: TextStyle(
              color: appColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2, // Space out dashes
            ),
          ),
        );
      } else {
        // Render Text (Normal or Revealed)
        spans.add(
          TextSpan(
            text: innerText,
            style: TextStyle(
              color: isHidden
                  ? appColors.primary
                  : appColors.textPrimary, // Highlight if it was hidden
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final text = content.substring(lastIndex);
      if (text.trim().isNotEmpty) {
        spans.add(TextSpan(text: text));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: appColors.textPrimary,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFooterActions(
    _PronunciationDrillItemState state,
    PronunciationItem item,
    AppColorsExtension appColors,
    List<PronunciationItem> drills,
    int index,
  ) {
    if ((state.passed || state.attempts >= 3) && !_isRetryingItem) {
      return Row(
        children: [
          // Retry button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _itemStates[item.id] = _PronunciationDrillItemState();
                _isRetryingItem = true;
              });
              _saveProgress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors.textSecondary.withValues(alpha: 0.15),
              foregroundColor: appColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          // Next Button
          if (widget.onNext != null)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final isLast = index == drills.length - 1;
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
                    _handleNext(drills.length);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.15),
                  foregroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                    index == drills.length - 1
                        ? (_firstUnpassedIndex != -1
                            ? 'Review Uncompleted'
                            : (widget.finalActionText ?? 'Finish'))
                        : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mic Button (only show if not passed/max attempts or retrying)
        _buildMicButton(state, item, appColors),
      ],
    );
  }

  Widget _buildAttemptUI(
    _PronunciationDrillItemState state,
    AppColorsExtension appColors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final results = state.attemptResults;
        Color color = appColors.textSecondary.withValues(alpha: 0.3);
        if (index < results.length) {
          color = results[index] ? Colors.green : Colors.red;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Color _getScoreColor(int score, int attempts, AppColorsExtension appColors) {
    if (attempts == 0) return appColors.buttonBg;
    if (score <= 20) return Colors.red;
    if (score <= 40) return Colors.orange;
    if (score <= 60) return Colors.amber;
    if (score <= 80) return Colors.cyan;
    return Colors.green;
  }

  Widget _buildMicButton(
    _PronunciationDrillItemState state,
    PronunciationItem item,
    AppColorsExtension appColors,
  ) {
    if (_sttError != null) return const SizedBox.shrink();
    final bool canRecord = _speechEnabled &&
        _sttError == null &&
        !state.passed &&
        state.attempts < 3;

    final scoreColor =
        _getScoreColor(state.bestScore, state.attempts, appColors);
    final micColor = _isRecording ? Colors.amber : scoreColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: canRecord
              ? (_isRecording
                  ? () => _stopRecording(item)
                  : () => _startRecording(item))
              : null,
          borderRadius: BorderRadius.circular(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: micColor.withValues(alpha: _isRecording ? 0.3 : 0.15),
              shape: BoxShape.circle,
            ),
            child: Opacity(
              opacity: canRecord ? 1.0 : 0.4,
              child: Icon(
                Icons.mic,
                color: micColor,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording ? 'Recording...' : 'Tap to record',
          style: TextStyle(
            color: _isRecording ? Colors.amber : appColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PronunciationDrillItemState {
  _PronunciationDrillItemState({
    this.score = 0,
    this.bestScore = 0,
    this.passed = false,
    this.attempts = 0,
    this.transcript,
    this.attemptResults = const [],
  });
  final int score;
  final int bestScore;
  final bool passed;
  final int attempts;
  final String? transcript;
  final List<bool> attemptResults;

  _PronunciationDrillItemState copyWith({
    int? score,
    int? bestScore,
    bool? passed,
    int? attempts,
    String? transcript,
    List<bool>? attemptResults,
  }) {
    return _PronunciationDrillItemState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      transcript: transcript ?? this.transcript,
      attemptResults: attemptResults ?? this.attemptResults,
    );
  }
}
