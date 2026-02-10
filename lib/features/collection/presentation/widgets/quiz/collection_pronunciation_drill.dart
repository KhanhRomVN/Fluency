import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionPronunciationDrill extends StatefulWidget {
  const CollectionPronunciationDrill({
    required this.collectionId,
    required this.terms,
    this.initialIndex = 0,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionPronunciationDrill> createState() =>
      _CollectionPronunciationDrillState();
}

class _CollectionPronunciationDrillState
    extends State<CollectionPronunciationDrill> {
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _speak(String text) async {
    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isInitialized) {
      await ttsProvider.initService();
    }
    await ttsProvider.ttsService?.speak(text);
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
    final isPassed = score >= 70;

    setState(() {
      _isRecording = false;
      _scores[_currentIndex] = score;
      _transcripts[_currentIndex] = transcript;
      if (isPassed) {
        _passed[_currentIndex] = true;
      }
    });

    if (isPassed) {
      final term = widget.terms[_currentIndex];
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
    final s = spoken.toLowerCase().trim();
    final t = target.toLowerCase().trim();
    if (s == t) return 100;

    // Simple overlap check
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
    final terms = widget.terms;

    if (terms.isEmpty)
      return const Scaffold(body: Center(child: Text('No terms')));

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: appColors.textPrimary),
        ),
        title: Text('Pronunciation',
            style: TextStyle(
                color: appColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: terms.length,
        itemBuilder: (context, index) {
          final term = terms[index];
          final score = _scores[index];
          final transcript = _transcripts[index];
          final isPassed = _passed[index] ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                  const SizedBox(height: 8),
                ],
                Text(
                  term.term,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (term.phonetics.isNotEmpty)
                  Text(
                    term.phonetics.first,
                    style:
                        TextStyle(fontSize: 18, color: appColors.textSecondary),
                  ),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => _speak(term.term),
                  icon:
                      Icon(Icons.volume_up, color: appColors.primary, size: 32),
                ),
                const Spacer(),
                if (transcript != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'You said: "$transcript"',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: appColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(term.term),
                  onLongPressEnd: (_) => _stopRecording(),
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
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording ? 'Listening...' : 'Hold to speak',
                  style: TextStyle(
                    color: _isRecording ? Colors.red : appColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                if (isPassed || (score != null && score < 70))
                  ElevatedButton(
                    onPressed: () {
                      if (index < terms.length - 1) {
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
                          horizontal: 48, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(index < terms.length - 1 ? 'Next' : 'Finish'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
