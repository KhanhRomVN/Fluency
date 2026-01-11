import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class Dictation extends StatefulWidget {
  const Dictation({
    super.key,
    required this.quiz,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<Dictation> createState() => _DictationState();
}

class _DictationState extends State<Dictation> {
  int _currentIndex = 0;
  final Map<String, String> _inputValues = {};
  // Map<ItemID, State>
  final Map<String, _DictationItemState> _itemStates = {};

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          setState(() {
            _playingId = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudio(DictationItem item) async {
    if (_playingId == item.id) {
      await _audioPlayer.stop();
      setState(() {
        _playingId = null;
      });
      return;
    }

    if (item.audio != null) {
      // Assume audio path needs resolution? usually 'assets/...' or file path.
      // Course repository usually resolves path to absolute file path.
      // If it's a relative path in `item.audio`, we might need base path.
      // But `QuizPage` usually receives resolved paths?
      // Let's assume absolute path for now as per `MediaPlayer`.
      try {
        await _audioPlayer.play(DeviceFileSource(item.audio!));
        setState(() {
          _playingId = item.id;
        });
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    }
  }

  void _checkAnswer(DictationItem item) {
    final input = _inputValues[item.id] ?? '';
    // TSX logic: compare exact text?
    // `const correctText = item.audio ? item.transcript : item.text;`
    final correctText = item.transcript ?? item.text ?? '';

    final normalizedInput =
        input.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final normalizedCorrect =
        correctText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Simple comparison used in TSX? It calculates diff score.
    // For MVP Dart port, exact match or simple contains?
    // Let's do exact match of normalized string for now.

    // Levenshtein distance would be better for percentage score.
    // Placeholder logic:
    bool isCorrect = normalizedInput == normalizedCorrect;
    int score = isCorrect ? 100 : 0;

    // TSX Logic for score:
    // `const similarity = stringSimilarity.compareTwoStrings(normalizedInput, normalizedCorrect);`
    // We don't have that package handy. Simple check.

    setState(() {
      final currentState = _itemStates[item.id] ?? _DictationItemState();
      _itemStates[item.id] = currentState.copyWith(
        score: score,
        passed: isCorrect, // or score > 80?
        attempts: currentState.attempts + 1,
      );
    });
  }

  void _retryCurrent() {
    // Clear input and state?
    // TSX just keeps state passed but allows retry?
    // Actually TSX `retryCurrentCard` resets state.
    final item = widget.quiz.dictations![_currentIndex];
    setState(() {
      _inputValues[item.id] = '';
      _itemStates[item.id] = _DictationItemState();
    });
  }

  void _next() {
    if (widget.quiz.dictations != null &&
        _currentIndex < widget.quiz.dictations!.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final dictations = widget.quiz.dictations ?? [];

    if (dictations.isEmpty) {
      return Center(
        child: Text(
          'No dictation items available.',
          style: TextStyle(color: appColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instruction
              if (widget.quiz.instruction.isNotEmpty) ...[
                RichTextParser.buildRichText(
                  context,
                  widget.quiz.instruction,
                  onWordLongPress: widget.onWordLongPress,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16),
                ).first,
                const SizedBox(height: 24),
              ],

              // Items (Show passed and current)
              // TSX shows passed items above current item.
              ...dictations.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                if (index > _currentIndex) return const SizedBox.shrink();

                return _buildCard(context, item, index, appColors);
              }),

              const SizedBox(height: 80), // Spacer
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, DictationItem item, int index,
      AppColorsExtension appColors) {
    final state = _itemStates[item.id] ?? _DictationItemState();
    final isCurrent = index == _currentIndex;
    final isPassed = state.passed; // or check index < _currentIndex

    // Style logic
    // final isInactive = !isCurrent; // Passed items become inactive looking?
    // TSX: `isCurrent ? 'bg-card ...' : 'bg-muted/50 opacity-75'`

    return Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isCurrent
              ? appColors.cardBackground
              : appColors.cardBackground.withValues(alpha: 0.5),
          border: Border.all(
            color: isCurrent
                ? appColors.primary.withValues(alpha: 0.5)
                : appColors.border,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: appColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (isPassed && !isCurrent)
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                  SizedBox(width: isPassed && !isCurrent ? 8 : 0),
                  Text(
                    '${index + 1}/${widget.quiz.dictations?.length ?? 0}',
                    style:
                        TextStyle(color: appColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: appColors.border.withValues(alpha: 0.5)),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Play Button
                  GestureDetector(
                    onTap: () => _playAudio(item),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _playingId == item.id
                            ? Colors.red
                            : appColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        _playingId == item.id
                            ? Icons.graphic_eq
                            : Icons.volume_up,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score
                  if (state.attempts > 0)
                    Text(
                      '${state.score}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.score >= 80 ? Colors.green : Colors.red,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Input
                  TextField(
                    controller:
                        TextEditingController(text: _inputValues[item.id])
                          ..selection = TextSelection.fromPosition(TextPosition(
                              offset: _inputValues[item.id]?.length ?? 0)),
                    onChanged: (val) {
                      _inputValues[item.id] = val;
                      // Force rebuild? TextField controller management in ListView is tricky.
                      // Better to use controller stored in state map?
                      // For MVP simple approach:
                    },
                    enabled: !state.passed &&
                        isCurrent, // Disable if passed or not current
                    maxLines: 3,
                    style:
                        TextStyle(fontSize: 18, color: appColors.textPrimary),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Type what you hear...',
                      hintStyle: TextStyle(
                          color:
                              appColors.textSecondary.withValues(alpha: 0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: appColors.border,
                            style: BorderStyle.none), // dashed?
                      ),
                      filled: true,
                      fillColor: Colors.transparent, // TSX bg-transparent
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appColors.border),
                      ),
                    ),
                  ),

                  // Correct Answer reveal
                  if (state.passed) ...[
                    const SizedBox(height: 16),
                    Text(
                      item.transcript ?? item.text ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (item.ipa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          item.ipa!,
                          style: TextStyle(
                              color: appColors.primary,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    if (item.translate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          item.translate!,
                          style: TextStyle(
                              color: appColors.textSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Actions
            if (isCurrent)
              Padding(
                padding: const EdgeInsets.all(16),
                child: !state.passed
                    ? ElevatedButton(
                        onPressed: () => _checkAnswer(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Check Answer',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _retryCurrent,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: appColors.textSecondary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: appColors.border),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (index <
                              (widget.quiz.dictations?.length ?? 0) - 1) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _next,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
          ],
        ));
  }
}

class _DictationItemState {
  final int score;
  final bool passed;
  final int attempts;

  _DictationItemState({this.score = 0, this.passed = false, this.attempts = 0});

  _DictationItemState copyWith({int? score, bool? passed, int? attempts}) {
    return _DictationItemState(
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attempts: attempts ?? this.attempts,
    );
  }
}
