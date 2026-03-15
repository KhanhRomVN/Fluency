import 'dart:convert';
import 'dart:math' as math;
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionSpeechBuilder extends StatefulWidget {
  const CollectionSpeechBuilder({
    required this.collectionId,
    required this.terms,
    this.initialIndex = 0,
    this.onPageChanged,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  @override
  State<CollectionSpeechBuilder> createState() =>
      _CollectionSpeechBuilderState();
}

class _CollectionSpeechBuilderState extends State<CollectionSpeechBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isRecording = false;
  SttService? _sttService;
  bool _speechEnabled = false;

  final Map<int, int> _scores = {};
  final Map<int, int> _bestScores = {};
  final Map<int, bool> _passed = {};
  final Map<int, bool> _isChecked = {};
  final Map<int, String?> _transcripts = {};
  final Map<int, int> _attempts = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttService = SystemSttService();
    final available = await _sttService!.initialize();
    if (mounted) {
      setState(() {
        _speechEnabled = available;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sttService?.dispose();
    super.dispose();
  }

  List<String> _getExamples(Term term) {
    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        final meanings = json['meanings'] as List?;
        if (meanings != null) {
          final examples = <String>[];
          for (var meaning in meanings) {
            final definitions = meaning['definitions'] as List?;
            if (definitions != null) {
              for (var def in definitions) {
                final example = def['example'] as String?;
                if (example != null && example.isNotEmpty) {
                  examples.add(example);
                }
              }
            }
          }
          return examples;
        }
      }
    } catch (_) {}
    return [];
  }

  void _startRecording(String target) async {
    if (_isRecording || !_speechEnabled) return;

    try {
      await _sttService!.startListening(
        onResult: (text, isFinal) {
          if (isFinal) {
            _processResult(text, target);
          }
        },
        localeId: 'en_US',
      );
      setState(() => _isRecording = true);
    } catch (_) {}
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    await _sttService!.stopListening();
    setState(() => _isRecording = false);
  }

  void _processResult(String transcript, String target) {
    final score = _calculateScore(transcript, target);
    final isPassed = score >= 80;

    setState(() {
      _isRecording = false;
      _scores[_currentIndex] = score;
      _isChecked[_currentIndex] = true;
      _transcripts[_currentIndex] = transcript;
      _attempts[_currentIndex] = (_attempts[_currentIndex] ?? 0) + 1;

      final currentBest = _bestScores[_currentIndex] ?? 0;
      if (score > currentBest) {
        _bestScores[_currentIndex] = score;
      }

      if (isPassed) {
        _passed[_currentIndex] = true;
      }

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (isPassed) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }
    });

    if (isPassed) {
      final termsWithExamples =
          widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();
      final term = termsWithExamples[_currentIndex];
      final repository = CollectionRepositoryImpl();
      final newProgress = (term.masteryLevel + 0.1).clamp(0.0, 1.0);
      repository.updateTermProgress(
        widget.collectionId,
        term.id,
        newProgress,
      );

      // Auto-next logic:
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _currentIndex == termsWithExamples.indexOf(term)) {
          if (_currentIndex < termsWithExamples.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  int _calculateScore(String spoken, String target) {
    final s = spoken.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
    final t = target.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');

    final sWords = s.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\s+'));

    int matches = 0;
    for (var word in tWords) {
      if (sWords.contains(word)) matches++;
    }
    return ((matches / tWords.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final termsWithExamples =
        widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();

    if (termsWithExamples.isEmpty) {
      return Center(
        child: Text(
          'No examples',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (idx) {
        setState(() => _currentIndex = idx);
        widget.onPageChanged?.call(idx);
      },
      physics: const ClampingScrollPhysics(),
      itemCount: termsWithExamples.length,
      itemBuilder: (context, index) {
        final term = termsWithExamples[index];
        final examples = _getExamples(term);
        final example = examples.first;
        final bestScore = _bestScores[index] ?? 0;
        final transcript = _transcripts[index];
        final isPassed = _passed[index] ?? false;
        final isChecked = _isChecked[index] ?? false;
        final attempts = _attempts[index] ?? 0;

        final borderColor = isPassed
            ? Colors.green
            : (attempts > 0
                ? Colors.red
                : appColors.border.withValues(alpha: 0.5));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
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
                  _buildCardHeader(
                      context, appColors, termsWithExamples, index),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Speak this sentence:',
                            style: TextStyle(
                                color: appColors.textSecondary, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (attempts > 0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 24),
                                        child: Text(
                                          '$bestScore%',
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: bestScore >= 80
                                                ? Colors.green
                                                : (bestScore >= 50
                                                    ? Colors.orange
                                                    : Colors.red),
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: appColors.inputBackground
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: appColors.border
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        example,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: appColors.textPrimary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (transcript != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Column(
                                          children: [
                                            Text(
                                              'You said:',
                                              style: TextStyle(
                                                  color:
                                                      appColors.textSecondary,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '"$transcript"',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: appColors.textPrimary,
                                                  fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
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
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMicButton(index, example, appColors),
                            if (isChecked) ...[
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (index < termsWithExamples.length - 1) {
                                    _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      appColors.primary.withValues(alpha: 0.15),
                                  foregroundColor: appColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: Text(
                                    index < termsWithExamples.length - 1
                                        ? 'Next'
                                        : 'Finish',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRecording && _currentIndex == index
                              ? 'Listening...'
                              : (isChecked ? 'Try again?' : 'Tap to record'),
                          style: TextStyle(
                            color: appColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    AppColorsExtension appColors,
    List<Term> terms,
    int index,
  ) {
    final completedCount = _passed.values.where((v) => v).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${index + 1} / ${terms.length}',
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
                    totalSegments: terms.length,
                    segmentStates: List.generate(terms.length, (i) {
                      if (!(_isChecked[i] ?? false)) return 0;
                      return (_passed[i] ?? false) ? 1 : 2;
                    }),
                    primaryColor: appColors.primary,
                    errorColor: Colors.red,
                    emptyColor: appColors.border.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildMicButton(
    int index,
    String target,
    AppColorsExtension appColors,
  ) {
    final isRecordingForThis = _isRecording && _currentIndex == index;

    return InkWell(
      onTap: isRecordingForThis
          ? () => _stopRecording()
          : () => _startRecording(target),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isRecordingForThis
              ? appColors.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: isRecordingForThis ? appColors.primary : Colors.grey,
          size: 24,
        ),
      ),
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
    const strokeWidth = 3.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -3.14159 / 2;
    final gap = (totalSegments > 1) ? 0.2 : 0;
    final segmentAngle = (2 * 3.14159 - (gap * totalSegments)) / totalSegments;

    for (var i = 0; i < totalSegments; i++) {
      final state = (i < segmentStates.length) ? segmentStates[i] : 0;
      if (state == 1)
        paint.color = primaryColor;
      else if (state == 2)
        paint.color = errorColor;
      else
        paint.color = emptyColor;

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
  bool shouldRepaint(covariant _SegmentedProgressPainter oldDelegate) => true;
}
