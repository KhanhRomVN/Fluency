import 'dart:convert';
import 'dart:math';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/domain/entities/transcript_model.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

class ListeningChoice extends StatefulWidget {
  const ListeningChoice({
    required this.quiz,
    required this.lessonId,
    this.onCheck,
    this.onNext,
    this.onPrev,
    this.onShowExplain,
    this.onWordLongPress,
    this.onSegmentChange,
    this.targetQuestionIndex,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final void Function(String explanation)? onShowExplain;
  final void Function(String word)? onWordLongPress;
  final void Function(double? start, double? end)? onSegmentChange;

  final int? targetQuestionIndex;

  @override
  State<ListeningChoice> createState() => _ListeningChoiceState();
}

class _ListeningChoiceState extends State<ListeningChoice> {
  // Key: Question ID, Value: Selected option value (text or key)
  final Map<String, String> _selectedAnswers = {};

  // Track submission status per question ID
  final Set<String> _submittedQuestions = {};

  // Track correctness per question ID
  final Map<String, bool> _questionCorrectness = {};

  // Current active question index
  int _currentQuestionIndex = 0;

  TranscriptData? _transcriptData;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProgress();
    _loadTranscript();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ListeningChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quiz.transcript != oldWidget.quiz.transcript) {
      _loadTranscript();
    } else if (widget.quiz.id != oldWidget.quiz.id) {
      // Re-emit existing data if the quiz ID changed but transcript is same (page switch)
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_transcriptData != null) {
          debugPrint('ListeningChoice: Re-emitting segment change');
        }
        _triggerSegmentChange();
      });
    }

    if (widget.targetQuestionIndex != null &&
        widget.targetQuestionIndex != oldWidget.targetQuestionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(widget.targetQuestionIndex!);
          setState(() {
            _currentQuestionIndex = widget.targetQuestionIndex!;
          });
        }
      });
    }
  }

  double _parseTimeToSeconds(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return 0;
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return int.parse(parts[0]) * 60.0 + int.parse(parts[1]);
      } else if (parts.length == 3) {
        return int.parse(parts[0]) * 3600.0 +
            int.parse(parts[1]) * 60.0 +
            int.parse(parts[2]);
      }
    } catch (e) {
      debugPrint('Error parsing time string $timeStr: $e');
    }
    return 0;
  }

  Future<void> _loadTranscript() async {
    final transcriptPath = widget.quiz.transcript;
    if (transcriptPath == null || transcriptPath.isEmpty) return;

    try {
      String jsonString;
      if (transcriptPath.startsWith('http')) {
        // Handle http if needed, but usually we download first
        return;
      } else if (transcriptPath.startsWith('/')) {
        final file = File(transcriptPath);
        if (await file.exists()) {
          jsonString = await file.readAsString();
        } else {
          return;
        }
      } else {
        // Asset
        jsonString = await rootBundle.loadString(transcriptPath);
      }

      final jsonMap = json.decode(jsonString);
      if (jsonMap is Map<String, dynamic>) {
        final data = TranscriptData.fromJson(jsonMap);
        setState(() {
          _transcriptData = data;
        });
        debugPrint(
            'ListeningChoice: Transcript loaded successfully. Segments: ${data.transcript.length}');

        // Calculate quiz-level segment (entire transcript range)
        // Moved to MediaPlayer, no need to calculate here unless needed for other logic
        // if (data.transcript.isNotEmpty) { ... }

        _triggerSegmentChange();
      }
    } catch (e) {
      debugPrint('Error loading transcript in ListeningChoice: $e');
    }
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quiz.id,
    );

    if (progress != null && mounted) {
      setState(() {
        _currentQuestionIndex =
            progress.data?['currentQuestionIndex'] as int? ?? 0;

        // Jump to saved page
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentQuestionIndex);
        } else {
          // If controller not attached yet, initialPage handles it,
          // but we already created controller with default init (0).
          // We might need to recreate controller if initState already ran?
          // Actually create controller with this index is safer if this runs early.
          // However, initState runs once.
          // Better: rely on jumpToPage.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_currentQuestionIndex);
            } else {
              _pageController =
                  PageController(initialPage: _currentQuestionIndex);
            }
          });
        }

        final submittedIds =
            progress.data?['submittedQuestions'] as List<dynamic>?;
        if (submittedIds != null) {
          _submittedQuestions.addAll(submittedIds.cast<String>());
        }

        final correctness =
            progress.data?['questionCorrectness'] as Map<String, dynamic>?;
        if (correctness != null) {
          correctness.forEach((key, value) {
            _questionCorrectness[key] = value as bool;
          });
        }

        final selected =
            progress.data?['selectedAnswers'] as Map<String, dynamic>?;
        if (selected != null) {
          selected.forEach((questionId, answer) {
            _selectedAnswers[questionId] = answer.toString();
          });
        }
      });
      _triggerSegmentChange();
    }
  }

  void _triggerSegmentChange() {
    if (widget.quiz.questions.isEmpty) {
      widget.onSegmentChange?.call(null, null);
      return;
    }

    final q = widget.quiz.questions[_currentQuestionIndex];
    final segmentId = q.audioSegmentId;

    debugPrint(
        'ListeningChoice: Checking segment for Q${_currentQuestionIndex + 1} (ID: ${q.id}). SegmentID: $segmentId');

    if (segmentId != null && segmentId.isNotEmpty && _transcriptData != null) {
      // Try to parse ID as int
      final idInt = int.tryParse(segmentId);
      if (idInt != null) {
        try {
          final segment = _transcriptData!.transcript.firstWhere(
            (s) => s.id == idInt,
          );

          final start = segment.timestamps.startSeconds.toDouble();
          final end = segment.timestamps.endSeconds.toDouble();

          debugPrint(
              'ListeningChoice: Found segment $idInt. Start: $start, End: $end');
          widget.onSegmentChange?.call(start, end);
          return;
        } catch (_) {
          debugPrint('ListeningChoice: Segment $idInt not found');
        }
      }
    } else {
      debugPrint('ListeningChoice: No segment info or transcript data');
    }

    // Fallback or clear segment
    widget.onSegmentChange?.call(null, null);
  }

  void _handleOptionSelect(String questionId, String optionValue) {
    if (_submittedQuestions.contains(questionId)) return;
    setState(() {
      _selectedAnswers[questionId] = optionValue;
    });
  }

  Future<void> _handleConfirm() async {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final selected = _selectedAnswers[question.id];
    if (selected == null) return;

    setState(() {
      _submittedQuestions.add(question.id);
      final isCorrect = selected == question.answer ||
          question.validAnswers.contains(selected);
      _questionCorrectness[question.id] = isCorrect;
    });

    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final correctCount = _questionCorrectness.values.where((e) => e).length;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quiz.id,
      quizType: 'listening-choice',
      completedItems: _submittedQuestions.length,
      totalItems: widget.quiz.questions.length,
      correctItems: correctCount,
      data: {
        'currentQuestionIndex': _currentQuestionIndex,
        'submittedQuestions': _submittedQuestions.toList(),
        'questionCorrectness': _questionCorrectness,
        'selectedAnswers': _selectedAnswers,
      },
    );

    if (_submittedQuestions.length == widget.quiz.questions.length) {
      widget.onCheck?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.questions;
    if (questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // Note: _currentQuestionIndex now updated via PageView onPageChanged

    return ColoredBox(
      color: appColors.background,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
                _triggerSegmentChange();
                _saveProgress();
              },
              itemBuilder: (context, index) {
                final question = questions[index];
                final isSubmitted = _submittedQuestions.contains(question.id);

                return Padding(
                  // Add padding between pages if needed, but PageView usually handles it.
                  // If we want spacing between cards during swipe, we can add margin here.
                  // But standard PageView is edge-to-edge.
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: appColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _DashedBorderPainter(
                              color: _getBorderColor(appColors, question),
                              strokeWidth: 2,
                              gap: 4,
                              borderRadius: 12,
                            ),
                            child: Column(
                              children: [
                                // Header - Pass the specfic index for this card
                                _buildHeader(
                                    context, appColors, questions, index),
                                const Divider(height: 1),

                                // Content
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Images
                                        _buildImages(question),
                                        if ((question.images?.isNotEmpty ??
                                                false) ||
                                            question.image != null)
                                          const SizedBox(height: 16),

                                        // Question Text
                                        if (question.question.isNotEmpty) ...[
                                          Text(
                                            question.question,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: appColors.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],

                                        // Options
                                        _buildOptions(context, question,
                                            appColors, isSubmitted),
                                      ],
                                    ),
                                  ),
                                ),
                                // Footer
                                if (_submittedQuestions.contains(question.id) ||
                                    _selectedAnswers
                                        .containsKey(question.id)) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _buildActionButtons(appColors,
                                            questions[_currentQuestionIndex]),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
      ),
    );
  }

  Color _getBorderColor(
      AppColorsExtension appColors, QuizQuestion currentQuestion) {
    final isSubmitted = _submittedQuestions.contains(currentQuestion.id);
    if (isSubmitted) {
      return (_questionCorrectness[currentQuestion.id] ?? false)
          ? appColors.primary
          : Colors.red;
    }
    return appColors.border.withValues(alpha: 0.5);
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension appColors,
      List<QuizQuestion> questions, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

          // Progress Circle (Custom Painter from MultipleChoice)
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildSegmentedProgress(appColors, questions),
                Text(
                  '${_submittedQuestions.length}',
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

  Widget _buildSegmentedProgress(
      AppColorsExtension appColors, List<QuizQuestion> questions) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: SegmentedProgressPainter(
        totalSegments: questions.length,
        segmentStates: List.generate(questions.length, (index) {
          final qId = questions[index].id;
          if (!_submittedQuestions.contains(qId)) return 0;
          return (_questionCorrectness[qId] ?? false) ? 1 : 2;
        }),
        primaryColor: appColors.primary,
        errorColor: Colors.red,
        emptyColor: appColors.border,
      ),
    );
  }

  Widget _buildImages(QuizQuestion question) {
    final images = question.images ?? [];
    if (images.isEmpty && question.image != null) images.add(question.image!);

    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: images.map((img) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 240),
              color: Colors.grey[100],
              child: _loadImage(img),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _loadImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain);
    } else if (path.startsWith('/')) {
      return Image.file(File(path), fit: BoxFit.contain);
    } else {
      // Assuming it's an asset or needs resolution
      return Image.asset(path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
    }
  }

  Widget _buildOptions(BuildContext context, QuizQuestion question,
      AppColorsExtension appColors, bool isSubmitted) {
    final options = ['A', 'B', 'C', 'D']
        .sublist(0, question.options.isNotEmpty ? question.options.length : 4);
    final selected = _selectedAnswers[question.id];

    return Column(
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final key = entry.value;
        final optionValue =
            question.options.isNotEmpty ? question.options[idx] : key;
        final isSelected = selected == optionValue;
        final isCorrect = question.answer == optionValue ||
            question.validAnswers.contains(optionValue);

        var borderColor = appColors.border.withValues(alpha: 0.3);
        var bgColor = appColors.cardBackground;
        var textColor = appColors.textPrimary;
        Widget? icon;

        if (isSubmitted) {
          if (isCorrect) {
            borderColor = appColors.primary;
            bgColor = appColors.primary.withValues(alpha: 0.1);
            textColor = appColors.primary;
            icon = const Icon(Icons.check, size: 16, color: Colors.white);
          } else if (isSelected) {
            borderColor = Colors.red;
            bgColor = Colors.red.withValues(alpha: 0.1);
            textColor = Colors.red;
            icon = const Icon(Icons.close, size: 16, color: Colors.white);
          } else {
            bgColor = appColors.cardBackground;
            textColor = appColors.textSecondary.withValues(alpha: 0.5);
          }
        } else if (isSelected) {
          borderColor = appColors.primary;
          bgColor = appColors.primary.withValues(alpha: 0.05);
          textColor = appColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: isSubmitted
                ? null
                : () => _handleOptionSelect(question.id, optionValue),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isSubmitted && (icon != null))
                          ? (isCorrect ? appColors.primary : Colors.red)
                          : (isSelected
                              ? appColors.primary
                              : appColors.cardBackground),
                      border: Border.all(
                          color: (isSubmitted && (icon != null))
                              ? (isCorrect ? appColors.primary : Colors.red)
                              : (isSelected
                                  ? appColors.primary
                                  : appColors.border),
                          width: 2),
                    ),
                    child: Center(
                      child: icon ??
                          Text(key,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? Colors.white : Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSubmitted ? optionValue : 'Option $key',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || (isSubmitted && isCorrect)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(
      AppColorsExtension appColors, QuizQuestion currentQuestion) {
    final isSubmitted = _submittedQuestions.contains(currentQuestion.id);

    if (isSubmitted) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: widget.onNext,
        child:
            const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (_selectedAnswers.containsKey(currentQuestion.id)) {
      return ElevatedButton(
        onPressed: _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Check Answer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// Re-defining Painter here to avoid import issues or dependencies if needed,
// though importing from multiple_choice is fine if it's exported.
class SegmentedProgressPainter extends CustomPainter {
  SegmentedProgressPainter({
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

    var startAngle = -pi / 2;
    final gap = (totalSegments > 1) ? 0.2 : 0;
    final totalGap = gap * totalSegments;
    final segmentAngle = (2 * pi - totalGap) / totalSegments;

    for (var i = 0; i < totalSegments; i++) {
      final state = (i < segmentStates.length) ? segmentStates[i] : 0;
      paint.color =
          state == 1 ? primaryColor : (state == 2 ? errorColor : emptyColor);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
