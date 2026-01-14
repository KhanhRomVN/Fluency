import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PronunciationDrill extends StatefulWidget {
  const PronunciationDrill({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<PronunciationDrill> createState() => _PronunciationDrillState();
}

class _PronunciationDrillState extends State<PronunciationDrill> {
  int _currentIndex = 0;
  bool _isRecording = false;

  // Map<ItemID, State>
  final Map<String, _PronunciationDrillItemState> _itemStates = {};

  void _startRecording(PronunciationItem item) {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
    });
    // Mock recording duration
    Future.delayed(const Duration(seconds: 2), () {
      _stopRecording(item);
    });
  }

  void _stopRecording(PronunciationItem item) {
    if (!_isRecording) return;

    // Mock result
    final score = (DateTime.now().millisecond % 40) + 60; // 60-99
    final passed = score >= 60;

    if (mounted) {
      setState(() {
        _isRecording = false;
        final current = _itemStates[item.id] ?? _PronunciationDrillItemState();
        _itemStates[item.id] = current.copyWith(
          score: score,
          bestScore: score > current.bestScore ? score : current.bestScore,
          passed: passed || current.passed,
          attempts: current.attempts + 1,
          transcript: item.text, // Mock transcript match
        );
      });
    }
  }

  void _retryCurrent() {
    final item = widget.quiz.pronunciations![_currentIndex];
    _startRecording(item);
  }

  void _next() {
    if (widget.quiz.pronunciations != null &&
        _currentIndex < widget.quiz.pronunciations!.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  // Simulate Test Button Action (from React's bottom-right button)
  void _simulateTest() {
    // For now, it functions as Next or a helper to pass
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final drills = widget.quiz.pronunciations ?? [];
    final borderColor = Colors.grey.withOpacity(0.5);

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                                horizontal: 24, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Counter
                                Text(
                                  '${_currentIndex + 1} / ${drills.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.normal, // Fixed: Not bold
                                    color: appColors.textPrimary,
                                  ),
                                ),
                                // Progress Circle
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CustomPaint(
                                    painter: _CircularProgressPainter(
                                      // Fixed: Use completedCount instead of currentIndex
                                      // If strictly segment based, we need to pass states.
                                      // For now, simple progress of "passed/attempts" is better than "current index".
                                      // React draws segments for *attempted* items.
                                      // Let's use completedCount / length for the arc.
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
                            )),
                        Divider(
                            height: 1,
                            color: appColors.border.withOpacity(0.5)),

                        // Content (Flex to fill available space)
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  // Fixed: Center vertically
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center, // Center logic
                                      children: [
                                        // Score Display
                                        if (currentState.attempts > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 24),
                                            child: Text(
                                              '${currentState.bestScore}%',
                                              style: TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: currentState.bestScore >=
                                                        80
                                                    ? Colors.green
                                                    : (currentState.bestScore >=
                                                            50
                                                        ? Colors.orange
                                                        : Colors.red),
                                              ),
                                            ),
                                          ),

                                        // Main Text
                                        _buildFormattedText(
                                            context,
                                            currentItem.text,
                                            currentState.passed,
                                            appColors),

                                        const SizedBox(height: 16),

                                        // IPA
                                        if (currentItem.ipa != null)
                                          Text(
                                            currentItem.ipa!,
                                            style: TextStyle(
                                              color: appColors.primary,
                                              fontFamily: 'monospace',
                                              fontSize: 16,
                                            ),
                                          ),

                                        // Translation
                                        if (currentItem.translate != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
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

                                        // Transcript (Feedback)
                                        if (currentState.transcript != null)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 32),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: appColors.primary
                                                  .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: appColors.primary
                                                    .withOpacity(0.3),
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                            child: Text(
                                              '"${currentState.transcript}"',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: appColors.textSecondary,
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
                                    bottom: 32, left: 24, right: 24, top: 16),
                                child: _buildControls(currentState, currentItem,
                                    appColors, drills),
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
        ),
      ],
    );
  }

  // Custom formatted text builder to handle <p hide='true'> and other tags
  Widget _buildFormattedText(BuildContext context, String content,
      bool isRevealed, AppColorsExtension appColors) {
    // Check if simple text without tags
    if (!content.contains('<p')) {
      return Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.normal,
          color: appColors.textPrimary,
          height: 1.5,
        ),
      );
    }

    final List<InlineSpan> spans = [];
    final regex = RegExp(r"(<p[^>]*>)(.*?)(</p>)",
        caseSensitive: false); // Simple tag parser

    int lastIndex = 0;
    // We iterate matches. If text is between tags, we add it too.
    for (final match in regex.allMatches(content)) {
      if (match.start > lastIndex) {
        String text = content.substring(lastIndex, match.start);
        if (text.trim().isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
      }

      String startTag = match.group(1)!;
      String innerText = match.group(2)!;

      // Check attributes
      bool isHidden =
          startTag.contains("hide='true'") || startTag.contains('hide="true"');

      if (isHidden && !isRevealed) {
        // Render Gap (Dashed lines)
        spans.add(TextSpan(
            text: "_______", // Placeholder for gap
            style: TextStyle(
              color: appColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2, // Space out dashes
            )));
      } else {
        // Render Text (Normal or Revealed)
        spans.add(TextSpan(
            text: innerText,
            style: TextStyle(
              color: isHidden
                  ? appColors.primary
                  : appColors.textPrimary, // Highlight if it was hidden
              fontWeight: FontWeight.normal,
            )));
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      String text = content.substring(lastIndex);
      if (text.trim().isNotEmpty) {
        spans.add(TextSpan(text: text));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 22,
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
      List<PronunciationItem> drills) {
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
                    color: Colors.black.withOpacity(0.1),
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
          if (_currentIndex < drills.length - 1)
            InkWell(
              onTap: _next,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 50,
                height: 50,
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
                    color: Colors.white, size: 22),
              ),
            ),
        ],
      );
    }
    // Low Score: Retry Only (Large)
    else if (state.attempts > 0 && state.bestScore < 50) {
      return InkWell(
        onTap: _retryCurrent,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: appColors.buttonSecondBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.refresh, color: appColors.textSecondary, size: 28),
        ),
      );
    }
    // Initial: Record
    else {
      return InkWell(
        onTap: () =>
            _isRecording ? _stopRecording(item) : _startRecording(item),
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : appColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              if (_isRecording)
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: appColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Icon(
            _isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }
  }
}

class _PronunciationDrillItemState {
  final int score;
  final int bestScore;
  final bool passed;
  final int attempts;
  final String? transcript;

  _PronunciationDrillItemState({
    this.score = 0,
    this.bestScore = 0,
    this.passed = false,
    this.attempts = 0,
    this.transcript,
  });

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

// Circular Progress Painter
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
