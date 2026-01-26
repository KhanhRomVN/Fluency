import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class Speaking extends StatefulWidget {
  const Speaking({
    required this.quiz,
    super.key,
    this.onCheck,
    this.onNext,
  });

  final Quiz quiz;
  final VoidCallback? onCheck;
  final VoidCallback? onNext;

  @override
  State<Speaking> createState() => _SpeakingState();
}

class _SpeakingState extends State<Speaking>
    with SingleTickerProviderStateMixin {
  int _activeIndex = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _stepSubmitted = {};
  bool _isRecording = false;

  late final List<QuizQuestion> _questions;

  // Animation variables
  late AnimationController _animController;
  double _dragOffset = 0;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _questions = widget.quiz.questions.isNotEmpty
        ? widget.quiz.questions
        : [
            QuizQuestion(
              id: widget.quiz.id,
              question: widget.quiz.question,
              options: const [],
              answer: '',
              validAnswers: const [],
              explain: '',
            ),
          ];

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
    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.primaryVelocity ?? 0;
    final threshold = screenWidth * 0.25;

    // Check if we should change question
    var shouldChange = false;
    var direction = 0; // -1: Next (Swipe Left), 1: Prev (Swipe Right)

    if (velocity < -1000 || _dragOffset < -threshold) {
      if (_hasNext) {
        shouldChange = true;
        direction = -1;
      }
    } else if (velocity > 1000 || _dragOffset > threshold) {
      if (_activeIndex > 0) {
        shouldChange = true;
        direction = 1;
      }
    }

    if (shouldChange) {
      final endX = direction == -1 ? -screenWidth : screenWidth;
      _slideAnimation = Tween<double>(begin: _dragOffset, end: endX).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );

      _animController.forward(from: 0).then((_) {
        setState(() {
          if (direction == -1) {
            _handleNext();
          } else {
            _activeIndex--;
            _isRecording = false; // Reset recording on back too?
          }
          // Reset offset to other side for "coming in" animation
          _dragOffset = direction == -1 ? screenWidth : -screenWidth;
          _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut),
          );
          _animController.forward(from: 0);
        });
      });
    } else {
      _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      );
      _animController.forward(from: 0);
    }
  }

  void _animateToNextQuestion() {
    final screenWidth = MediaQuery.of(context).size.width;
    _slideAnimation = Tween<double>(begin: 0, end: -screenWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward(from: 0).then((_) {
      setState(() {
        _handleNext();
        _dragOffset = screenWidth;
        _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
        _animController.forward(from: 0);
      });
    });
  }

  bool get _hasNext => _activeIndex < _questions.length - 1;
  String get _currentAnswer => _answers[_activeIndex] ?? '';
  bool get _isCurrentSubmitted => _stepSubmitted[_activeIndex] ?? false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _handleSubmitStep() {
    setState(() {
      _stepSubmitted[_activeIndex] = true;
      _isRecording = false;
    });
  }

  void _handleNext() {
    setState(() {
      _activeIndex++;
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final currentQuestion = _questions[_activeIndex];

    return Stack(
      children: [
        // Main Content
        Positioned.fill(
          bottom: 100,
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

                  // Question
                  if (currentQuestion.question.isNotEmpty)
                    Text(
                      currentQuestion.question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: appColors.textPrimary,
                            height: 1.5,
                            fontSize: 16,
                          ),
                    ),
                  const SizedBox(height: 16),

                  // Answer Input
                  Text(
                    'Your Answer / Notes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),

                  if (_isCurrentSubmitted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appColors.cardBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentAnswer.isEmpty
                            ? '(No answer provided)'
                            : _currentAnswer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: appColors.textPrimary,
                              fontStyle: _currentAnswer.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                      ),
                    )
                  else
                    TextField(
                      maxLines: 8,
                      controller: TextEditingController(text: _currentAnswer),
                      onChanged: (value) {
                        setState(() {
                          _answers[_activeIndex] = value;
                        });
                      },
                      enabled: !_isCurrentSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: TextStyle(color: appColors.textSecondary),
                        filled: true,
                        fillColor: appColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: appColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: appColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: appColors.primary, width: 2),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: appColors.textPrimary,
                          ),
                    ),

                  // Sample Answer (shown after submit)
                  if (_isCurrentSubmitted &&
                      widget.quiz.example != null &&
                      widget.quiz.example!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sample Answer',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appColors.cardBackground.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: appColors.border),
                      ),
                      child: Text(
                        widget.quiz.example!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: appColors.textPrimary,
                              height: 1.6,
                              fontSize: 16,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Floating Bottom Controls
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: appColors.background.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: appColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mic Toggle
                  IconButton(
                    onPressed: _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.mic_off : Icons.mic,
                      color:
                          _isRecording ? Colors.white : appColors.textPrimary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isRecording ? Colors.red : appColors.cardBackground,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (widget.quiz.audio != null &&
                      widget.quiz.audio!.isNotEmpty)
                    const SizedBox(height: 120),

                  // Submit or Next Button
                  if (!_isCurrentSubmitted && _currentAnswer.trim().isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _handleSubmitStep,
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),

                  if (_isCurrentSubmitted)
                    ElevatedButton.icon(
                      onPressed: _hasNext
                          ? _animateToNextQuestion
                          : () {
                              widget.onCheck?.call();
                              widget.onNext?.call();
                            },
                      icon: Icon(
                        _hasNext ? Icons.chevron_right : Icons.check_circle,
                        size: 20,
                      ),
                      label: Text(_hasNext ? 'Next' : 'Next question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
