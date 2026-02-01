import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  final SpeechToText _speechToText = SpeechToText();

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

  void _initSpeech() async {
    await _speechToText.initialize();
    if (mounted) setState(() {});
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
            _itemStates[key] = _PronunciationDrillItemState(
              score: data['score'] as int? ?? 0,
              bestScore: data['bestScore'] as int? ?? 0,
              passed: data['passed'] as bool? ?? false,
              attempts: data['attempts'] as int? ?? 0,
              transcript: data['transcript'] as String?,
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
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveProgress();
  }

  void _animateToNextQuestion() {
    if (_currentIndex < (widget.quiz.pronunciations?.length ?? 0) - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startRecording(PronunciationItem item) async {
    if (_isRecording) return;

    // Get STT settings from provider
    final sttProvider = context.read<SttSettingProvider>();
    String localeId = 'en_US'; // default

    // Note: VoskModel doesn't have locale field yet, using default
    // In the future, we can add locale field to VoskModel

    await _speechToText.listen(
      onResult: (result) => _onSpeechResult(result, item),
      localeId: localeId,
    );
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording(PronunciationItem item) async {
    if (!_isRecording) return;
    await _speechToText.stop();
    setState(() {
      _isRecording = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result, PronunciationItem item) {
    debugPrint(
        'STT Result: "${result.recognizedWords}" (Final: ${result.finalResult})');
    if (result.finalResult) {
      final transcript = result.recognizedWords;
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
          _saveProgress();
        });
      }
    }
  }

  String _getTextContent(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
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

  void _retryCurrent() {
    final item = widget.quiz.pronunciations![_currentIndex];
    _startRecording(item);
    _saveProgress(); // Save that we are retrying (maybe not strictly needed but safe to persist current index if crashed)
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final drills = widget.quiz.pronunciations ?? [];
    final borderColor = Colors.grey.withValues(alpha: 0.5);

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
            // Instruction
            if (widget.quiz.instruction.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 15, color: appColors.textPrimary),
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

            // Dashed Border Card
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification) {
                    if (notification.overscroll < 0) {
                      widget.onPrev?.call();
                    } else if (notification.overscroll > 0) {
                      widget.onNext?.call();
                    }
                  }
                  return false;
                },
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
                          left: 16, right: 16, bottom: 12),
                      child: Container(
                        width: double.infinity,
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                    bottom: 20,
                                                  ),
                                                  child: Text(
                                                    '${state.bestScore}%',
                                                    style: TextStyle(
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: state.bestScore >=
                                                              80
                                                          ? Colors.green
                                                          : (state.bestScore >=
                                                                  50
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
                                                    color: appColors.primary,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),

                                              // Translation
                                              if (item.translate != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    item.translate!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: appColors
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 15,
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
                                                        .withValues(
                                                            alpha: 0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: appColors.primary
                                                          .withValues(
                                                              alpha: 0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '"${state.transcript}"',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: appColors
                                                          .textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Controls Area (Pushed to bottom of Flex)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                        left: 24,
                                        right: 24,
                                        top: 12,
                                      ),
                                      child: _buildControls(
                                        state,
                                        item,
                                        appColors,
                                        drills,
                                      ),
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
          fontSize: 20,
          fontWeight: FontWeight.normal,
          color: appColors.textPrimary,
          height: 1.5,
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
          fontSize: 20,
          color: appColors.textPrimary,
          height: 1.5,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildControls(
    _PronunciationDrillItemState state,
    PronunciationItem item,
    AppColorsExtension appColors,
    List<PronunciationItem> drills,
  ) {
    // High Score: Retry + Next (Internal to Card)
    if (state.attempts > 0 && state.bestScore >= 50) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Retry Button
          InkWell(
            onTap: _retryCurrent,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: appColors.buttonSecondBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  Icon(Icons.refresh, color: appColors.textSecondary, size: 22),
            ),
          ),

          const SizedBox(width: 24),

          // Next Button (if available) - Inside card logic usually, but we also have absolute button.
          // React code shows: Retry and Next buttons next to each other in logic.
        ],
      );
    }
    // Low Score or No attempts: Show Mic button
    else {
      return InkWell(
        onTap: _isRecording
            ? () => _stopRecording(item)
            : () => _startRecording(item),
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : appColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isRecording ? Colors.red : appColors.primary)
                    .withValues(alpha: 0.3),
                blurRadius: _isRecording ? 12 : 8,
                spreadRadius: _isRecording ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }
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
