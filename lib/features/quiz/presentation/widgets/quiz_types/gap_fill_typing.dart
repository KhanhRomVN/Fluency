import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GapFillTyping extends StatefulWidget {
  const GapFillTyping({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    required this.question,
    required this.answers,
    this.title,
    this.instruction,
    this.onCheck,
    this.onShowExplain,
    this.hasAudio = false,
    this.onWordLongPress,
    this.onNext,
    this.onPrev,
    this.finalActionText,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final String question;
  final List<QuizAnswer> answers;
  final String? title;
  final String? instruction;
  final VoidCallback? onCheck;
  final void Function(String explanation)? onShowExplain;
  final bool hasAudio;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final String? finalActionText;

  @override
  State<GapFillTyping> createState() => _GapFillTypingState();
}

class _GapFillTypingState extends State<GapFillTyping> {
  // Map of gap ID to text controller
  final Map<String, TextEditingController> _controllers = {};
  bool _isChecked = false;
  bool _areAllGapsFilled = false;

  // Animation variables
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _parseGaps();

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
        _isChecked = progress.data?['isChecked'] as bool? ?? false;

        // Restore user answers
        final savedAnswers =
            progress.data?['userAnswers'] as Map<String, dynamic>?;
        if (savedAnswers != null) {
          savedAnswers.forEach((key, value) {
            if (_controllers.containsKey(key)) {
              _controllers[key]!.text = value as String;
            }
          });
        }

        // Check if all filled based on restored data
        _checkIfAllGapsFilled();

        // If already checked, notify parent to show transcript/etc
        if (_isChecked) {
          widget.onCheck?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant GapFillTyping oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      // Reset state when question changes
      setState(() {
        _isChecked = false;
        _areAllGapsFilled = false;
      });
      _parseGaps();
    }
  }

  void _parseGaps() {
    _controllers.clear(); // Clear old controllers if re-parsing
    final regex = RegExp(r"id=['\u0022](.*?)['\u0022]", caseSensitive: false);
    final matches = regex.allMatches(widget.question);
    for (final match in matches) {
      final id = match.group(1);
      if (id != null) {
        _controllers[id] = TextEditingController();
        _controllers[id]!.addListener(_checkIfAllGapsFilled);
      }
    }
    _checkIfAllGapsFilled();
  }

  void _checkIfAllGapsFilled() {
    final allFilled = _controllers.values.every((c) => c.text.isNotEmpty);
    if (allFilled != _areAllGapsFilled) {
      setState(() {
        _areAllGapsFilled = allFilled;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final borderColor = _isChecked
        ? (_allGapsCorrect()
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.red.withValues(alpha: 0.5))
        : Colors.grey.withValues(alpha: 0.3);

    return Stack(
      children: [
        // Main Content Area
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: Theme.of(context).textTheme.copyWith(
                                      bodyMedium: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 16),
                                    ),
                              ),
                              child: _buildContent(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
              child: _buildActionButtons(appColors),
            ),
          ],
        ),
      ],
    );
  }

  bool _allGapsCorrect() {
    for (final answer in widget.answers) {
      final controller = _controllers[answer.id];
      if (controller != null) {
        final userAnswer = controller.text;
        final isCorrect = answer.answer.any(
          (ans) => userAnswer.toLowerCase().trim() == ans.toLowerCase().trim(),
        );
        if (!isCorrect) return false;
      }
    }
    return true;
  }

  Widget _buildActionButtons(AppColorsExtension appColors) {
    // Determine button text and action
    String text;
    VoidCallback? onPressed;
    Color? backgroundColor = appColors.primary.withValues(alpha: 0.15);
    Color? foregroundColor = appColors.primary;

    if (_isChecked) {
      text = widget.finalActionText ?? 'Next';
      onPressed = widget.onNext;
    } else {
      text = 'Check answers';
      // Enable only if all gaps are filled
      onPressed = _areAllGapsFilled
          ? () {
              setState(() {
                _isChecked = true;
              });

              // Check if all are correct to play sound
              bool allCorrect = true;
              for (final answer in widget.answers) {
                final controller = _controllers[answer.id];
                if (controller != null) {
                  final userAnswer = controller.text;
                  final isCorrect = answer.answer.any(
                    (ans) =>
                        userAnswer.toLowerCase().trim() ==
                        ans.toLowerCase().trim(),
                  );
                  if (!isCorrect) {
                    allCorrect = false;
                    break;
                  }
                }
              }

              if (mounted) {
                final soundProvider = context.read<SoundEffectProvider>();
                if (allCorrect) {
                  soundProvider.playCorrect();
                } else {
                  soundProvider.playWrong();
                }
              }

              _saveProgress();
              widget.onCheck?.call();
            }
          : null;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              appColors.textPrimary.withValues(alpha: 0.05),
          disabledForegroundColor: appColors.textPrimary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Parses the question string and builds a list of widgets.
  Widget _buildContent(BuildContext context) {
    // Sanitize question string to remove any hidden characters or leading spaces
    // and replace newline tags with actual newlines
    final sanitizedQuestion = widget.question
        .trim()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll('</n>', '\n')
        .replaceAll('</n', '\n');
    return _buildRichText(context, sanitizedQuestion, isQuestion: true);
  }

  /// Parses the text content and builds a list of widgets.
  Widget _buildRichText(
    BuildContext context,
    String content, {
    bool isQuestion = false,
  }) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // Use buildTextSpans to get InlineSpans and wrap them in a single Text.rich
    // This allows natural text wrapping with inline widgets (gaps).
    final spans = RichTextParser.buildTextSpans(
      context,
      content,
      isQuestion: isQuestion,
      onGapFound: (id) => _createGapWidget(id, appColors, context),
      onWordLongPress: widget.onWordLongPress,
    );

    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.8, // Comfortable line height
            color: appColors.textPrimary,
          ),
    );
  }

  Widget _createGapWidget(
    String id,
    AppColorsExtension appColors,
    BuildContext context,
  ) {
    // Find the answer for this gap
    final answer = widget.answers.firstWhere(
      (a) => a.id == id,
      orElse: () => const QuizAnswer(id: '', answer: [], explain: ''),
    );
    final controller = _controllers[id]!;
    final userAnswer = controller.text;
    final isCorrect = answer.answer.any(
      (ans) => userAnswer.toLowerCase().trim() == ans.toLowerCase().trim(),
    );

    if (_isChecked) {
      Widget content;
      if (isCorrect) {
        // Correct case: Text in Primary Color
        content = Text(
          userAnswer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors.primary,
                fontWeight: FontWeight.bold,
              ),
        );
      } else {
        // Incorrect case: User text red strikethrough + Correct text primary
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userAnswer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.red,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              answer.answer.firstOrNull ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      }

      return InkWell(
        onTap: () => _showExplanation(context, answer),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: content,
        ),
      );
    } else {
      // Normal Input Case
      return IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: TextField(
            controller: controller,
            onChanged: (value) {
              _saveProgress();
              _checkIfAllGapsFilled();
            },
            // maxLength: maxLength, // Removed explicit maxLength to match React "auto-width" feel better visually
            maxLengthEnforcement: MaxLengthEnforcement.none,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) =>
                null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              hintText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: appColors.primary.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: appColors.primary,
                  width: 2,
                ),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showExplanation(BuildContext context, QuizAnswer answer) {
    if (widget.onShowExplain != null) {
      // If callback provided, use it
      final explanation = answer.explain.isNotEmpty
          ? answer.explain
          : '<p>No explanation available.</p>';
      widget.onShowExplain!(explanation);
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Prepare data to save
    final userAnswers = <String, String>{};
    _controllers.forEach((key, controller) {
      userAnswers[key] = controller.text;
    });

    // Calculate correctness for progress
    // Count how many gaps are correct
    final totalGaps = widget.answers.length;
    final totalScore = widget.quiz.totalScore;
    final filledScore = widget.answers
        .where((a) => _controllers[a.id]?.text.isNotEmpty == true)
        .fold(0, (sum, a) => sum + a.score);

    var correctCount = 0;
    final Map<String, bool> correctness = {};
    if (_isChecked) {
      for (final answer in widget.answers) {
        final controller = _controllers[answer.id];
        if (controller != null) {
          final userAnswer = controller.text;
          final isCorrect = answer.answer.any(
            (ans) =>
                userAnswer.toLowerCase().trim() == ans.toLowerCase().trim(),
          );
          if (isCorrect) correctCount += answer.score;
          correctness[answer.id] = isCorrect;
        }
      }
    } else {
      // If not checked, mark as "correct" (primary color) if filled
      for (final answer in widget.answers) {
        final controller = _controllers[answer.id];
        if (controller != null && controller.text.isNotEmpty) {
          correctness[answer.id] = true;
        }
      }
    }

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'gap-fill-typing',
      completedItems: filledScore,
      totalItems: totalScore,
      correctItems: correctCount,
      data: {
        'isChecked': _isChecked,
        'userAnswers': userAnswers,
        'correctCount': correctCount,
        'totalGaps': totalGaps,
        'correctness': correctness,
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Painters (Copied from MultipleChoice for consistency)
// -----------------------------------------------------------------------------
