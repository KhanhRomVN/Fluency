import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  State<PronunciationDrill> createState() => _PronunciationDrillState();
}

class _PronunciationDrillState extends State<PronunciationDrill> {
  int _currentIndex = 0;
  bool _isRecording = false;
  SttService? _sttService;
  bool _speechEnabled = false;

  // Map<ItemID, State>
  final Map<String, _PronunciationDrillItemState> _itemStates = {};

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
    debugPrint('PronunciationDrill: Initializing STT (system)...');

    _sttService = SystemSttService();

    final available = await _sttService!.initialize();
    if (mounted) {
      setState(() {
        _speechEnabled = available;
      });
    }
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      final savedStates = progress.data?['itemStates'] as Map<String, dynamic>?;
      if (savedStates != null) {
        savedStates.forEach((key, value) {
          final data = value as Map<String, dynamic>;
          _itemStates[key] = _PronunciationDrillItemState(
            score: data['score'] as int? ?? 0,
            bestScore: data['bestScore'] as int? ?? 0,
            passed: data['passed'] as bool? ?? false,
            attempts: data['attempts'] as int? ?? 0,
            transcript: data['transcript'] as String?,
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

      setState(() {
        _currentIndex = firstUnpassed;
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
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Serialize states
    final statesMap = _itemStates.map((key, value) {
      return MapEntry(key, {
        'score': value.score,
        'bestScore': value.bestScore,
        'passed': value.passed,
        'attempts': value.attempts,
        'transcript': value.transcript,
      });
    });

    final totalItems = widget.quiz.pronunciations?.length ?? 0;
    // Completed if passed (correct) OR attempts > 0 (tried)
    final completedItems =
        _itemStates.values.where((s) => s.attempts > 0 || s.passed).length;
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sttService?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveProgress();
    _speakCurrentWord();
  }

  Future<void> _speakCurrentWord() async {
    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isInitialized) {
      await ttsProvider.initService();
    }

    final item = (widget.quiz.pronunciations ?? [])[_currentIndex];
    final text = _getTextContent(item.text);

    if (text.isNotEmpty) {
      await ttsProvider.ttsService?.speak(text);
    }
  }

  String _getTextContent(String? html) {
    if (html == null) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
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
    } catch (e) {
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
          _itemStates[item.id] = current.copyWith(
            score: score,
            bestScore: score > current.bestScore ? score : current.bestScore,
            passed: passed || current.passed,
            attempts: current.attempts + 1,
            transcript: transcript,
          );

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

                  final borderColor = state.passed
                      ? Colors.green
                      : (state.attempts > 0
                          ? Colors.red
                          : Colors.grey.withValues(alpha: 0.5));
                  return Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 24, top: 24),
                    child: Container(
                      width: double.infinity,
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
                            // Header inside Card (Counter + Progress)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Counter
                                  Text(
                                    '${index + 1} / ${drills.length}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: appColors.textPrimary,
                                    ),
                                  ),
                                  // Progress Circle
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CustomPaint(
                                      painter: _CircularProgressPainter(
                                        progress: drills.isEmpty
                                            ? 0
                                            : completedCount / drills.length,
                                        color: appColors.primary,
                                        trackColor: appColors.border,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$completedCount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: appColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: appColors.border.withValues(alpha: 0.5),
                            ),

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
                                            if (state.attempts > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 20,
                                                ),
                                                child: Text(
                                                  '${state.bestScore}%',
                                                  style: TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: state.bestScore >= 80
                                                        ? Colors.green
                                                        : (state.bestScore >= 50
                                                            ? Colors.orange
                                                            : Colors.red),
                                                  ),
                                                ),
                                              ),

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
                                                  color:
                                                      appColors.textSecondary,
                                                  fontSize: 18,
                                                  fontFamily: 'NotoSans',
                                                ),
                                              ),

                                            // Translation
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
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),

                                            // Transcript (Feedback)
                                            if (state.transcript != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 24),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: appColors.primary
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: appColors.primary
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  '"${state.transcript}"',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        appColors.textSecondary,
                                                    fontSize: 14,
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
                            ),
                            Divider(
                              height: 1,
                              color: appColors.border.withValues(alpha: 0.5),
                            ),

                            // Footer Actions
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildFooterActions(
                                    state,
                                    item,
                                    appColors,
                                    drills,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
              fontWeight: FontWeight.normal,
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
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mic Button
        _buildMicButton(state, item, appColors),

        // Next Button (if passed)
        if (state.passed && widget.onNext != null) ...[
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: widget.onNext,
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
            child: const Text('Next',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildMicButton(
    _PronunciationDrillItemState state,
    PronunciationItem item,
    AppColorsExtension appColors,
  ) {
    return InkWell(
      onTap: _isRecording
          ? () => _stopRecording(item)
          : () => _startRecording(item),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isRecording
              ? appColors.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: _isRecording ? appColors.primary : Colors.grey,
          size: 24,
        ),
      ),
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
  });
  final int score;
  final int bestScore;
  final bool passed;
  final int attempts;
  final String? transcript;

  _PronunciationDrillItemState copyWith({
    int? score,
    int? bestScore,
    bool? passed,
    int? attempts,
    String? transcript,
  }) {
    return _PronunciationDrillItemState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      transcript: transcript ?? this.transcript,
    );
  }
}

// Dashed Border Painter
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

// Circular Progress Painter
class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    // Rotate to start from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
