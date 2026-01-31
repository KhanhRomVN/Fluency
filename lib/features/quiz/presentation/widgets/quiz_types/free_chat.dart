import 'dart:async';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class FreeChat extends StatefulWidget {
  const FreeChat({
    required this.quiz,
    super.key,
    this.onWordLongPress,
  });

  final Quiz quiz;
  final void Function(String word)? onWordLongPress;

  @override
  State<FreeChat> createState() => _FreeChatState();
}

class _FreeChatState extends State<FreeChat> {
  String? _activeMessageId;
  final Map<String, _MessageScore> _messageScores = {};
  int _visibleCount = 0;
  final Map<String, bool> _ipaVisible = {};
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Translation visibility set
  final Set<String> _translateVisible = {};

  // Long press handling
  Timer? _longPressTimer;
  bool _isLongPress = false;
  Offset _startPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initSpeech();
    _initializeVisibleCount();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flutterTts.stop();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _initializeTts() {
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
  }

  void _initializeVisibleCount() {
    final chats = widget.quiz.chats ?? [];
    final userRole = _getUserRole();

    if (userRole == null || userRole.isEmpty) {
      _visibleCount = 0;
      return;
    }

    final firstUserIdx = _findNextUserIndex(0);
    if (firstUserIdx != -1) {
      setState(() {
        _visibleCount = firstUserIdx + 1;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _visibleCount = chats.length;
      });
    }
  }

  int _findNextUserIndex(int startIndex) {
    final chats = widget.quiz.chats ?? [];
    final userRole = _getUserRole();
    if (userRole == null) return -1;

    for (var i = startIndex; i < chats.length; i++) {
      if (chats[i].role == userRole) return i;
    }
    return -1;
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

  String? _getUserRole() {
    // Extract userRole from quiz instruction or first chat message
    // For FreeChat, we expect it to be defined in quiz data
    final chats = widget.quiz.chats ?? [];
    if (chats.isEmpty) return null;

    // Assume the first unique role that appears multiple times is user role
    final roleCounts = <String, int>{};
    for (final chat in chats) {
      roleCounts[chat.role] = (roleCounts[chat.role] ?? 0) + 1;
    }

    // Return the role with most occurrences (simple heuristic)
    if (roleCounts.isEmpty) return null;
    return roleCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
    await _flutterTts.stop();
    await _flutterTts.speak(text);
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
    await _speechToText.listen(
      onResult: (result) =>
          _onSpeechResult(result, chatId, targetText, messageIndex),
      localeId: 'en_US',
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
        'FreeChat STT Result: "${result.recognizedWords}" (Final: ${result.finalResult})');
    if (result.finalResult) {
      final transcript = result.recognizedWords;
      debugPrint('FreeChat STT Final: "$transcript"');
      final score = _calculateScore(transcript, targetText);
      final feedback = _analyzeWordFeedback(transcript, targetText);

      setState(() {
        _isListening = false;
        _messageScores[chatId] = _MessageScore(
          score: score,
          feedback: feedback,
          transcript: transcript,
        );

        // If score is good (>= 50%) and this is the last visible message, advance
        if (score >= 50 && messageIndex == _visibleCount - 1) {
          final nextUserIdx = _findNextUserIndex(_visibleCount);
          if (nextUserIdx != -1) {
            _visibleCount = nextUserIdx + 1;
          } else {
            _visibleCount = (widget.quiz.chats ?? []).length;
          }
          _scrollToBottom();
        }
      });
    }
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
    final userRole = _getUserRole();

    if (_visibleCount > 0 && userRole != null) {
      final lastVisibleChat = chats[_visibleCount - 1];
      if (lastVisibleChat.role == userRole &&
          !_messageScores.containsKey(lastVisibleChat.id)) {
        isUserTurn = true;
        activeUserChat = lastVisibleChat;
      }
    }

    return Stack(
      children: [
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
                      bottom: isUserTurn ? 100 : 16),
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
                    color: appColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appColors.primary.withOpacity(0.4),
                        blurRadius: 10,
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

  Widget _buildBubble(
      ChatMessage chat, int index, AppColorsExtension appColors) {
    final isUserMessage = chat.role == _getUserRole();
    final translateText = _getTranslateText(chat);
    final isTranslateVisible = _translateVisible.contains(chat.id);
    final scoreData = _messageScores[chat.id];
    final targetText = _getTextContent(chat.question ?? chat.content);
    final showIpaButton =
        scoreData != null && scoreData.score < 50 && chat.ipa != null;

    final roleColor = _getRoleColor(chat.role, isUserMessage);

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
                // Translate Button
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
                // User Turn Actions (Result)

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
                  // If not scored, show TTS/Translate helper?
                  // ScriptedChat does show them.
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
                ]
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
