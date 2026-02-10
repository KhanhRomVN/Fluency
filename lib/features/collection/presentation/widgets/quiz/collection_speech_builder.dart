import 'dart:convert';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:flutter/material.dart';

class CollectionSpeechBuilder extends StatefulWidget {
  const CollectionSpeechBuilder({
    required this.collectionId,
    required this.terms,
    this.initialIndex = 0,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionSpeechBuilder> createState() =>
      _CollectionSpeechBuilderState();
}

class _CollectionSpeechBuilderState extends State<CollectionSpeechBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isRecording = false;
  SttService? _sttService;
  bool _speechEnabled = false;

  final Map<int, int> _scores = {};
  final Map<int, bool> _passed = {};
  final Map<int, String?> _transcripts = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttService = SystemSttService();
    final available = await _sttService!.initialize();
    if (mounted) {
      setState(() {
        _speechEnabled = available;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sttService?.dispose();
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

  void _startRecording(String target) async {
    if (_isRecording || !_speechEnabled) return;

    try {
      await _sttService!.startListening(
        onResult: (text, isFinal) {
          if (isFinal) {
            _processResult(text, target);
          }
        },
        localeId: 'en_US',
      );
      setState(() => _isRecording = true);
    } catch (_) {}
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    await _sttService!.stopListening();
    setState(() => _isRecording = false);
  }

  void _processResult(String transcript, String target) {
    final score = _calculateScore(transcript, target);
    final isPassed = score >= 80;

    setState(() {
      _isRecording = false;
      _scores[_currentIndex] = score;
      _transcripts[_currentIndex] = transcript;
      if (isPassed) {
        _passed[_currentIndex] = true;
      }
    });

    if (isPassed) {
      final termsWithExamples =
          widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();
      final term = termsWithExamples[_currentIndex];
      final repository = CollectionRepositoryImpl();
      final newProgress = (term.masteryLevel + 0.1).clamp(0.0, 1.0);
      repository.updateTermProgress(
        widget.collectionId,
        term.id,
        newProgress,
      );
    }
  }

  int _calculateScore(String spoken, String target) {
    final s = spoken.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
    final t = target.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');

    final sWords = s.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\s+'));

    int matches = 0;
    for (var word in tWords) {
      if (sWords.contains(word)) matches++;
    }
    return ((matches / tWords.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final termsWithExamples =
        widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();

    if (termsWithExamples.isEmpty)
      return const Scaffold(body: Center(child: Text('No examples')));

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: appColors.textPrimary),
        ),
        title: Text('Speech Builder',
            style: TextStyle(
                color: appColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemCount: termsWithExamples.length,
        itemBuilder: (context, index) {
          final term = termsWithExamples[index];
          final examples = _getExamples(term);
          final example = examples.first;
          final score = _scores[index];
          final transcript = _transcripts[index];
          final isPassed = _passed[index] ?? false;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (score != null) ...[
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Speak this sentence:',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: appColors.border, width: 2),
                  ),
                  child: Text(
                    example,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: appColors.textPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                if (transcript != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Text(
                          'You said:',
                          style: TextStyle(
                              color: appColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"$transcript"',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: appColors.textPrimary,
                              fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(example),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : appColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : appColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isRecording ? 'Listening...' : 'Hold to record',
                  style: TextStyle(
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                if (isPassed || (score != null && score < 80))
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
                          isPassed ? Colors.green : appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 56, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(index < termsWithExamples.length - 1
                        ? 'Next'
                        : 'Finish'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
