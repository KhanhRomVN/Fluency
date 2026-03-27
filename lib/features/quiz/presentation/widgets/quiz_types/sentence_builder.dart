import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    required this.isChecked,
    required this.onCheck,
    this.onNext,
    this.onPrev,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final bool isChecked;
  final VoidCallback onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder> {
  final List<String> _selectedWords = [];
  final List<String> _availableWords = [
    'The',
    'quick',
    'brown',
    'fox',
    'jumps',
    'over',
    'lazy',
    'dog',
  ];

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    final progress = await quizStateProvider.loadQuizProgress(
      widget.lessonId,
      widget.quizId,
    );

    if (progress != null && mounted) {
      final selected = progress.data?['selectedWords'] as List<dynamic>?;
      if (selected != null) {
        setState(() {
          _selectedWords.clear();
          _selectedWords.addAll(selected.cast<String>());
        });
      }
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'sentence-builder',
      completedItems: widget.isChecked
          ? 1
          : (_selectedWords.isNotEmpty
              ? 0
              : 0), // Not really paginated in the items sense
      totalItems: 1,
      data: {
        'selectedWords': _selectedWords,
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addWord(String word) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.add(word);
      });
      _saveProgress();
    }
  }

  void _removeWord(int index) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.removeAt(index);
      });
      _saveProgress();
    }
  }

  void _clearAll() {
    if (!widget.isChecked) {
      setState(_selectedWords.clear);
    }
  }

  bool get _canCheck => _selectedWords.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            children: [
              ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  // Instruction

                  // Selected Words Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isChecked
                            ? (true) // This quiz type logic for correctness is handled differently, keeping it simple for now or checking if there's a state
                                ? appColors.border.withValues(alpha: 0.3)
                                : appColors.border.withValues(alpha: 0.3)
                            : _selectedWords.isEmpty
                                ? appColors.border.withValues(alpha: 0.3)
                                : appColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: appColors.cardBackground,
                    ),
                    child: _selectedWords.isEmpty
                        ? Text(
                            'Tap words below to build your sentence',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: appColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectedWords.asMap().entries.map((entry) {
                              return GestureDetector(
                                onTap: () => _removeWord(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isChecked
                                        ? appColors.background
                                        : appColors.cardBackground,
                                    border: Border.all(
                                      color: appColors.border,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: widget.isChecked
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 2,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: appColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (!widget.isChecked) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.close,
                                          size: 16,
                                          color: appColors.textSecondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  if (_selectedWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.5),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Available Words
                  Text(
                    'Available Words:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _availableWords.map((word) {
                      return GestureDetector(
                        onTap: () => _addWord(word),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: appColors.cardBackground,
                            border: Border.all(
                              color: appColors.border,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              color: appColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Check Button
        if (_canCheck && !widget.isChecked)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.background,
              border: Border(
                top: BorderSide(color: appColors.border),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary.withValues(alpha: 0.15),
                  foregroundColor: appColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        if (widget.quiz.audio != null && widget.quiz.audio!.isNotEmpty)
          const SizedBox(height: 120),
      ],
    );
  }
}
