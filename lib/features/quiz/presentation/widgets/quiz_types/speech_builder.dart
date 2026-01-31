import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SpeechBuilder extends StatefulWidget {
  const SpeechBuilder({
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
  State<SpeechBuilder> createState() => _SpeechBuilderState();
}

class _SpeechBuilderState extends State<SpeechBuilder>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRecording = false;
  final Map<String, _SpeechBuilderItemState> _itemStates = {};

  // Animation variables for Swipe
  double _swipeOffset = 0;
  late AnimationController _swipeController;
  Animation<double>? _swipeSlideAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _swipeController.addListener(() {
      setState(() {
        if (_swipeSlideAnimation != null) {
          _swipeOffset = _swipeSlideAnimation!.value;
        }
      });
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
            _itemStates[key] = _SpeechBuilderItemState(
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
    _swipeController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isTransitioning) return;
    setState(() {
      _swipeOffset += details.primaryDelta!;
      _swipeOffset = _swipeOffset.clamp(-100.0, 100.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;
    const threshold = 80.0;
    final items = widget.quiz.speechBuilders ?? [];

    if (_swipeOffset < -threshold && _currentIndex < items.length - 1) {
      _slideCard('left');
    } else if (_swipeOffset > threshold && _currentIndex > 0) {
      _slideCard('right');
    } else {
      _resetSwipe();
    }
  }

  void _slideCard(String direction) {
    setState(() {
      _isTransitioning = true;
    });

    final endOffset = direction == 'left' ? -400.0 : 400.0;
    _swipeSlideAnimation =
        Tween<double>(begin: _swipeOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    _swipeController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex += (direction == 'left' ? 1 : -1);
        _swipeOffset = (direction == 'left' ? 400.0 : -400.0);

        _swipeSlideAnimation =
            Tween<double>(begin: _swipeOffset, end: 0).animate(
          CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
        );
        _swipeController.forward(from: 0).then((_) {
          setState(() {
            _isTransitioning = false;
          });
          _saveProgress();
        });
      });
    });
  }

  void _resetSwipe() {
    _swipeSlideAnimation = Tween<double>(begin: _swipeOffset, end: 0).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _swipeController.forward(from: 0);
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction (Outer)

        // Main Card Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Transform.translate(
                offset: Offset(_swipeOffset, 0),
                child: Transform.rotate(
                  angle: _swipeOffset * 0.0002,
                  child: Opacity(
                    opacity: (1 - (_swipeOffset.abs() / 400)).clamp(0.5, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          color: appColors.primary.withValues(alpha: 0.5),
                          strokeWidth: 2,
                          gap: 4,
                          borderRadius: 12,
                        ),
                        child: Column(
                          children: [
                            // Internal Header
                            _buildInternalHeader(context, appColors, items),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Hint / Translate
                                    if (currentItem.hint != null ||
                                        currentItem.translate != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 24),
                                        child: Text.rich(
                                          TextSpan(
                                            children:
                                                RichTextParser.buildTextSpans(
                                              context,
                                              currentItem.hint ??
                                                  currentItem.translate ??
                                                  '',
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: appColors.textSecondary,
                                            fontSize: 14,
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
                                            currentItem,
                                            currentState,
                                            appColors,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Score / Feedback
                                    if (currentState.attempts > 0 &&
                                        !currentState.passed)
                                      _buildFeedback(currentState, appColors),

                                    const SizedBox(height: 32),

                                    // Controls
                                    _buildControls(
                                        currentItem, currentState, appColors),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Floating Next (Standard in some quizzes when passed)
        if (currentState.passed && _currentIndex < items.length - 1)
          _buildFloatingNextButton(appColors),
      ],
    );
  }

  Widget _buildInternalHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<SpeechBuilderItem> questions,
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
            '${_currentIndex + 1} / ${questions.length}',
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

  Widget _buildControls(
    SpeechBuilderItem item,
    _SpeechBuilderItemState state,
    AppColorsExtension appColors,
  ) {
    if (state.passed) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 32),
      );
    }

    return InkWell(
      onTap: () => _isRecording ? _stopRecording(item) : _startRecording(item),
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : appColors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRecording
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : appColors.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: _isRecording ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.mic_off : Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFloatingNextButton(AppColorsExtension appColors) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: FloatingActionButton(
        onPressed: () => _slideCard('left'),
        backgroundColor: appColors.primary,
        child: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
      ),
    );
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
