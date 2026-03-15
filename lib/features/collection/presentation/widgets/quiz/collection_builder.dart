import 'dart:convert';
import 'dart:math' as math;
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionBuilder extends StatefulWidget {
  const CollectionBuilder({
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
  State<CollectionBuilder> createState() => _CollectionBuilderState();
}

class _CollectionBuilderState extends State<CollectionBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, List<String>> _selectedLettersMap = {};
  final Map<int, bool> _isCheckedMap = {};
  final Map<int, bool?> _isCorrectMap =
      {}; // Changed to bool? to match QuizBuilder

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

  void _onLetterTap(int index, String letter, List<String> available) {
    if (_isCheckedMap[index] ?? false) return;

    setState(() {
      final selected = _selectedLettersMap[index] ?? [];
      selected.add(letter);
      _selectedLettersMap[index] = selected;
    });
  }

  void _removeLetter(int index) {
    if (_isCheckedMap[index] ?? false) return;

    setState(() {
      final selected = _selectedLettersMap[index] ?? [];
      if (selected.isNotEmpty) {
        selected.removeLast();
      }
    });
  }

  void _resetItem(int index) {
    setState(() {
      _selectedLettersMap[index] = [];
      _isCheckedMap[index] = false;
      _isCorrectMap[index] = null;
    });
  }

  void _checkAnswer(int index) {
    final term = widget.terms[index];
    final target = term.term.replaceAll(' ', '').toLowerCase();
    final built = (_selectedLettersMap[index] ?? []).join('').toLowerCase();
    final isCorrect = built == target;

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

      if (isCorrect) {
        final repository = CollectionRepositoryImpl();
        final newProgress = (term.masteryLevel + 0.1).clamp(0.0, 1.0);
        repository.updateTermProgress(
          widget.collectionId,
          term.id,
          newProgress,
        );

        // Auto-next logic:
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _currentIndex == index) {
            if (_currentIndex < widget.terms.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final terms = widget.terms;

    if (terms.isEmpty) {
      return Center(
        child: Text(
          'No terms available',
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
      itemCount: terms.length,
      itemBuilder: (context, index) {
        final term = terms[index];
        final targetLetters =
            term.term.split('').where((e) => e.trim().isNotEmpty).toList();
        final selectedLetters = _selectedLettersMap[index] ?? [];
        final isChecked = _isCheckedMap[index] ?? false;
        final isCorrect = _isCorrectMap[index];

        // Generate scrambled letters if not exists
        final available = targetLetters.toList()..shuffle(math.Random(index));

        final borderColor = isChecked
            ? (isCorrect ?? false ? Colors.green : Colors.red)
            : Colors.grey.withValues(alpha: 0.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            children: [
              Container(
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Build this word:',
                                style: TextStyle(
                                  color: appColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              if (term.definition.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _getDefinitionText(term.definition),
                                  style: TextStyle(
                                    color: appColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Built Word Display
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(minHeight: 100),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? (isCorrect ?? false
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1))
                                      : appColors.cardBackground,
                                  border: Border.all(
                                    color: isChecked
                                        ? (isCorrect ?? false
                                            ? Colors.green
                                            : Colors.red)
                                        : appColors.primary
                                            .withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: selectedLetters.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Tap letters below to build',
                                          style: TextStyle(
                                            color: appColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: selectedLetters
                                            .asMap()
                                            .entries
                                            .map((e) {
                                          return GestureDetector(
                                            onTap: isChecked
                                                ? null
                                                : () => _removeLetter(index),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isChecked
                                                    ? appColors.background
                                                    : appColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                e.value,
                                                style: TextStyle(
                                                  color: isChecked
                                                      ? appColors.textPrimary
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),

                              // Correct Answer Feedback
                              if (isChecked && isCorrect == false) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Correct word:',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        term.term,
                                        style: TextStyle(
                                          color: appColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Letter Blocks (Available)
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 14,
                                  children:
                                      available.asMap().entries.map((entry) {
                                    final letter = entry.value;
                                    final countInSelected = selectedLetters
                                        .where((l) => l == letter)
                                        .length;
                                    final totalInAvailable = available
                                        .where((l) => l == letter)
                                        .length;
                                    final isUsed =
                                        countInSelected >= totalInAvailable;

                                    return GestureDetector(
                                      onTap: isUsed || isChecked
                                          ? null
                                          : () => _onLetterTap(
                                              index, letter, available),
                                      child: AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        opacity:
                                            isUsed || isChecked ? 0.5 : 1.0,
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isUsed
                                                ? appColors.background
                                                : appColors.cardBackground,
                                            border: Border.all(
                                                color: appColors.border),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: isUsed
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.05),
                                                      blurRadius: 2,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: isUsed
                                                    ? appColors.textSecondary
                                                    : appColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      if (isChecked || selectedLetters.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [_buildFooterActions(appColors, index)],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
    final completedCount = _isCheckedMap.values.where((v) => v).length;

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

  Widget _buildFooterActions(AppColorsExtension appColors, int index) {
    final isChecked = _isCheckedMap[index] ?? false;
    final selected = _selectedLettersMap[index] ?? [];
    final term = widget.terms[index];
    final targetLength =
        term.term.split('').where((e) => e.trim().isNotEmpty).length;

    if (isChecked) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          if (index < widget.terms.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            Navigator.pop(context);
          }
        },
        child: Text(index < widget.terms.length - 1 ? 'Next' : 'Finish',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (selected.length == targetLength) {
      return ElevatedButton(
        onPressed: () => _checkAnswer(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary.withValues(alpha: 0.15),
          foregroundColor: appColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child:
            const Text('Check', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: () => _resetItem(index),
      style: ElevatedButton.styleFrom(
        backgroundColor: appColors.textSecondary.withValues(alpha: 0.15),
        foregroundColor: appColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
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
