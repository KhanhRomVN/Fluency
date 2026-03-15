import 'dart:convert';
import 'dart:math' as math;
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionSentenceBuilder extends StatefulWidget {
  const CollectionSentenceBuilder({
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
  State<CollectionSentenceBuilder> createState() =>
      _CollectionSentenceBuilderState();
}

class _CollectionSentenceBuilderState extends State<CollectionSentenceBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, List<String>> _selectedWordsMap = {};
  final Map<int, bool> _isCheckedMap = {};
  final Map<int, bool> _isCorrectMap = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _addWord(int index, String word) {
    if (_isCheckedMap[index] ?? false) return;
    setState(() {
      final selected = _selectedWordsMap[index] ?? [];
      selected.add(word);
      _selectedWordsMap[index] = selected;
    });
  }

  void _removeWord(int index, int wordIdx) {
    if (_isCheckedMap[index] ?? false) return;
    setState(() {
      final selected = _selectedWordsMap[index] ?? [];
      selected.removeAt(wordIdx);
      _selectedWordsMap[index] = selected;
    });
  }

  void _checkAnswer(int index, String target) {
    final built = (_selectedWordsMap[index] ?? [])
        .join(' ')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    final targetNormalized =
        target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final isCorrect = built == targetNormalized;

    setState(() {
      _isCheckedMap[index] = true;
      _isCorrectMap[index] = isCorrect;

      // Play sound effect
      if (mounted) {
        final soundProvider = context.read<SoundEffectProvider>();
        if (isCorrect) {
          soundProvider.playCorrect();
        } else {
          soundProvider.playWrong();
        }
      }
    });

    if (isCorrect) {
      final termsWithExamples =
          widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();
      final term = termsWithExamples[index];
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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final termsWithExamples =
        widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();

    if (termsWithExamples.isEmpty) {
      return Center(
        child: Text(
          'No examples found for these terms.',
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
        final words = example.split(' ').where((w) => w.isNotEmpty).toList();
        final scrambled = List<String>.from(words)..shuffle();

        final selected = _selectedWordsMap[index] ?? [];
        final isChecked = _isCheckedMap[index] ?? false;
        final isCorrect = _isCorrectMap[index] ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: isChecked
                    ? (isCorrect ? Colors.green : Colors.red)
                    : appColors.border.withValues(alpha: 0.5),
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
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Build this sentence:',
                          style: TextStyle(
                              color: appColors.textSecondary, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Target area
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 120),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: appColors.inputBackground
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChecked
                                  ? (isCorrect ? Colors.green : Colors.red)
                                  : appColors.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selected.asMap().entries.map((entry) {
                              return GestureDetector(
                                onTap: () => _removeWord(index, entry.key),
                                child: Chip(
                                  label: Text(entry.value),
                                  backgroundColor:
                                      appColors.primary.withValues(alpha: 0.1),
                                  labelStyle: TextStyle(
                                      color: appColors.primary,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (isChecked && !isCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Correct: $example',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Options
                        if (!isChecked)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: scrambled.map((word) {
                              final countInTarget =
                                  words.where((w) => w == word).length;
                              final countInSelected =
                                  selected.where((w) => w == word).length;
                              final disabled = countInSelected >= countInTarget;

                              return GestureDetector(
                                onTap: disabled
                                    ? null
                                    : () => _addWord(index, word),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: disabled ? 0.3 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: appColors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: appColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: appColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isChecked) ...[
                          TextButton(
                            onPressed: selected.isNotEmpty
                                ? () => setState(() {
                                      _selectedWordsMap[index] = [];
                                    })
                                : null,
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: selected.isNotEmpty
                                ? () => _checkAnswer(index, example)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Check',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ] else
                          ElevatedButton(
                            onPressed: () {
                              if (index < termsWithExamples.length - 1) {
                                _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isCorrect ? Colors.green : appColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(index < termsWithExamples.length - 1
                                ? 'Next'
                                : 'Finish'),
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
    final completedCount = _isCorrectMap.values.where((v) => v).length;

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
                      if (!(_isCheckedMap[i] ?? false)) return 0;
                      return (_isCorrectMap[i] ?? false) ? 1 : 2;
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
