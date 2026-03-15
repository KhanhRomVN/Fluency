import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpeechBuilder extends StatefulWidget {
  const SpeechBuilder({
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
  State<SpeechBuilder> createState() => _SpeechBuilderState();
}

class _SpeechBuilderState extends State<SpeechBuilder> {
  int _currentIndex = 0;
  bool _isRecording = false;
  final Map<String, _SpeechBuilderItemState> _itemStates = {};

  // Animation variables for Swipe
  late PageController _pageController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

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
      final savedStates = progress.data?['itemStates'] as Map<String, dynamic>?;
      if (savedStates != null) {
        savedStates.forEach((key, value) {
          final data = value as Map<String, dynamic>;
          _itemStates[key] = _SpeechBuilderItemState(
            score: data['score'] as int? ?? 0,
            bestScore: data['bestScore'] as int? ?? 0,
            passed: data['passed'] as bool? ?? false,
            attempts: data['attempts'] as int? ?? 0,
            transcript: data['transcript'] as String?,
          );
        });
      }

      // Find first unpassed item index
      final items = widget.quiz.speechBuilders ?? [];
      int firstUnpassed = 0;
      for (int i = 0; i < items.length; i++) {
        if (!(_itemStates[items[i].id]?.passed ?? false)) {
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

    final totalItems = widget.quiz.speechBuilders?.length ?? 0;
    final completedItems = _itemStates.values.where((s) => s.passed).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'speech-builder',
      completedItems: completedItems,
      totalItems: totalItems,
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

  // Swipe logic removed in favor of PageView

  void _startRecording(SpeechBuilderItem item) {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
    });

    // Mock Recording Logic
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _stopRecording(item);
    });
  }

  void _stopRecording(SpeechBuilderItem item) {
    if (!_isRecording) return;

    // Determine target text from answers
    final targetText = item.answers?.first.answer.first ?? '';

    // Mock result (60-100% score)
    final score = math.Random().nextInt(41) + 60;
    final passed = score >= 80; // Threshold to pass

    setState(() {
      _isRecording = false;
      final current = _itemStates[item.id] ?? _SpeechBuilderItemState();
      _itemStates[item.id] = current.copyWith(
        score: score,
        bestScore: score > current.bestScore ? score : current.bestScore,
        passed: passed || current.passed,
        attempts: current.attempts + 1,
        transcript:
            passed ? targetText : 'I am trying to speak...', // Mock transcript
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final items = widget.quiz.speechBuilders ?? [];

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No speech builder items available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    final currentItem = items[_currentIndex];
    final currentState =
        _itemStates[currentItem.id] ?? _SpeechBuilderItemState();

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final state = _itemStates[item.id] ?? _SpeechBuilderItemState();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: state.passed
                    ? Colors.green
                    : (state.attempts > 0
                        ? Colors.red
                        : appColors.border.withValues(alpha: 0.5)),
                strokeWidth: 2,
                gap: 4,
                borderRadius: 12,
              ),
              child: Column(
                children: [
                  // Internal Header
                  _buildInternalHeader(context, appColors, items, index),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Hint / Translate
                          if (item.hint != null || item.translate != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text.rich(
                                TextSpan(
                                  children: RichTextParser.buildTextSpans(
                                    context,
                                    item.hint ?? item.translate ?? '',
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: appColors.textSecondary,
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // Question Context
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: _buildQuestionContent(
                                  context,
                                  item,
                                  state,
                                  appColors,
                                ),
                              ),
                            ),
                          ),

                          // Score / Feedback
                          if (state.attempts > 0 && !state.passed)
                            _buildFeedback(state, appColors),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterActions(
                          item,
                          state,
                          appColors,
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
    );
  }

  Widget _buildInternalHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<SpeechBuilderItem> questions,
    int index,
  ) {
    final passedCount = _itemStates.values.where((s) => s.passed).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${index + 1} / ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: appColors.textSecondary,
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(32, 32),
                  painter: _SegmentedProgressPainter(
                    totalSegments: questions.length,
                    segmentStates: List.generate(questions.length, (index) {
                      final qId = questions[index].id;
                      final s = _itemStates[qId];
                      if (s == null || (!s.passed && s.attempts == 0)) return 0;
                      return s.passed ? 1 : 2;
                    }),
                    primaryColor: appColors.primary,
                    errorColor: Colors.red,
                    emptyColor: appColors.border.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '$passedCount',
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
    );
  }

  Widget _buildQuestionContent(
    BuildContext context,
    SpeechBuilderItem item,
    _SpeechBuilderItemState state,
    AppColorsExtension appColors,
  ) {
    if (item.question != null) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: RichTextParser.buildRichText(
          context,
          item.question!,
          isQuestion: true,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: appColors.textPrimary,
            height: 1.4,
          ),
          onGapFound: (gapId) {
            final answerObj = item.answers?.firstWhere(
              (a) => a.id == gapId,
              orElse: () => const QuizAnswer(id: '', answer: [], explain: ''),
            );
            final answerText = answerObj?.answer.first ?? '';
            final underscores =
                '_' * (answerText.isNotEmpty ? answerText.length : 5);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                state.passed ? answerText : underscores,
                style: TextStyle(
                  color: state.passed
                      ? appColors.primary
                      : appColors.primary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: state.passed ? 0 : 2,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Legacy Items Mode
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: (item.items ?? []).map((word) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: state.passed
                  ? Colors.green.withValues(alpha: 0.1)
                  : appColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.passed ? Colors.green : appColors.border,
              ),
            ),
            child: Text(
              word,
              style: TextStyle(
                color: state.passed ? Colors.green : appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildFeedback(
      _SpeechBuilderItemState state, AppColorsExtension appColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: _getScoreColor(state.score).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${state.bestScore}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(state.score),
            ),
          ),
          if (state.transcript != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You said: "${state.transcript}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildFooterActions(
    SpeechBuilderItem item,
    _SpeechBuilderItemState state,
    AppColorsExtension appColors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMicButton(item, state, appColors),
        if (state.passed) ...[
          const SizedBox(width: 16),
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
      ],
    );
  }

  Widget _buildMicButton(
    SpeechBuilderItem item,
    _SpeechBuilderItemState state,
    AppColorsExtension appColors,
  ) {
    /*
    if (state.passed) {
       // If passed, maybe we don't show the mic button anymore?
       // Or we show it to allow re-recording?
       // The original code returned a Check icon if passed.
       // But in footer, we want the "Next" button to be the primary action.
       // Let's keep the mic button active for re-recording, 
       // or if passed, show the check icon but maybe smaller?
       // Actually, in PronunciationDrill, we kept the mic button.
       // Here, original code returned Container(Check Icon).
       // Let's return SizedBox.shrink() if passed, because "Next" button appears.
       // Or allow re-recording?
       // Users might want to try again to get better score.
       // But if passed, `onNext` is available.
    }
    */

    // If passed, we can hide the mic button OR allow retry.
    // Original code:
    /*
    if (state.passed) {
      return Container(..., child: Icon(Icons.check...));
    }
    */
    // If I show "Next" button, the check icon next to it is redundant/confusing?
    // In PronunciationDrill, `_buildControls` was just the Mic.
    // Here, let's keep it simple: If passed, hide Mic (or show Refresh?), show Next.
    // But `pronunciation_drill` allows re-recording even if passed?
    // Let's allow re-recording.

    return InkWell(
      onTap: () => _isRecording ? _stopRecording(item) : _startRecording(item),
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

  IconData isRecordingOrPassedIcon(_SpeechBuilderItemState state) {
    if (state.passed) return Icons.refresh;
    return Icons.mic;
  }
}

class _SpeechBuilderItemState {
  _SpeechBuilderItemState({
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

  _SpeechBuilderItemState copyWith({
    int? score,
    int? bestScore,
    bool? passed,
    int? attempts,
    String? transcript,
  }) {
    return _SpeechBuilderItemState(
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
      transcript: transcript ?? this.transcript,
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
  final List<int> segmentStates;
  final Color primaryColor;
  final Color errorColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth.toDouble()
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
    return oldDelegate.totalSegments != totalSegments ||
        oldDelegate.segmentStates != segmentStates;
  }
}
