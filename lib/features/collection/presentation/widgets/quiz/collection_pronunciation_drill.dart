import 'dart:convert';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionPronunciationDrill extends StatefulWidget {
  const CollectionPronunciationDrill({
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
  State<CollectionPronunciationDrill> createState() =>
      _CollectionPronunciationDrillState();
}

class _CollectionPronunciationDrillState
    extends State<CollectionPronunciationDrill> {
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

  void _onPageChangedInternal(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onPageChanged?.call(index);
  }

  Future<void> _speak(String text) async {
    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isInitialized) {
      await ttsProvider.initService();
    }
    await ttsProvider.ttsService?.speak(text);
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
    final isPassed = score >= 70;

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
      final term = widget.terms[_currentIndex];
      final repository = CollectionRepositoryImpl();
      final newProgress = (term.masteryLevel + 0.1).clamp(0.0, 1.0);
      repository.updateTermProgress(
        widget.collectionId,
        term.id,
        newProgress,
      );

      // Auto-next logic:
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _currentIndex == widget.terms.indexOf(term)) {
          if (_currentIndex < widget.terms.length - 1) {
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
    final s = spoken.toLowerCase().trim();
    final t = target.toLowerCase().trim();
    if (s == t) return 100;

    final sWords = s.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\s+'));
    int matches = 0;
    for (var word in tWords) {
      if (sWords.any((sw) => sw.contains(word) || word.contains(sw))) {
        matches++;
      }
    }
    return ((matches / tWords.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final terms = widget.terms;

    if (terms.isEmpty) {
      return Center(
        child: Text(
          'No terms',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChangedInternal,
      physics: const ClampingScrollPhysics(),
      itemCount: terms.length,
      itemBuilder: (context, index) {
        final term = terms[index];
        final score = _scores[index];
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
                  // Card Header
                  _buildCardHeader(context, appColors, terms, index),
                  const Divider(height: 1),

                  // Content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (attempts > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(
                                  '$bestScore%',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: bestScore >= 80
                                        ? Colors.green
                                        : (bestScore >= 50
                                            ? Colors.orange
                                            : Colors.red),
                                  ),
                                ),
                              ),
                            Text(
                              term.term,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: appColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (term.phonetics.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  term.phonetics.first,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: appColors.textSecondary,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ),
                            if (term.definition.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _getDefinitionText(term.definition),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: appColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            IconButton(
                              onPressed: () => _speak(term.term),
                              icon: Icon(Icons.volume_up,
                                  color: appColors.primary, size: 32),
                            ),
                            if (transcript != null)
                              Container(
                                margin: const EdgeInsets.only(top: 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      appColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: appColors.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '"$transcript"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: appColors.textSecondary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMicButton(index, term.term, appColors),
                        if (isChecked) ...[
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (index < terms.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  appColors.primary.withValues(alpha: 0.15),
                              foregroundColor: appColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                                index < terms.length - 1 ? 'Next' : 'Finish',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
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

  String _getDefinitionText(String definition) {
    if (!definition.startsWith('{')) return definition;
    try {
      final json = jsonDecode(definition) as Map<String, dynamic>;
      final meanings = json['meanings'] as List?;
      if (meanings != null &&
          meanings.isNotEmpty &&
          meanings[0]['definitions'] != null &&
          (meanings[0]['definitions'] as List).isNotEmpty) {
        return meanings[0]['definitions'][0]['definition'] as String;
      }
    } catch (_) {}
    return definition;
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
