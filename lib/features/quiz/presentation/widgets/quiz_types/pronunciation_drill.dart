import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

// Placeholder for pronunciation drill items
class PronunciationDrillItem {
  final String id;
  final String text;
  final String pronunciation;

  const PronunciationDrillItem({
    required this.id,
    required this.text,
    required this.pronunciation,
  });
}

class PronunciationDrill extends StatefulWidget {
  const PronunciationDrill({
    super.key,
    required this.quiz,
  });

  final Quiz quiz;

  @override
  State<PronunciationDrill> createState() => _PronunciationDrillState();
}

class _PronunciationDrillState extends State<PronunciationDrill> {
  int _currentIndex = 0;
  bool _isRecording = false;
  int? _userScore;

  // Placeholder drill items
  final List<PronunciationDrillItem> _drills = const [
    PronunciationDrillItem(
      id: '1',
      text: 'Hello World',
      pronunciation: '/həˈloʊ wɜːrld/',
    ),
  ];

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        // Simulate scoring
        _userScore = 85;
      }
    });
  }

  void _nextDrill() {
    if (_currentIndex < _drills.length - 1) {
      setState(() {
        _currentIndex++;
        _userScore = null;
      });
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _userScore = null;
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final currentDrill = _drills[_currentIndex];

    return Column(
      children: [
        // Instruction
        if (widget.quiz.instruction.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DefaultTextStyle(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: RichTextParser.buildRichText(
                  context,
                  widget.quiz.instruction,
                ),
              ),
            ),
          ),
          Divider(height: 32, color: appColors.border),
        ],
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentDrill.text,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textPrimary,
                                  fontSize: 16,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentDrill.pronunciation,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: appColors.textSecondary,
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                ),
                      ),
                      if (_userScore != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Score: $_userScore%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: _userScore! >= 70
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _toggleRecording,
                backgroundColor: _isRecording ? Colors.red : appColors.primary,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
              if (_userScore != null) ...[
                const SizedBox(width: 16),
                if (_currentIndex < _drills.length - 1)
                  ElevatedButton.icon(
                    onPressed: _nextDrill,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _restart,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart'),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
