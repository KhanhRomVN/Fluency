import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

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
    // If it's a gap fill (hiddenWord), we should check if they said the hidden word correctly.
    // For now, simple mock pass.
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

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top content (Instruction)
                if (widget.quiz.instruction.isNotEmpty) ...[
                  RichTextParser.buildRichText(
                    context,
                    widget.quiz.instruction,
                    onWordLongPress: widget.onWordLongPress,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16),
                  ).first,
                  const SizedBox(height: 24),
                ],

                // Cards (Passed and Current)
                ...drills.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  // Only show passed cards and current card
                  if (index > _currentIndex) return const SizedBox.shrink();

                  return _buildCard(context, item, index, appColors);
                }),

                // Invisible spacer for visual balance (mimicking TSX)
                if (widget.quiz.instruction.isNotEmpty)
                  Opacity(
                    opacity: 0,
                    child: RichTextParser.buildRichText(
                      context,
                      widget.quiz.instruction,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16),
                    ).first,
                  ),

                // Bottom spacer
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCard(BuildContext context, PronunciationItem item, int index,
      AppColorsExtension appColors) {
    final state = _itemStates[item.id] ?? _PronunciationDrillItemState();
    final isCurrent = index == _currentIndex;
    final isPassed = index < _currentIndex || state.passed;

    // Animate in if current
    // In Flutter we can use simple AnimatedContainer or just let it rebuild.
    // For simplicity, we just render it.

    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isCurrent
              ? appColors.cardBackground
              : appColors.cardBackground.withValues(alpha: 0.5),
          border: Border.all(
              color: isCurrent
                  ? appColors.primary.withValues(alpha: 0.5)
                  : appColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: appColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (isPassed && !isCurrent) ...[
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${index + 1}/${widget.quiz.pronunciations?.length ?? 0}',
                    style:
                        TextStyle(color: appColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: appColors.border.withValues(alpha: 0.5)),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Score
                  if (isCurrent && state.attempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${state.bestScore}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: state.bestScore >= 80
                              ? Colors.green
                              : (state.bestScore >= 50
                                  ? Colors.orange
                                  : Colors.red),
                        ),
                      ),
                    ),

                  // Main Text with Gap UI Support
                  _buildTextContent(
                      context, item, isCurrent, isPassed, appColors),

                  const SizedBox(height: 16),

                  if (item.ipa != null)
                    Text(item.ipa!,
                        style: TextStyle(
                            color: appColors.primary,
                            fontFamily: 'monospace',
                            fontSize: 16)),

                  if (item.translate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(item.translate!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: appColors.textSecondary,
                              fontStyle: FontStyle.italic)),
                    ),

                  if (isCurrent && state.transcript != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: appColors.primary.withValues(alpha: 0.5),
                            style: BorderStyle.none),
                        // Note: Flutter BorderStyle.none means no border.
                        // To get dashed border usually needs custom painter or package.
                        // We will use standard border for now to avoid complexity or dotted_border package if available (not assumed available).
                        // Let's use simple border with low opacity or solid.
                        // Updated to just solid for now as quick fix.
                      ),
                      // Actually let's use a subtle background
                      color: appColors.background,
                      child: Text(
                        '"${state.transcript}"',
                        style: TextStyle(color: appColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),

            // Controls (Current Card Only)
            if (isCurrent)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: appColors.border.withValues(alpha: 0.5)),
                  ),
                ),
                child: _buildControls(state, item, appColors),
              ),
          ],
        ));
  }

  Widget _buildTextContent(BuildContext context, PronunciationItem item,
      bool isCurrent, bool isPassed, AppColorsExtension appColors) {
    // If hiddenWord exists, handle gap fill style
    if (item.hiddenWord != null && item.hiddenWord!.isNotEmpty) {
      final text = item.text;
      final hiddenWord = item.hiddenWord!;

      // Case insensitive split
      final pattern = RegExp(RegExp.escape(hiddenWord), caseSensitive: false);
      final parts = text.split(pattern);
      final matches = pattern.allMatches(text).toList();

      List<InlineSpan> spans = [];
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(
            text: parts[i],
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary),
          ));
        }

        if (i < matches.length) {
          // The hidden word part
          final matchWord = text.substring(matches[i].start, matches[i].end);

          if (isCurrent && !isPassed) {
            // Show Gap with underscores (dashed look)
            final gapText = List.filled(matchWord.length, '_').join(' ');
            spans.add(TextSpan(
              text: gapText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    appColors.primary, // User requested primary color for gapUI
                // User wants "gạch xen kẽ" (dashed lines). Underscores look like dashes.
                // Let's use primary color for the dashes to match the theme?
                // Or standard text color. Let's use primary to indicate active gap.
              ),
            ));
          } else {
            // Show Revealed Word
            spans.add(TextSpan(
              text: matchWord,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.primary,
              ),
            ));
          }
        }
      }

      return Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
      );
    }

    // Default display (split by words)
    final words = item.text.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: words.map((w) {
        // If passed, highlight? TSX doesn't highlight everything, only hidden words or specific feedback.
        // But the user screenshot 2 shows simple text.
        // Let's keep it simple: textPrimary.
        return Text(
          w,
          style: TextStyle(
              fontSize: 20,
              color: appColors.textPrimary,
              fontWeight: FontWeight.bold),
        );
      }).toList(),
    );
  }

  Widget _buildControls(_PronunciationDrillItemState state,
      PronunciationItem item, AppColorsExtension appColors) {
    if (state.attempts > 0 && state.bestScore >= 50) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _retryCurrent,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: appColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_currentIndex <
              (widget.quiz.pronunciations?.length ?? 0) - 1) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
        ],
      );
    } else if (state.attempts > 0 && state.bestScore < 50) {
      // Retry button icon only
      return Center(
        child: GestureDetector(
          onTap: _retryCurrent,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: appColors.cardBackground,
                border: Border.all(color: appColors.border),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  )
                ]),
            child: Icon(Icons.refresh, color: appColors.textSecondary),
          ),
        ),
      );
    } else {
      // Mic button
      return Center(
        child: GestureDetector(
          onTap: () =>
              _isRecording ? _stopRecording(item) : _startRecording(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: _isRecording ? Colors.red : appColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isRecording)
                    BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 20)
                  else
                    BoxShadow(
                        color: appColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                ]),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 32,
            ),
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
