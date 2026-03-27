import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/sound_effect_provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:provider/provider.dart';
import 'package:fluency/features/quiz/presentation/widgets/quiz_types/pronunciation_drill.dart';

class ScriptedChat extends StatefulWidget {
  const ScriptedChat({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    this.onWordLongPress,
    this.onCheck,
    super.key,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onCheck;

  @override
  State<ScriptedChat> createState() => _ScriptedChatState();
}

class _ScriptedChatState extends State<ScriptedChat> {
  String? _userRole;
  String? _activeMessageId;
  final Map<String, _MessageScore> _messageScores = {};
  int _visibleCount = 0;
  final ScrollController _scrollController = ScrollController();

  SttService? _sttService;
  bool _isListening = false;
  String? _sttError;
  StreamSubscription<TtsState>? _ttsSubscription;

  // Sequence playback
  bool _isPlayingSequence = false;
  int _currentSequenceIndex = 0;

  // ... (rest)

  // Translation visibility set
  final Set<String> _translateVisible = {};
  final Set<String> _ipaVisible = {};
  final Set<String> _tipsVisible = {};

  // Long press handling
  Timer? _longPressTimer;
  bool _isLongPress = false;
  Offset _startPos = Offset.zero;
  bool _isTtsLoading = false;
  String? _loadingStatus;

  List<_RoleInfo> get _availableRoles {
    final chats = widget.quiz.chats ?? [];
    final roleMap = <String, _RoleInfo>{};

    for (final chat in chats) {
      if (!roleMap.containsKey(chat.role)) {
        roleMap[chat.role] = _RoleInfo(
          role: chat.role,
          name: chat.name,
          gender: chat.gender,
        );
      }
    }

    return roleMap.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeStt();

    // Listen for TTS service changes (switching voices/engines)
    context.read<TtsProvider>().addListener(_onTtsProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  void _onTtsProviderChanged() {
    if (mounted) {
      debugPrint(
          'ScriptedChat: TtsProvider notify received, updating TTS connection');
      _setupTtsListener();
    }
  }

  Future<void> _initializeStt() async {
    try {
      debugPrint('ScriptedChat: Initializing STT (system)...');

      _sttService = SystemSttService();

      final available = await _sttService!.initialize();
      if (mounted) {
        setState(() {
          if (!available) {
            _sttError = 'Speech recognition not available on this device';
          }
        });
      }
      if (available) {
        debugPrint('ScriptedChat: STT Initialized successfully');
      } else {
        debugPrint('ScriptedChat: STT Initialization failed or unavailable');
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('ScriptedChat: STT Initialization error: $e');
      if (mounted) {
        setState(() {
          _sttError = 'Speech recognition not available on this device';
        });
      }
    }
  }

  Future<void> _loadProgress() async {
    try {
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
            _visibleCount = savedVisibleCount;
            debugPrint(
                'ScriptedChat: Restored progress. Visible=$_visibleCount, Role=$_userRole');

            // Resume sequence logic
            int restartIndex = _visibleCount;
            bool shouldResume = false;

            if (_visibleCount > 0) {
              final chats = widget.quiz.chats ?? [];
              if (_visibleCount <= chats.length) {
                final lastIndex = _visibleCount - 1;
                final lastChat = chats[lastIndex];

                if (lastChat.role != _userRole) {
                  restartIndex = lastIndex;
                  shouldResume = true;
                  debugPrint(
                      'ScriptedChat: Resuming at assistant message $restartIndex for context.');
                } else {
                  final scoreData = _messageScores[lastChat.id];
                  if (scoreData != null && scoreData.score >= 50) {
                    restartIndex = _visibleCount;
                    shouldResume = true;
                    debugPrint(
                        'ScriptedChat: User passed previous, resuming at next sequence $restartIndex');
                  } else {
                    if (lastIndex > 0) {
                      restartIndex = lastIndex - 1;
                      shouldResume = true;
                      debugPrint(
                          'ScriptedChat: User pending/failed. Replaying previous assistant prompt at $restartIndex');
                    } else {
                      shouldResume = false;
                    }
                  }
                }
              }
            } else {
              restartIndex = 0;
              shouldResume = true;
            }

            _currentSequenceIndex = restartIndex;
            _isPlayingSequence = shouldResume;

            if (shouldResume) {
              // Wait for TTS to be ready before starting sequence
              _waitForTtsAndStartSequence();
            }

            // If quiz is already completed (all chats visible and user passed last turn)
            final chats = widget.quiz.chats ?? [];
            if (_visibleCount >= chats.length) {
              final lastChat = chats.last;
              if (lastChat.role != _userRole ||
                  (_messageScores[lastChat.id]?.score ?? 0) >= 50) {
                widget.onCheck?.call();
              }
            }
          }
        });

        // Check if we need to migrate/update the progress with the new correctness map
        if (progress.data?['correctness'] == null) {
          debugPrint(
              'ScriptedChat: No correctness map in saved progress, force-saving to migrate');
          _saveProgress();
        }
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('ScriptedChat: Error loading progress: $e');
    }
  }

  Future<void> _waitForTtsAndStartSequence() async {
    try {
      debugPrint('ScriptedChat: Waiting for TTS initialization...');
      final ttsProvider = context.read<TtsProvider>();

      if (!ttsProvider.isInitialized) {
        if (mounted) {
          setState(() {
            _isTtsLoading = true;
            _loadingStatus = 'Đang khởi tạo âm thanh offline...';
          });
        }
      }

      // Wait for TTS initialization
      int retries = 0;
      while (!ttsProvider.isInitialized && retries < 30 && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        retries++;
        if (retries % 5 == 0) {
          debugPrint(
              'ScriptedChat: Still waiting for TTS... (${retries * 200}ms)');
          if (mounted) {
            setState(() {
              _loadingStatus =
                  'Đang nạp dữ liệu giọng nói... (${retries ~/ 5}s)';
            });
          }
        }
      }

      // If still not initialized, force init
      if (!ttsProvider.isInitialized && mounted) {
        debugPrint('ScriptedChat: Forcing TTS init before sequence');
        if (mounted) {
          setState(() {
            _loadingStatus = 'Đang đồng bộ cấu hình...';
          });
        }
        await ttsProvider.initService();
      }

      if (mounted) {
        setState(() {
          _isTtsLoading = false;
          _loadingStatus = null;
        });
      }

      // Verify TTS service is available
      if (ttsProvider.ttsService == null) {
        debugPrint(
            'ScriptedChat: ERROR - TTS service is still null after init!');
        return;
      }

      debugPrint(
          'ScriptedChat: TTS is ready (service: ${ttsProvider.ttsService.runtimeType})');

      // Setup listener
      _setupTtsListener();

      // Start sequence playback
      if (mounted && _isPlayingSequence) {
        debugPrint('ScriptedChat: Starting sequence playback');
        _playNextInSequence();
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('ScriptedChat: Error in _waitForTtsAndStartSequence: $e');
    }
  }

  void _setupTtsListener() {
    if (!mounted) return;
    final ttsProvider = context.read<TtsProvider>();
    if (ttsProvider.ttsService != null) {
      _ttsSubscription?.cancel();
      _ttsSubscription = ttsProvider.ttsService!.stateStream.listen((state) {
        debugPrint('ScriptedChat: TTS State changed to $state');
        if (state == TtsState.stopped && _isPlayingSequence) {
          debugPrint('ScriptedChat: TTS stopped, playing next in sequence');
          _playNextInSequence();
        }
      });
      debugPrint('ScriptedChat: TTS listener setup complete');
    } else {
      debugPrint('ScriptedChat: Cannot setup listener - TTS service is null');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsSubscription?.cancel();
    // Use try-catch or null check for context in dispose if needed
    try {
      context.read<TtsProvider>().removeListener(_onTtsProviderChanged);
      context.read<TtsProvider>().ttsService?.stop();
    } catch (_) {}
    _sttService?.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTts() async {
    try {
      final ttsProvider = context.read<TtsProvider>();

      // Wait for initialization if needed
      int retries = 0;
      while (!ttsProvider.isInitialized && retries < 25) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      // If still not initialized, force it
      if (!ttsProvider.isInitialized) {
        debugPrint(
            'ScriptedChat: TTS not initialized after wait, forcing init');
        await ttsProvider.initService();
      }

      _setupTtsListener();
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
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
    // Wait for TTS before starting
    _waitForTtsAndStartSequence();
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

    // Increment index BEFORE playing TTS
    _currentSequenceIndex++;

    // Play TTS - the TTS state listener will call _playNextInSequence again when done
    final text = _getTextContent(nextChat.question ?? nextChat.content);
    _speakText(text, gender: nextChat.gender);
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

  Future<void> _speakText(String text, {String? gender}) async {
    try {
      debugPrint(
          'ScriptedChat: _speakText called with text: "$text", gender: $gender');
      final ttsProvider = context.read<TtsProvider>();
      if (ttsProvider.ttsService == null) {
        debugPrint('ScriptedChat: TTS Service is null, triggering fallback');
        if (_isPlayingSequence) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _isPlayingSequence) {
              _playNextInSequence();
            }
          });
        }
        return;
      }

      if (text.isNotEmpty) {
        debugPrint('ScriptedChat: calling ttsProvider.speakWithGender');
        // Don't await - let the TTS state listener handle progression
        ttsProvider.speakWithGender(text, gender: gender);
        debugPrint('ScriptedChat: TTS started');
      } else {
        // If nothing to speak, manually advance
        debugPrint('ScriptedChat: empty text, manually advancing');
        if (_isPlayingSequence) {
          Future.delayed(Duration.zero, () {
            if (mounted && _isPlayingSequence) _playNextInSequence();
          });
        }
      }
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('TTS Speak Error: $e');
      // Fallback: manually advance if TTS fails
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
    if (_sttService == null) {
      await _initializeStt();
    }

    if (_sttService == null ||
        _sttError != null ||
        !await _sttService!.isAvailable()) {
      debugPrint('ScriptedChat: STT Service unavailable');
      return;
    }

    String localeId = 'en_US';

    await _sttService!.startListening(
      onResult: (text, isFinal) =>
          _onSpeechResult(text, isFinal, chatId, targetText, messageIndex),
      localeId: localeId,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _sttService?.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(String transcript, bool isFinal, String chatId,
      String targetText, int messageIndex) {
    debugPrint('ScriptedChat STT Result: "$transcript" (Final: $isFinal)');

    if (isFinal) {
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

        // Play sound effect
        if (mounted) {
          final soundProvider = context.read<SoundEffectProvider>();
          if (score >= 50) {
            soundProvider.playCorrect();
          } else {
            soundProvider.playWrong();
          }
        }

        if (score >= 50 && messageIndex == _visibleCount - 1) {
          _currentSequenceIndex = messageIndex + 1;
          _isPlayingSequence = true;
          _playNextInSequence();
        }
      });

      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    try {
      final quizStateProvider = context.read<QuizStateProvider>();

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

      var correctItems = 0;
      final Map<String, bool> correctness = {};
      for (var i = 0; i < _visibleCount; i++) {
        if (i >= chats.length) break;
        final chat = chats[i];
        correctness[chat.id] = true;
        if (chat.role != _userRole) {
          correctItems++;
        } else {
          final scoreData = _messageScores[chat.id];
          if (scoreData != null && scoreData.score >= 50) {
            correctItems++;
          }
        }
      }

      debugPrint(
          'ScriptedChat: Saving progress. Visible=$_visibleCount, Total=$totalItems, Correct=$correctItems');
      debugPrint(
          'ScriptedChat: Correctness Map: ${correctness.keys.length} items');

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
          'correctness': correctness,
        },
      );
    } catch (e, s) {
      MonitoringService.captureError(e, stackTrace: s);
      debugPrint('ScriptedChat: Error saving progress: $e');
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

    Future<void>.delayed(Duration.zero, () {
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

    ChatMessage? activeUserChat;
    var isUserTurn = false;

    if (_visibleCount > 0 && _userRole != null) {
      final lastVisibleChat = chats[_visibleCount - 1];
      if (lastVisibleChat.role == _userRole) {
        final scoreData = _messageScores[lastVisibleChat.id];
        if (scoreData == null || scoreData.score < 50) {
          isUserTurn = true;
          activeUserChat = lastVisibleChat;
        }
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
                  itemCount: _visibleCount + 1,
                  itemBuilder: (context, index) {
                    if (index == _visibleCount) {
                      return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4);
                    }
                    final chat = chats[index];
                    return _buildBubble(chat, index, appColors);
                  },
                ),
              ),
            ),
          ],
        ),
        if (_userRole == null) _buildRoleSelectionDrawer(appColors),
        if (isUserTurn && activeUserChat != null)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sttError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This device does not support speech-to-text service.',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_sttError == null)
                  Center(
                    child: GestureDetector(
                      onTap: () => _handleSimulateTest(
                          activeUserChat!.id,
                          _getTextContent(activeUserChat.question ??
                              activeUserChat.content),
                          _visibleCount - 1),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? appColors.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          color: _isListening ? appColors.primary : Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_isTtsLoading) _buildLoadingOverlay(appColors),
      ],
    );
  }

  Widget _buildLoadingOverlay(AppColorsExtension appColors) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: appColors.cardBackground.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(appColors.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    Icon(
                      Icons.headset,
                      color: appColors.primary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Chuẩn bị âm thanh',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _loadingStatus ?? 'Đang tải dữ liệu...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng chờ trong giây lát',
                  style: TextStyle(
                    color: appColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionDrawer(AppColorsExtension appColors) {
    return GestureDetector(
      onTap: () {}, // Prevent taps from passing through
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: appColors.drawerBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Role',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Select the character you want to practice as',
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  color: appColors.border.withValues(alpha: 0.5),
                  height: 1,
                ),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    itemCount: _availableRoles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final roleInfo = _availableRoles[index];
                      return _buildRoleCard(roleInfo, appColors);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(_RoleInfo roleInfo, AppColorsExtension appColors) {
    final isMale = roleInfo.gender == 'male';
    final genderColor = isMale ? Colors.blue : Colors.pink;
    final genderIcon = isMale
        ? '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-mars-icon lucide-mars"><path d="M16 3h5v5"/><path d="m21 3-6.75 6.75"/><circle cx="10" cy="14" r="6"/></svg>'''
        : '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-venus-icon lucide-venus"><path d="M12 15v7"/><path d="M9 19h6"/><circle cx="12" cy="9" r="6"/></svg>''';

    return Container(
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onRoleSelected(roleInfo.role),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: genderColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.string(
                    genderIcon,
                    colorFilter: ColorFilter.mode(
                      genderColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleInfo.name ?? roleInfo.role,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        roleInfo.role,
                        style: TextStyle(
                          fontSize: 11,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: appColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
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
    final roleColor = _getRoleColor(chat.role, isUserMessage);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUserMessage) ...[
                Text(
                  chat.role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
                if (chat.name != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    chat.name!,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textPrimary,
                    ),
                  ),
                ],
              ] else ...[
                if (scoreData != null) ...[
                  Text(
                    '${scoreData.score}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(scoreData.score),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (chat.name != null) ...[
                  Text(
                    chat.name!,
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  chat.role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUserMessage)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                  child: InkWell(
                    onTap: () => _openPronunciationDrawer(chat),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset(
                        'assets/icons/rotate-ccw.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          appColors.textSecondary.withValues(alpha: 0.7),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
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
                        color: isUserMessage
                            ? appColors.primary
                            : appColors.border,
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
                        RichTextParser.buildRichText(
                          context,
                          chat.question ?? chat.content,
                          onWordLongPress: widget.onWordLongPress,
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.textPrimary,
                          ),
                        ).first,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Translate:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  translateText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (chat.ipa != null && _ipaVisible.contains(chat.id))
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.blue.shade600,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IPA:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  chat.ipa!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: appColors.textSecondary,
                                    fontFamily: 'NotoSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (chat.tips != null &&
                            chat.tips!.isNotEmpty &&
                            _tipsVisible.contains(chat.id))
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: Colors.amber.shade600,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ...chat.tips!.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final tip = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$index. ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: appColors.textSecondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: RichTextParser.buildRichText(
                                            context,
                                            tip,
                                            onWordLongPress:
                                                widget.onWordLongPress,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: appColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ).first,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        if (scoreData != null && isUserMessage)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: _getScoreColor(scoreData.score),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your recording:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: appColors.textSecondary,
                                  ),
                                ),
                                _buildTextWithFeedback(
                                  scoreData.transcript,
                                  scoreData.feedback,
                                  appColors,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _speakText(targetText, gender: chat.gender),
                child: Icon(
                  Icons.volume_up,
                  size: 16,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
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
                  '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/></svg>''',
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
              if (chat.ipa != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_ipaVisible.contains(chat.id)) {
                        _ipaVisible.remove(chat.id);
                      } else {
                        _ipaVisible.add(chat.id);
                      }
                    });
                  },
                  child: Icon(
                    Icons.text_fields,
                    size: 16,
                    color: _ipaVisible.contains(chat.id)
                        ? Colors.blue.shade600
                        : appColors.textSecondary,
                  ),
                ),
              ],
              if (chat.tips != null && chat.tips!.isNotEmpty) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_tipsVisible.contains(chat.id)) {
                        _tipsVisible.remove(chat.id);
                      } else {
                        _tipsVisible.add(chat.id);
                      }
                    });
                  },
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: _tipsVisible.contains(chat.id)
                        ? Colors.amber.shade700
                        : appColors.textSecondary,
                  ),
                ),
              ],
            ],
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
      if (item.status == _FeedbackStatus.missing) continue;

      Color? color;
      if (item.status == _FeedbackStatus.correct) {
        color = Colors.green;
      } else if (item.status == _FeedbackStatus.incorrect) {
        color = Colors.red;
      } else if (item.status == _FeedbackStatus.extra) {
        color = Colors.grey;
      } else {
        color = appColors.textPrimary;
      }

      spans.add(
        TextSpan(
          text: item.word,
          style: TextStyle(color: color, fontStyle: FontStyle.italic),
        ),
      );

      if (i < feedback.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 13,
          color: appColors.textSecondary,
        ),
      ),
    );
  }

  void _openPronunciationDrawer(ChatMessage chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _PronunciationPracticeDrawer(
                  targetText: _getTextContent(chat.content),
                  appColors: Theme.of(context).extension<AppColorsExtension>()!,
                ),
              ),
            ],
          ),
        );
      },
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

class _RoleInfo {
  _RoleInfo({
    required this.role,
    this.name,
    this.gender,
  });

  final String role;
  final String? name;
  final String? gender;
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class _PronunciationPracticeDrawer extends StatefulWidget {
  const _PronunciationPracticeDrawer({
    required this.targetText,
    required this.appColors,
  });

  final String targetText;
  final AppColorsExtension appColors;

  @override
  State<_PronunciationPracticeDrawer> createState() =>
      _PronunciationPracticeDrawerState();
}

class _PronunciationPracticeDrawerState
    extends State<_PronunciationPracticeDrawer> {
  SttService? _sttService;
  bool _speechEnabled = false;
  bool _isRecording = false;
  String? _sttError;
  StreamSubscription<String>? _sttStatusSub;

  int _bestScore = 0;
  int _attempts = 0;
  String? _transcript;
  List<_WordFeedback> _feedback = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttService = SystemSttService();
    try {
      _speechEnabled = await _sttService!.initialize();
      if (_speechEnabled) {
        _sttStatusSub = _sttService!.statusStream.listen((String status) {
          if (status == 'notListening' || status == 'done') {
            _stopListening();
          }
        });
      } else {
        setState(() {
          _sttError = 'Speech recognition not available on this device';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sttError = e.toString());
      }
    }
  }

  @override
  void dispose() {
    _sttStatusSub?.cancel();
    _sttService?.dispose();
    super.dispose();
  }

  void _startListening() {
    if (!_speechEnabled || _sttService == null) return;
    setState(() {
      _isRecording = true;
      _sttError = null;
      _transcript = null;
      _feedback = [];
    });
    _sttService!.startListening(
      onResult: _onSpeechResult,
      localeId: 'en-US',
    );
  }

  void _stopListening() {
    if (!_isRecording) return;
    _sttService?.stopListening();
    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  void _onSpeechResult(String transcript, bool isFinal) {
    if (!mounted) return;
    setState(() {
      _transcript = transcript;
    });

    if (isFinal || transcript.length >= widget.targetText.length - 2) {
      final score = _calculateScore(transcript, widget.targetText);
      final newFeedback = _analyzeWordFeedback(transcript, widget.targetText);

      setState(() {
        _isRecording = false;
        _attempts++;
        if (score > _bestScore) _bestScore = score;
        _feedback = newFeedback;
      });
      _sttService?.stopListening();
    }
  }

  int _calculateScore(String spoken, String target) {
    final cleanSpoken = spoken.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final cleanTarget = target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    if (cleanSpoken.isEmpty || cleanTarget.isEmpty) return 0;
    final distance = _levenshteinDistance(cleanSpoken, cleanTarget);
    final maxLength = math.max(cleanSpoken.length, cleanTarget.length);
    final score = ((1 - distance / maxLength) * 100).round();
    return score.clamp(0, 100);
  }

  int _levenshteinDistance(String a, String b) {
    final dp = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) dp[i][0] = i;
    for (var j = 0; j <= b.length; j++) dp[0][j] = j;

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              math.min(dp[i - 1][j - 1], math.min(dp[i - 1][j], dp[i][j - 1]));
        }
      }
    }
    return dp[a.length][b.length];
  }

  List<_WordFeedback> _analyzeWordFeedback(String spoken, String target) {
    final sWords = spoken
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
      ..removeWhere((e) => e.isEmpty);
    final tWords = target
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
      ..removeWhere((e) => e.isEmpty);
    final originalTWords = target.split(' ')..removeWhere((e) => e.isEmpty);

    final feedback = <_WordFeedback>[];
    for (var i = 0; i < tWords.length; i++) {
      final tw = tWords[i];
      final ow = originalTWords[i];
      if (sWords.contains(tw)) {
        feedback.add(_WordFeedback(ow, _FeedbackStatus.correct));
        sWords.remove(tw);
      } else {
        feedback.add(_WordFeedback(ow, _FeedbackStatus.incorrect));
      }
    }
    return feedback;
  }

  Color _getScoreColor(int score, int attempts) {
    if (attempts == 0)
      return widget.appColors.textSecondary.withValues(alpha: 0.3);
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.amber.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = widget.appColors;
    return Column(
      children: [
        const Spacer(),

        // Score Circle
        if (_attempts > 0 && !_isRecording)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _attempts == 0 ? 0.0 : _bestScore / 100,
                      strokeWidth: 8,
                      backgroundColor:
                          appColors.textSecondary.withValues(alpha: 0.25),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(_bestScore, _attempts),
                      ),
                    ),
                  ),
                  Text(
                    '$_bestScore%',
                    style: TextStyle(
                      fontSize: 24,
                      color: _getScoreColor(_bestScore, _attempts),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Main Text (Target)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _feedback.isEmpty
              ? Text(
                  widget.targetText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: appColors.textPrimary,
                    height: 1.3,
                  ),
                )
              : _buildFeedbackRichText(),
        ),

        const SizedBox(height: 24),

        // Spoken Transcript (You said)
        if (_transcript != null && !_isRecording) ...[
          Text(
            'You said:',
            style: TextStyle(
              color: appColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color:
                  _getScoreColor(_bestScore, _attempts).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getScoreColor(_bestScore, _attempts)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _transcript!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getScoreColor(_bestScore, _attempts),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const Spacer(),

        // Error message
        if (_sttError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sttError!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Mic button
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _isRecording ? _stopListening : _startListening,
                borderRadius: BorderRadius.circular(50),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (_isRecording
                            ? Colors.amber
                            : _getScoreColor(_bestScore, _attempts))
                        .withValues(alpha: _isRecording ? 0.3 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic,
                    color: _isRecording
                        ? Colors.amber
                        : _getScoreColor(_bestScore, _attempts),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording ? 'Recording...' : 'Tap to record',
                style: TextStyle(
                  color: _isRecording ? Colors.amber : appColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackRichText() {
    final spans = <InlineSpan>[];
    for (var i = 0; i < _feedback.length; i++) {
      final item = _feedback[i];
      Color color = widget.appColors.textPrimary;
      if (item.status == _FeedbackStatus.correct) color = Colors.green;
      if (item.status == _FeedbackStatus.incorrect) color = Colors.red;

      spans.add(
        TextSpan(
          text: item.word,
          style: TextStyle(
            fontSize: 24,
            color: color,
            height: 1.3,
          ),
        ),
      );
      if (i < _feedback.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center);
  }
}
