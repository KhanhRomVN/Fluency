import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class SpeakingEssay extends StatefulWidget {
  const SpeakingEssay({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<SpeakingEssay> createState() => _SpeakingEssayState();
}

class _SpeakingEssayState extends State<SpeakingEssay> {
  bool _isRecording = false;
  String? _finalTranscript;
  int? _score;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;

      if (!_isRecording) {
        // Mock finished
        _finalTranscript =
            "This is a mocked transcript of your speaking essay.";
        _score = 85;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.quiz.instruction.isNotEmpty) ...[
          RichTextParser.buildRichText(
            context,
            widget.quiz.instruction,
            onWordLongPress: widget.onWordLongPress,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16),
          ).first,
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appColors.border),
          ),
          child: Column(
            children: [
              if (widget.quiz.question.isNotEmpty)
                Text(
                  widget.quiz.question,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : appColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : appColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isRecording ? 'Recording...' : 'Tap to speak',
                style: TextStyle(color: appColors.textSecondary),
              ),
              if (_score != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Score: $_score%',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"$_finalTranscript"',
                    style: TextStyle(
                        color: appColors.textPrimary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
