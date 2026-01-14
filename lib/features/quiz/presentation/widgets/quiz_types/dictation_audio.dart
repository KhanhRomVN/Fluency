import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

class DictationAudio extends StatefulWidget {
  const DictationAudio({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<DictationAudio> createState() => _DictationAudioState();
}

class _DictationAudioState extends State<DictationAudio> {
  int _currentIndex = 0;

  // Map<ItemID, State>
  final Map<String, _DictationItemState> _itemStates = {};

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _playingId = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(DictationItem item) async {
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
        debugPrint("Error playing audio: $e");
      }
    }
  }

  void _checkAnswer(DictationItem item) {
    final state = _itemStates[item.id] ?? _DictationItemState();
    final correctText = item.transcript ?? item.text ?? '';
    final words = correctText.trim().split(RegExp(r'\s+'));

    // Check if all words are correct
    bool allCorrect = true;
    int correctCount = 0;

    for (int i = 0; i < words.length; i++) {
      final input = state.wordInputs[i] ?? '';
      final correct = words[i].replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final user = input.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();

      if (user == correct) {
        correctCount++;
      } else {
        allCorrect = false;
      }
    }

    int score = (correctCount / words.length * 100).round();

    setState(() {
      _itemStates[item.id] = state.copyWith(
        score: score,
        passed: allCorrect,
        attempts: state.attempts + 1,
      );
    });
  }

  void _retryCurrent() {
    final item = widget.quiz.dictations![_currentIndex];
    final oldState = _itemStates[item.id] ?? _DictationItemState();
    setState(() {
      _itemStates[item.id] = _DictationItemState();
      // Note: React implementation might clear inputs on retry or keep them?
      // Usually better UX to keep them but reset status.
      // But _DictationItemState default clears everything.
      // Let's clear inputs for a fresh retry as typically implied.
    });
  }

  void _next() {
    if (widget.quiz.dictations != null &&
        _currentIndex < widget.quiz.dictations!.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final dictations = widget.quiz.dictations ?? [];
    final borderColor = Colors.grey.withOpacity(0.5);

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

    // Check if all inputs are filled to length
    bool allFilled = true;
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final input = currentState.wordInputs[i] ?? '';
      if (input.length != w.length) {
        allFilled = false;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instruction
        if (widget.quiz.instruction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DefaultTextStyle(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, color: appColors.textPrimary),
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
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        // Header
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_currentIndex + 1} / ${dictations.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CustomPaint(
                                    painter: _CircularProgressPainter(
                                      progress: (_currentIndex + 1) /
                                          dictations.length,
                                      color: appColors.primary,
                                      trackColor: appColors.border,
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        Divider(
                            height: 1,
                            color: appColors.border.withOpacity(0.5)),

                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Score
                                if (currentState.attempts > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(
                                      '${currentState.score}%',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: currentState.score >= 80
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),

                                // Word Inputs
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children:
                                      List.generate(words.length, (index) {
                                    final word = words[index];
                                    final input =
                                        currentState.wordInputs[index] ?? '';
                                    final isHint =
                                        false; // Logic for hint words if any

                                    // Feedback Logic
                                    Color? textColor;
                                    if (currentState.attempts > 0 ||
                                        currentState.passed) {
                                      final cleanWord = word
                                          .replaceAll(RegExp(r'[^\w]'), '')
                                          .toLowerCase();
                                      final cleanInput = input
                                          .replaceAll(RegExp(r'[^\w]'), '')
                                          .toLowerCase();
                                      if (cleanInput == cleanWord || isHint) {
                                        textColor = appColors.primary;
                                      } else {
                                        textColor = Colors.red;
                                      }
                                    }

                                    return _buildWordInput(
                                      context: context,
                                      index: index,
                                      correctWord: word,
                                      currentInput: input,
                                      textColor: textColor,
                                      enabled: !currentState.passed,
                                      appColors: appColors,
                                      onChanged: (val) {
                                        setState(() {
                                          // Map implementation needs replacement
                                          // Make sure we create a new map instance or modify correctly
                                          final newInputs =
                                              Map<int, String>.from(
                                                  currentState.wordInputs);
                                          newInputs[index] = val;
                                          _itemStates[currentItem.id] =
                                              currentState.copyWith(
                                                  wordInputs: newInputs);
                                        });
                                      },
                                    );
                                  }),
                                ),

                                // Correct Answer Reveal
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
                                      padding: const EdgeInsets.only(top: 8),
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
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        currentItem.translate!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: appColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Bottom Spacer for Buttons
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Buttons

              // Play Button (Bottom Center)
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
                                  .withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: _playingId == currentItem.id
                              ? Border.all(
                                  color: Colors.red.withOpacity(0.3), width: 3)
                              : null,
                        ),
                        child: Icon(
                          Icons.graphic_eq, // Or volume_up
                          color: _playingId == currentItem.id
                              ? Colors.red
                              : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

              // Check / Retry / Next (Bottom Right)
              Positioned(
                bottom: 24,
                right: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!currentState.passed && allFilled)
                      ElevatedButton.icon(
                        onPressed: () => _checkAnswer(currentItem),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                            currentState.attempts == 0 ? "Check" : "Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                        ),
                      ),
                    if (currentState.passed) ...[
                      // Retry Button
                      InkWell(
                        onTap: _retryCurrent,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: appColors.buttonSecondBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.refresh,
                              color: appColors.textSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_currentIndex < dictations.length - 1)
                        InkWell(
                          onTap: _next,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: appColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: appColors.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWordInput({
    required BuildContext context,
    required int index,
    required String correctWord,
    required String currentInput,
    required Color? textColor,
    required bool enabled,
    required AppColorsExtension appColors,
    required ValueChanged<String> onChanged,
  }) {
    // Calculate width approx (font size * chars + padding)
    // Or just let IntrinsicWidth handle it if used, but TextField needs explicit width usually relative to content chars
    final textStyle = TextStyle(
      fontSize: 18,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: textColor ?? appColors.textPrimary,
      letterSpacing: 1.2,
    );

    // Rough calc: average char width ~11px for size 18 monospace
    final width = (correctWord.length * 12.0) + 16.0;

    return SizedBox(
      width: math.max(width, 30.0), // Min width
      child: Column(
        children: [
          TextField(
            controller: TextEditingController(text: currentInput)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: currentInput.length)),
            onChanged: (val) {
              if (val.length <= correctWord.length) {
                onChanged(val);
              }
            },
            enabled: enabled,
            textAlign: TextAlign.center,
            style: textStyle,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              counterText: '',
            ),
            maxLength: correctWord.length,
          ),
          // Custom Underlines (dashes)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(correctWord.length, (i) {
              final hasChar = i < currentInput.length;
              return Container(
                width: 8,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: hasChar
                    ? Colors.transparent
                    : (textColor ??
                        appColors.textSecondary
                            .withOpacity(0.3)), // Hide dash if typed
                // React version hides dash if typed.
              );
            }),
          )
        ],
      ),
    );
  }
}

class _DictationItemState {
  final int score;
  final bool passed;
  final int attempts;
  final Map<int, String> wordInputs;

  _DictationItemState({
    this.score = 0,
    this.passed = false,
    this.attempts = 0,
    this.wordInputs = const {},
  });

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

// Reuse Painters (Move to shared file ideally, but duplicating for now as per prev pattern)

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.gap = 5,
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final Path dashedPath = _dashPath(path, width: 8, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + width < metric.length)
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

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
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
