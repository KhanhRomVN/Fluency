import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WritingEssay extends StatefulWidget {
  const WritingEssay({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    super.key,
    this.onWordLongPress,
    this.onCheck,
    this.onNext,
    this.onPrev,
    this.finalActionText,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<WritingEssay> createState() => _WritingEssayState();
}

class _WritingEssayState extends State<WritingEssay> {
  final TextEditingController _controller = TextEditingController();
  int _wordCount = 0;
  bool _submitted = false;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller.addListener(_updateWordCount);
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
        _submitted = progress.data?['submitted'] as bool? ?? false;
        final savedText = progress.data?['text'] as String?;
        if (savedText != null) {
          _controller.text = savedText;
          _updateWordCount();
        }

        // If already submitted, notify parent to show transcript/etc
        if (_submitted) {
          widget.onCheck?.call();
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();
    // Debounce saving? Or just save on submit?
    // Autosave text is nice. But for now, let's save on submit primarily,
    // or maybe throttling. Since there's no throttle logic here, I'll save on submit.
    // BUT user might want to save draft.
    // I won't implement debounce now to keep it simple, unless I see existing debounce.
    // I'll save on submit.

    final completedItems = _submitted ? 1 : 0;
    const totalItems = 1;
    final correctItems = _submitted ? 1 : 0;

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'writing-essay',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'submitted': _submitted,
        'text': _controller.text,
      },
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_updateWordCount)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _controller.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  void _submit() {
    // Mock submit
    setState(() {
      _submitted = true;

      // Play sound effect
      if (mounted) {
        context.read<SoundEffectProvider>().playCorrect();
      }

      _saveProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final minWords = widget.quiz.min ?? 0;
    final isEnoughWords = _wordCount >= minWords;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_android,
                size: 64,
                color: appColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Mobile View Not Supported',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This quiz type is designed for larger screens. Please use a tablet or computer for the best experience.',
                style: TextStyle(
                  fontSize: 16,
                  color: appColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instruction
                  if (widget.quiz.instruction.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RichTextParser.buildRichText(
                        context,
                        widget.quiz.instruction,
                        style: TextStyle(
                          fontSize: 16,
                          color: appColors.textPrimary,
                          height: 1.5,
                        ),
                        onWordLongPress: widget.onWordLongPress,
                      ).first,
                    ),

                  // Input Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: (val) => _updateWordCount(),
                              enabled: !_submitted,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: TextStyle(
                                fontSize: 16,
                                color: appColors.textPrimary,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your essay here...',
                                hintStyle: TextStyle(
                                  color: appColors.textSecondary
                                      .withValues(alpha: 0.7),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Words: $_wordCount',
                                  style: TextStyle(
                                    color: isEnoughWords
                                        ? Colors.green
                                        : appColors.textSecondary,
                                    fontWeight: isEnoughWords
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (minWords > 0)
                                  Text(
                                    'Minimum: $minWords',
                                    style: TextStyle(
                                      color: appColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Spacer for bottom buttons
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_submitted && (minWords == 0 || isEnoughWords))
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Submit'),
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
                  ),
                if (_submitted)
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onCheck?.call();
                      widget.onNext?.call();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(widget.finalActionText ?? 'Next question'),
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
