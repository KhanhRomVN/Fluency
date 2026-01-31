import 'dart:async';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:universal_io/io.dart';

class ScriptedChat extends StatefulWidget {
  const ScriptedChat({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    super.key,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;

  @override
  State<ScriptedChat> createState() => _ScriptedChatState();
}

class _ScriptedChatState extends State<ScriptedChat> {
  String? _userRole;
  String? _activeMessageId;
  final Map<String, _MessageScore> _messageScores = {};
  int _visibleCount = 0;
  final Map<String, bool> _ipaVisible = {};
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Sequence playback
  bool _isPlayingSequence = false;
  int _currentSequenceIndex = 0;

  // Translation visibility set
  final Set<String> _translateVisible = {};

  // Long press handling
  Timer? _longPressTimer;
  bool _isLongPress = false;
  Offset _startPos = Offset.zero;

  List<String> get _availableRoles {
    final chats = widget.quiz.chats ?? [];
    return chats.map((c) => c.role).toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    // Fire and forget, but it catches errors internally
    _initializeTts();

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
        _userRole = progress.data?['userRole'] as String?;
        final savedVisibleCount = progress.data?['visibleCount'] as int? ?? 0;

        // Restore message scores
        final scoresMap =
            progress.data?['messageScores'] as Map<String, dynamic>?;
        if (scoresMap != null) {
          scoresMap.forEach((key, value) {
            final data = value as Map<String, dynamic>;
            final feedbackData = data['feedback'] as List<dynamic>?;
            final feedbackList = feedbackData?.map((f) {
                  final fMap = f as Map<String, dynamic>;
                  return _WordFeedback(
                    fMap['word'] as String,
                    _FeedbackStatus.values[fMap['status'] as int],
                  );
                }).toList() ??
                [];

            _messageScores[key] = _MessageScore(
              score: data['score'] as int,
              transcript: data['transcript'] as String,
              feedback: feedbackList,
            );
          });
        }

        if (_userRole != null) {
          // If we have progress, restore the sequence state
          _visibleCount = savedVisibleCount;
          _currentSequenceIndex = _visibleCount;
          // Don't auto-play if we just restored, let user interact?
          // Or just scrollToBottom
          _scrollToBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flutterTts.stop();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    try {
      if (Platform.isAndroid) {
        await _flutterTts.getDefaultEngine;
      }

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);

      _flutterTts.setCompletionHandler(() {
        if (_isPlayingSequence) {
          _playNextInSequence();
        }
      });

      // Initialize Speech to Text
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('TTS/STT Init Error: $e');
    }
  }

  void _onRoleSelected(String role) {
    setState(() {
      _userRole = role;
    });
    _initializeVisibleCount();
    _saveProgress();
  }

  void _initializeVisibleCount() {
    // Reset to 0 to start fresh or just start sequencing
    setState(() {
      _visibleCount = 0;
      _isPlayingSequence = true;
      _currentSequenceIndex = 0;
    });
    _playNextInSequence();
  }

  void _playNextInSequence() {
    final chats = widget.quiz.chats ?? [];
    if (_currentSequenceIndex >= chats.length) {
      setState(() {
        _isPlayingSequence = false;
      });
      return;
    }

    final nextChat = chats[_currentSequenceIndex];

    // If next message is User, stop sequence and wait for user interaction
    if (nextChat.role == _userRole) {
      setState(() {
        _isPlayingSequence = false;
        _visibleCount = _currentSequenceIndex + 1; // Show user's turn
      });
      _scrollToBottom();
      return;
    }

    // If next is not User (System/Partner), show it and play TTS
    setState(() {
      _visibleCount = _currentSequenceIndex + 1;
    });
    _scrollToBottom();

    // Play TTS
    final text = _getTextContent(nextChat.question ?? nextChat.content);
    _speakText(
        text); // This will trigger completion handler -> _playNextInSequence

    _currentSequenceIndex++;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getTextContent(String html) {
    // Simple HTML stripping
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String? _getTranslateText(ChatMessage chat) {
    if (chat.translate != null) return chat.translate;

    // Try to extract translate from content if it contains HTML with data-translate
    final content = chat.question ?? chat.content;
    final translateMatch =
        RegExp(r'data-translate="([^"]*)"').firstMatch(content);
    return translateMatch?.group(1);
  }

  Color _getRoleColor(String role, bool isUser) {
    if (isUser) {
      return Theme.of(context).extension<AppColorsExtension>()!.primary;
    }

    // Generate color from role name
    var hash = 0;
    for (var i = 0; i < role.length; i++) {
      hash = role.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final colors = [
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.amber.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.teal.shade600,
    ];

    return colors[hash.abs() % colors.length];
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.stop();
      if (text.isNotEmpty) {
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
      // If TTS fails, we should probably manually advance the sequence after a delay?
      // Or just let it be.
      // If we don't advance, the user is stuck.
      if (_isPlayingSequence) {
        debugPrint('Advancing sequence manually due to TTS error');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isPlayingSequence) {
            _playNextInSequence();
          }
        });
      }
    }
  }

  int _calculateScore(String spoken, String target) {
    final spokenLower = spoken.toLowerCase().trim();
    final targetLower = target.toLowerCase().trim();

    if (spokenLower == targetLower) return 100;

    final spokenWords = spokenLower.split(RegExp(r'\s+'));
    final targetWords = targetLower.split(RegExp(r'\s+'));

    var matches = 0;
    for (final word in targetWords) {
      if (spokenWords.any((sw) => sw.contains(word) || word.contains(sw))) {
        matches++;
      }
    }

    return ((matches / targetWords.length) * 100).round();
  }

  String _simulatePronunciation(String targetText) {
    final words = targetText.split(' ');
    final result = <String>[];
    const errorRate = 0.3;

    for (final word in words) {
      final rand = math.Random().nextDouble();

      if (rand < errorRate * 0.4) {
        continue; // Skip word
      } else if (rand < errorRate * 0.7) {
        const wrongWords = [
          'the',
          'a',
          'an',
          'is',
          'was',
          'were',
          'very',
          'much',
          'so',
        ];
        result.add(wrongWords[math.Random().nextInt(wrongWords.length)]);
      } else if (rand < errorRate) {
        final chars = word.split('');
        final idx = math.Random().nextInt(chars.length);
        chars[idx] = String.fromCharCode(97 + math.Random().nextInt(26));
        result.add(chars.join());
      } else {
        result.add(word);
      }
    }

    if (math.Random().nextDouble() < 0.2) {
      const extraWords = ['um', 'uh', 'like', 'actually'];
      final extraWord = extraWords[math.Random().nextInt(extraWords.length)];
      final insertPos = math.Random().nextInt(result.length + 1);
      result.insert(insertPos, extraWord);
    }

    return result.join(' ');
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      b.length + 1,
      (i) => List.generate(a.length + 1, (j) => 0),
    );

    for (var i = 0; i <= b.length; i++) {
      matrix[i][0] = i;
    }

    for (var j = 0; j <= a.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= b.length; i++) {
      for (var j = 1; j <= a.length; j++) {
        if (b[i - 1] == a[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = [
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1,
          ].reduce(math.min);
        }
      }
    }

    return matrix[b.length][a.length];
  }

  List<_WordFeedback> _analyzeWordFeedback(String spoken, String target) {
    final spokenWords = spoken
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final targetWords = target
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final feedback = List<_WordFeedback?>.filled(targetWords.length, null);
    final usedSpokenIndices = <int>{};

    // First pass: exact matches
    for (var targetIdx = 0; targetIdx < targetWords.length; targetIdx++) {
      final targetWord = targetWords[targetIdx];
      final spokenIdx = spokenWords.indexWhere(
        (w) =>
            !usedSpokenIndices.contains(spokenWords.indexOf(w)) &&
            w == targetWord,
      );

      if (spokenIdx != -1) {
        feedback[targetIdx] =
            _WordFeedback(targetWord, _FeedbackStatus.correct);
        usedSpokenIndices.add(spokenIdx);
      }
    }

    // Second pass: similar matches
    for (var targetIdx = 0; targetIdx < targetWords.length; targetIdx++) {
      if (feedback[targetIdx] != null) continue;

      final targetWord = targetWords[targetIdx];
      var spokenIdx = -1;

      for (var i = 0; i < spokenWords.length; i++) {
        if (usedSpokenIndices.contains(i)) continue;

        final w = spokenWords[i];
        if (w.contains(targetWord) ||
            targetWord.contains(w) ||
            _levenshteinDistance(w, targetWord) <= 2) {
          spokenIdx = i;
          break;
        }
      }

      if (spokenIdx != -1) {
        feedback[targetIdx] =
            _WordFeedback(targetWord, _FeedbackStatus.incorrect);
        usedSpokenIndices.add(spokenIdx);
      } else {
        feedback[targetIdx] =
            _WordFeedback(targetWord, _FeedbackStatus.missing);
      }
    }

    // Third pass: extra words
    final extraWords = <_WordFeedback>[];
    for (var idx = 0; idx < spokenWords.length; idx++) {
      if (!usedSpokenIndices.contains(idx)) {
        extraWords.add(_WordFeedback(spokenWords[idx], _FeedbackStatus.extra));
      }
    }

    return [...feedback.whereType<_WordFeedback>(), ...extraWords];
  }

  void _startListening(
      String chatId, String targetText, int messageIndex) async {
    // Get STT settings from provider
    final sttProvider = context.read<SttSettingProvider>();
    String localeId = 'en_US'; // default

    await _speechToText.listen(
      onResult: (result) =>
          _onSpeechResult(result, chatId, targetText, messageIndex),
      localeId: localeId,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result, String chatId,
      String targetText, int messageIndex) {
    debugPrint(
        'ScriptedChat STT Result: "${result.recognizedWords}" (Final: ${result.finalResult})');
    if (result.finalResult) {
      final transcript = result.recognizedWords;
      debugPrint('ScriptedChat STT Final: "$transcript"');
      final score = _calculateScore(transcript, targetText);
      final feedback = _analyzeWordFeedback(transcript, targetText);

      setState(() {
        _isListening = false;
        _messageScores[chatId] = _MessageScore(
          score: score,
          feedback: feedback,
          transcript: transcript,
        );

        // If score is good (>= 50%) and this was the current step, continue sequence
        if (score >= 50 && messageIndex == _visibleCount - 1) {
          _currentSequenceIndex =
              messageIndex + 1; // Move past this user message
          _isPlayingSequence = true;
          _playNextInSequence();
        }
      });

      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Serialize message scores
    final scoresData = <String, dynamic>{};
    _messageScores.forEach((key, value) {
      scoresData[key] = {
        'score': value.score,
        'transcript': value.transcript,
        'feedback': value.feedback
            .map((f) => {
                  'word': f.word,
                  'status': f.status.index,
                })
            .toList(),
      };
    });

    final chats = widget.quiz.chats ?? [];
    final totalItems = chats.length;
    final completedItems = _visibleCount;

    // Calculate correct items:
    // 1. System messages that are visible (automatically correct)
    // 2. User messages that have a passing score (>= 50)
    var correctItems = 0;
    for (var i = 0; i < _visibleCount; i++) {
      if (i >= chats.length) break;
      final chat = chats[i];
      if (chat.role != _userRole) {
        correctItems++;
      } else {
        // User role: check score
        final scoreData = _messageScores[chat.id];
        if (scoreData != null && scoreData.score >= 50) {
          correctItems++;
        }
      }
    }

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'scripted-chat',
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems,
      data: {
        'userRole': _userRole,
        'visibleCount': _visibleCount,
        'messageScores': scoresData,
      },
    );
  }

  void _handleSimulateTest(String chatId, String targetText, int messageIndex) {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening(chatId, targetText, messageIndex);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startPos = event.position;
    _isLongPress = false;

    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _isLongPress = true;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_longPressTimer != null) {
      final dist = (event.position - _startPos).distance;
      if (dist > 10) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
      }
    }
  }

  void _handlePointerUp(String messageId, PointerUpEvent event) {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (!_isLongPress) {
      setState(() {
        _activeMessageId = _activeMessageId == messageId ? null : messageId;
      });
    }

    Future.delayed(Duration.zero, () {
      _isLongPress = false;
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isLongPress = false;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green.shade500;
    if (score >= 60) return Colors.yellow.shade600;
    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final chats = widget.quiz.chats ?? [];

    // Check if it's user's turn (last visible message is user role and not scored)
    ChatMessage? activeUserChat;
    var isUserTurn = false;

    if (_visibleCount > 0 && _userRole != null) {
      final lastVisibleChat = chats[_visibleCount - 1];
      if (lastVisibleChat.role == _userRole &&
          !_messageScores.containsKey(lastVisibleChat.id)) {
        isUserTurn = true;
        activeUserChat = lastVisibleChat;
      }
    }

    return Stack(
      children: [
        // Main chat content
        Column(
          children: [
            Expanded(
              child: Container(
                color: appColors.background,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: isUserTurn
                          ? 100
                          : 16 // Add padding at bottom if button is visible
                      ),
                  itemCount: _visibleCount,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildBubble(chat, index, appColors);
                  },
                ),
              ),
            ),
          ],
        ),

        // Role Selection Drawer - Only shown when userRole is not set
        if (_userRole == null) _buildRoleSelectionDrawer(appColors),

        // Floating Mic Button for User Turn
        if (isUserTurn && activeUserChat != null)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _handleSimulateTest(
                    activeUserChat!.id,
                    _getTextContent(
                        activeUserChat.question ?? activeUserChat.content),
                    _visibleCount - 1),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : appColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : appColors.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: _isListening ? 12 : 10,
                        spreadRadius: _isListening ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleSelectionDrawer(AppColorsExtension appColors) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the character you want to practice as',
                style: TextStyle(
                  fontSize: 14,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Role buttons
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _availableRoles.length,
                  itemBuilder: (context, index) {
                    final role = _availableRoles[index];
                    return _buildRoleButton(role, appColors);
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, AppColorsExtension appColors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onRoleSelected(role),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: appColors.primary.withOpacity(0.05),
            border: Border.all(
              color: Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: appColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    role.isNotEmpty ? role[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: appColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                role,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    ChatMessage chat,
    int index,
    AppColorsExtension appColors,
  ) {
    final isUserMessage = chat.role == _userRole;
    final translateText = _getTranslateText(chat);
    final isTranslateVisible = _translateVisible.contains(chat.id);
    final scoreData = _messageScores[chat.id];
    final targetText = _getTextContent(chat.question ?? chat.content);
    final showIpaButton =
        scoreData != null && scoreData.score < 50 && chat.ipa != null;

    final roleColor = _getRoleColor(chat.role, isUserMessage);

    // If it's a user message but it's not the current active turn (or past turn),
    // and we haven't spoken it yet (no score), we might want to hide it?
    // BUT the logic `_visibleCount` handles "showing" the bubble.
    // If it is shown, it means it is the user's turn acting out.

    // Check if we should show the "active" recording UI for user
    final isMyTurn = isUserMessage && scoreData == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role/Name badge
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUserMessage) ...[
                Text(
                  chat.role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
                if (chat.name != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${chat.name})',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
                if (chat.time != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    chat.time!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ] else ...[
                if (chat.time != null) ...[
                  Text(
                    chat.time!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (chat.name != null) ...[
                  Text(
                    '(${chat.name})',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  chat.role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Bubble
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Listener(
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: (event) => _handlePointerUp(chat.id, event),
                  onPointerCancel: _handlePointerCancel,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.cardBackground,
                      border: Border.all(
                        color: roleColor.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUserMessage
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottomRight: isUserMessage
                            ? Radius.zero
                            : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content
                        if (scoreData != null)
                          _buildTextWithFeedback(
                            targetText,
                            scoreData.feedback,
                            appColors,
                          )
                        else
                          RichTextParser.buildRichText(
                            context,
                            chat.question ?? chat.content,
                            onWordLongPress: widget.onWordLongPress,
                            style: TextStyle(
                              fontSize: 14,
                              color: appColors.textPrimary,
                            ),
                          ).first,

                        // Translation
                        if (translateText != null && isTranslateVisible)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: appColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              translateText,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),

                        // IPA Display
                        if (_ipaVisible[chat.id] == true && chat.ipa != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: appColors.inputBackground,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              chat.ipa!,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),

                        // Score badge
                        if (scoreData != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${scoreData.score}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(scoreData.score),
                                ),
                              ),
                              if (showIpaButton) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _ipaVisible[chat.id] =
                                          !(_ipaVisible[chat.id] ?? false);
                                    });
                                  },
                                  child: Icon(
                                    Icons.help_outline,
                                    size: 14,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // User Transcript Display
          if (scoreData != null && isUserMessage)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isUserMessage ? 0 : 0,
                right: isUserMessage ? 0 : 0,
              ),
              child: Row(
                mainAxisAlignment: isUserMessage
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.inputBackground,
                        border: Border.all(
                          color: appColors.border,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '"${scoreData.transcript}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Icon buttons
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUserMessage) ...[
                // TTS Button (Speaker)
                GestureDetector(
                  onTap: () => _speakText(targetText),
                  child: Icon(
                    Icons.volume_up,
                    size: 16,
                    color: appColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isTranslateVisible) {
                        _translateVisible.remove(chat.id);
                      } else {
                        _translateVisible.add(chat.id);
                      }
                    });
                  },
                  child: SvgPicture.string(
                    '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-languages-icon lucide-languages"><path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/></svg>''',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      isTranslateVisible
                          ? appColors.primary
                          : appColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ] else ...[
                // User Actions

                // If already scored, show replay/TTS?
                if (scoreData != null) ...[
                  GestureDetector(
                    onTap: () => _speakText(targetText),
                    child: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isTranslateVisible) {
                          _translateVisible.remove(chat.id);
                        } else {
                          _translateVisible.add(chat.id);
                        }
                      });
                    },
                    child: SvgPicture.string(
                      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-languages-icon lucide-languages"><path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/></svg>''',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        isTranslateVisible
                            ? appColors.primary
                            : appColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ] else ...[
                  // If not scored, user is seeing their turn.
                  // we just showed the Mic button above.
                  // Do we show translate/TTS for user's own prompt? Yes, helpful.
                  GestureDetector(
                    onTap: () => _speakText(targetText),
                    child: Icon(
                      Icons.volume_up,
                      size: 16,
                      color: appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isTranslateVisible) {
                          _translateVisible.remove(chat.id);
                        } else {
                          _translateVisible.add(chat.id);
                        }
                      });
                    },
                    child: SvgPicture.string(
                      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-languages-icon lucide-languages"><path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/></svg>''',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        isTranslateVisible
                            ? appColors.primary
                            : appColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),

          // Explanation - Centered after completion
          if (scoreData != null && chat.explain != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: appColors.border,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chat.explain!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: appColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextWithFeedback(
    String text,
    List<_WordFeedback> feedback,
    AppColorsExtension appColors,
  ) {
    final spans = <InlineSpan>[];

    for (var i = 0; i < feedback.length; i++) {
      final item = feedback[i];
      if (item.status == _FeedbackStatus.extra) continue;

      Color? color;
      if (item.status == _FeedbackStatus.correct) {
        color = appColors.primary;
      } else if (item.status == _FeedbackStatus.incorrect ||
          item.status == _FeedbackStatus.missing) {
        color = Colors.red.shade500;
      }

      spans.add(
        TextSpan(
          text: item.word,
          style: TextStyle(color: color),
        ),
      );

      if (i <
          feedback.where((f) => f.status != _FeedbackStatus.extra).length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 14,
          color: appColors.textPrimary,
        ),
      ),
    );
  }
}

enum _FeedbackStatus {
  correct,
  incorrect,
  missing,
  extra,
}

class _WordFeedback {
  _WordFeedback(this.word, this.status);

  final String word;
  final _FeedbackStatus status;
}

class _MessageScore {
  _MessageScore({
    required this.score,
    required this.feedback,
    required this.transcript,
  });

  final int score;
  final List<_WordFeedback> feedback;
  final String transcript;
}
