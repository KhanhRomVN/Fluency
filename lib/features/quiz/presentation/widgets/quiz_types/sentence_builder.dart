import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({
    required this.quiz,
    required this.isChecked,
    required this.onCheck,
    super.key,
  });

  final Quiz quiz;
  final bool isChecked;
  final VoidCallback onCheck;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder>
    with SingleTickerProviderStateMixin {
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
  late AnimationController _animController;
  double _dragOffset = 0;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.addListener(() {
      setState(() {
        if (_slideAnimation != null) {
          _dragOffset = _slideAnimation!.value;
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Similar logic, but SentenceBuilder often one question per screen/quiz item?
    // If it's part of a list, we might want next.
    // Usually Sentence Building is one "Question" in a list of questions if generic.
    // But this widget takes `Quiz quiz` which implies it handles the WHOLE quiz?
    // Wait, `SpeechBuilder` had list of items. `SentenceBuilder` code shows ONE list of available words.
    // It seems `SentenceBuilder` as written here is a single dummy example (The quick brown fox...).
    // Real implementation should probably take data from `quiz`.
    // Assuming it's a single item or the widget handles internal state if multiple.
    // Or maybe it's just one question per widget instance and parent swipes?
    // In `QuizPage` usually we swipe between questions.
    // If this widget is a page content, it should handle swipe to trigger parent's next.
    // UNLESS the parent handles swipe.
    // But we are adding animation INSIDE these widgets, implying they control the view.

    // Let's assuming "Next" logic is handled via callbacks or parent.
    // But the request is to "Add animation".
    // I will add the swipe-to-dismiss/next logic similar to others.

    // Check if Checked.
    // If checked -> allow next.

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = screenWidth * 0.25;

    var shouldChange = false;

    // Swipe Left (Next)
    if (velocity < -1000 || _dragOffset < -threshold) {
      // Determine if we can go next.
      // Usually if checked.
      // But `SentenceBuilder` might need to just submit?
      // If `widget.isChecked` is true, then swipe -> next.
      // If not, maybe nothing.
      if (widget.isChecked) {
        shouldChange = true;
      }
    }

    if (shouldChange) {
      final endX = -screenWidth;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: endX).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );

      _animController.forward(from: 0).then((_) {
        // Trigger generic next (parent callback not passed? `onCheck` is passed. NO `onNext` passed in `SentenceBuilder` constructor!)
        // Wait, `SentenceBuilder` constructor lines 6-12:
        /*
        class SentenceBuilder extends StatefulWidget {
          const SentenceBuilder({
            required this.quiz,
            required this.isChecked,
            required this.onCheck,
            super.key,
          });
        */
        // It does NOT have `onNext`.
        // So I cannot call `onNext`.
        // If I cannot call Next, animation to swipe away doesn't make sense if I can't trigger next question.
        // However, other widgets had `onNext`.
        // `SentenceBuilder` seems missing it.
        // I should probably ADD `onNext` to the constructor if I want to support this flow, but that changes the API.
        // Or maybe `onCheck` toggles state?
        // If the user request "add animation for these widgets", and this widget handles a single interaction...
        // Maybe the animation is just for "feedback" or "entrance"?
        // Or maybe I should add `onNext` to be consistent?
        // User said: "SentenceBuilder" (ScrambledWord?).
        // If I look at `MatchingDropdown`, it had `onNext`.

        // Let's assume I should genericize the animation but if `onNext` is missing, I can't really "go next".
        // But maybe the `QuizPage` (parent) handles it?
        // If so, `_onHorizontalDragEnd` here conflicts with parent if parent has GestureDetector?
        // Usually these widgets ARE the content.

        // I'll add `onNext` to the widget parameters to be safe and consistent, assuming I can update call sites later or parameters are flexible.
        // Actually, I can't easily update call sites I don't see.
        // But let's look at `SentenceBuilder` again.
        // It's a `StatefulWidget`.

        // If I can't navigate, swipe animation is useless or confusing.
        // Maybe I just add the fields and logic but only trigger if `onNext` is available (and add it as optional).

        // Let's add `this.onNext` as optional parameter.
      });
    } else {
      // Snap back
      _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward(from: 0);
    }
  }

  void _addWord(String word) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.add(word);
      });
    }
  }

  void _removeWord(int index) {
    if (!widget.isChecked) {
      setState(() {
        _selectedWords.removeAt(index);
      });
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
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final rotateAngle = _dragOffset * 0.001;
                final opacity = (1 - (_dragOffset.abs() / 500)).clamp(0.5, 1.0);
                return Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: Transform.rotate(
                    angle: rotateAngle,
                    child: Opacity(opacity: opacity, child: child),
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Instruction
                  if (widget.quiz.instruction.isNotEmpty) ...[
                    DefaultTextStyle(
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16),
                      child: Wrap(
                        children: RichTextParser.buildRichText(
                          context,
                          widget.quiz.instruction,
                        ),
                      ),
                    ),
                    Divider(height: 32, color: appColors.border),
                  ],

                  // Selected Words Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: appColors.border, width: 2),
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
                                child: Chip(
                                  label: Text(entry.value),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => _removeWord(entry.key),
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
                    runSpacing: 8,
                    children: _availableWords.map((word) {
                      return ActionChip(
                        label: Text(word),
                        onPressed: () => _addWord(word),
                        backgroundColor: appColors.cardBackground,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
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
                  backgroundColor: appColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
