import 'dart:async';
import 'dart:convert';

import 'package:fluency/core/services/llm_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';
import 'package:fluency/core/services/stt/system_stt_service.dart';
import 'package:fluency/core/services/stt/vosk_stt_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

class FreeChat extends StatefulWidget {
  const FreeChat({
    required this.quiz,
    required this.lessonId,
    required this.quizId,
    super.key,
    this.onWordLongPress,
    this.onQuizComplete,
  });

  final Quiz quiz;
  final String lessonId;
  final String quizId;
  final void Function(String word)? onWordLongPress;
  final VoidCallback? onQuizComplete;

  @override
  State<FreeChat> createState() => _FreeChatState();
}

class _FreeChatState extends State<FreeChat> {
  late LlmService _llmService;
  String? _conversationId;
  final List<ChatBubble> _messages = [];
  bool _isLoading = false;
  bool _isQuizEnded = false;
  final ScrollController _scrollController = ScrollController();

  SttService? _sttService;
  bool _isListening = false;
  bool _isSttAvailable = false;
  bool _isSttLoading = false;
  String? _loadingStatus;
  int _thinkingSeconds = 0;
  Timer? _thinkingTimer;
  Timer? _hintTimer;
  final Set<String> _translateVisible = {};

  @override
  void initState() {
    super.initState();
    _llmService = LlmService();
    _initializeStt();

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
        _conversationId = progress.data?['conversationId'] as String?;
        _isQuizEnded = progress.data?['isQuizEnded'] as bool? ?? false;

        final savedMessages = progress.data?['messages'] as List<dynamic>?;
        if (savedMessages != null) {
          _messages.clear();
          _messages.addAll(savedMessages.map((m) {
            final map = m as Map<String, dynamic>;
            return ChatBubble(
              id: map['id'] as String? ?? UniqueKey().toString(),
              role: map['role'] as String,
              content: map['content'] as String,
              isUser: map['isUser'] as bool,
              translate: map['translate'] as String?,
            );
          }));
        }
      });

      // Scroll to bottom after restore
      _scrollToBottom();

      // Check if we should initialize chat (empty messages)
      if (_messages.isEmpty) {
        _initializeChat();
      }
    } else {
      // No progress, start fresh
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _hintTimer?.cancel();
    _scrollController.dispose();
    _sttService?.dispose();
    super.dispose();
  }

  // ... (stt methods remain same)

  Future<void> _initializeStt() async {
    if (mounted) {
      setState(() {
        _isSttLoading = true;
        _loadingStatus = 'Đang chuẩn bị nhận diện giọng nói...';
      });
    }

    final sttProvider = context.read<SttSettingProvider>();
    final providerType = sttProvider.currentProviderType;
    final selectedModelId = sttProvider.selectedModelId;

    debugPrint('FreeChat: Initializing STT ($providerType)...');

    if (providerType == SttProviderType.vosk && selectedModelId != null) {
      _sttService = VoskSttService(selectedModelId: selectedModelId);
    } else {
      _sttService = SystemSttService();
    }

    _isSttAvailable = await _sttService!.initialize();

    if (mounted) {
      setState(() {
        _isSttLoading = false;
        _loadingStatus = null;
      });
    }

    if (_isSttAvailable) {
      debugPrint('FreeChat: STT Initialized successfully');
    } else {
      debugPrint('FreeChat: STT Initialization failed or unavailable');
    }
  }

  void _startListening() async {
    _hintTimer?.cancel(); // Stop hint timer when user starts speaking
    // Remove any existing hint bubble if user starts speaking
    setState(() {
      _messages.removeWhere((m) => m.isHint);
    });

    if (_sttService == null || !_isSttAvailable) {
      await _initializeStt();
    }

    if (!_isSttAvailable) {
      debugPrint('FreeChat: STT Service unavailable');
      return;
    }

    await _sttService!.startListening(
      onResult: (text, isFinal) => _onSpeechResult(text, isFinal),
      localeId: 'en_US', // Assuming English for Free Chat as well
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

  void _onSpeechResult(String transcript, bool isFinal) {
    debugPrint('FreeChat STT Result: "$transcript" (Final: $isFinal)');

    if (isFinal) {
      setState(() {
        _isListening = false;
      });
      if (transcript.trim().isNotEmpty) {
        _sendUserMessage(transcript);
      } else {
        // If empty result (user cancelled), restart hint timer?
        // _startHintTimer(); // Maybe?
      }
    }
  }

  void _startThinkingTimer() {
    _thinkingTimer?.cancel();
    setState(() {
      _thinkingSeconds = 0;
    });
    _thinkingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _thinkingSeconds++;
      });
    });
  }

  void _stopThinkingTimer() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
    setState(() {
      _thinkingSeconds = 0;
    });
  }

  void _startHintTimer(String hintText) {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isQuizEnded && !_isLoading && !_isListening) {
        _showHint(hintText);
      }
    });
  }

  void _showHint(String hintText) {
    setState(() {
      // Remove any existing hints first
      _messages.removeWhere((m) => m.isHint);
      _messages.add(
        ChatBubble(
          id: UniqueKey().toString(),
          role: 'Gợi ý',
          content: hintText,
          isUser: true,
          isHint: true,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<T> _sendMessageWithRetry<T>(
    Future<T> Function() call, {
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await call().timeout(timeout);
      } catch (e) {
        if (attempts > maxRetries)
          rethrow; // If max retries exceeded, throw error
        debugPrint(
            'LLM Call failed (Attempt $attempts/$maxRetries), retrying in 1s...');
        // Optional: add a small delay before retry
        // await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });
    _startThinkingTimer();

    try {
      final prompt = widget.quiz.prompt ??
          'You are a helpful AI assistant. Have a natural conversation with the user.';
      final context = widget.quiz.context ?? '';
      final aiRole = widget.quiz.aiRole ?? 'AI Assistant';

      // Tạo message đầu tiên từ system prompt và context
      final initialUserMessage = context.isNotEmpty
          ? 'Hello! $context'
          : 'Hello! Let\'s have a conversation.';

      final response =
          await _sendMessageWithRetry(() => _llmService.sendInitialMessage(
                systemPrompt: prompt,
                userMessage: initialUserMessage,
              ));

      setState(() {
        _conversationId = response.conversationId;
        // Thêm message đầu tiên từ AI
        _handleApiResponse(response.message.content, isInitial: true);
        _isLoading = false;
      });
      _stopThinkingTimer();

      _saveProgress();
    } catch (e, stackTrace) {
      debugPrint('Error initializing chat: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      _stopThinkingTimer();
      _showErrorBottomSheet(e.toString());
    }
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty || _isQuizEnded) return;

    final userRole = widget.quiz.userRole ?? 'You';

    // Thêm message của user vào UI
    setState(() {
      // Remove any hint before adding user message
      _messages.removeWhere((m) => m.isHint);

      _messages.add(
        ChatBubble(
          id: UniqueKey().toString(),
          role: userRole,
          content: text,
          isUser: true,
        ),
      );
      _isLoading = true;
    });
    _startThinkingTimer();

    _scrollToBottom();

    try {
      // Tạo danh sách messages để gửi lên API
      final apiMessages = <Map<String, String>>[];

      // 1. Add System Prompt
      final prompt = widget.quiz.prompt ??
          'ROLE SETUP:\n- You are an AI conversation partner.\n\nRESPONSE FORMAT (JSON only):\n{\n  "content": "Your natural response in English",\n  "translate": "Vietnamese translation",\n  "response_hint": "A short, natural phrase the USER could say next",\n  "correction": null\n}\n\nMaintain a natural conversation flow.';
      apiMessages.add({
        'role': 'system',
        'content': prompt,
      });

      // 2. Add Initial User Message (Context)
      final context = widget.quiz.context ?? '';
      final initialUserMessage = context.isNotEmpty
          ? 'Hello! $context'
          : 'Hello! Let\'s have a conversation.';
      apiMessages.add({
        'role': 'user',
        'content': initialUserMessage,
      });

      // 3. Add History Messages (excluding hints)
      for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        if (!msg.isHint) {
          String content = msg.content;

          // Append JSON enforcement to the LATEST user message
          if (i == _messages.length - 1 && msg.isUser) {
            content +=
                '\n\n[SYSTEM INSTRUCTION: Provide your response in valid JSON format. Ensure "response_hint" suggests what the user might say NEXT.]';
          }

          apiMessages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': content,
          });
        }
      }

      final response =
          await _sendMessageWithRetry(() => _llmService.sendMessage(
                messages: apiMessages,
                conversationId: _conversationId ?? '',
              ));

      setState(() {
        _conversationId = response.conversationId;
        _isLoading = false;
      });
      _stopThinkingTimer();

      _handleApiResponse(response.message.content);
    } catch (e, stackTrace) {
      debugPrint('Error sending user message: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      _stopThinkingTimer();
      _showErrorBottomSheet(e.toString());
    }
  }

  void _handleApiResponse(String content, {bool isInitial = false}) {
    debugPrint('Raw API Response: $content');
    final aiRole = widget.quiz.aiRole ?? 'AI Assistant';
    String displayContent = content;
    String? translate;
    String? responseHint;
    CorrectionData? correction;
    bool hasEndMarker = false;

    try {
      // Robust JSON extraction using regex
      final jsonRegExp = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegExp.firstMatch(content);

      if (match != null) {
        final jsonString = match.group(0)!;
        // Try to clean potential markdown fences again just in case regex caught them inside (unlikely with this regex but good practice)
        // Actually regex handles finding the brace block.

        final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;

        displayContent = jsonResponse['content'] as String? ?? '';
        translate = jsonResponse['translate'] as String?;
        responseHint = jsonResponse['response_hint'] as String?;
        final correctionData =
            jsonResponse['correction'] as Map<String, dynamic>?;

        // Parse correction if present
        if (correctionData != null) {
          correction = CorrectionData(
            issue: correctionData['issue'] as String? ?? '',
            feedback: correctionData['feedback'] as String? ?? '',
            practicePhrases: (correctionData['practice_phrases'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            encouragement: correctionData['encouragement'] as String? ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('JSON parsing failed: $e, falling back to raw content');
      // Fallback content is already set to `content`
    }

    // Check for end marker
    hasEndMarker = displayContent.contains('[*END*]');
    displayContent = displayContent.replaceAll('[*END*]', '').trim();

    debugPrint('Parsed Display Content: "$displayContent"');

    setState(() {
      _messages.add(
        ChatBubble(
          id: UniqueKey().toString(),
          role: aiRole,
          content: displayContent,
          isUser: false,
          translate: translate,
          responseHint: responseHint,
          correction: correction,
          gender: 'male',
        ),
      );
    });

    _scrollToBottom();

    // Auto-speak AI response with gender
    _speakAiMessage(displayContent, gender: 'male');

    // Start hint timer if hint is available
    if (responseHint != null && !hasEndMarker) {
      _startHintTimer(responseHint);
    }

    // If has end marker, auto-end quiz
    if (hasEndMarker) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _endQuiz();
      });
    }
  }

  Future<void> _speakAiMessage(String text, {String? gender}) async {
    try {
      final ttsProvider = context.read<TtsProvider>();

      // Wait for initialization
      if (!ttsProvider.isInitialized) {
        await ttsProvider.initService();
      }

      if (ttsProvider.isInitialized && text.isNotEmpty) {
        // Use provided gender or default to male
        await ttsProvider.speakWithGender(text, gender: gender ?? 'male');
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  void _endQuiz() {
    setState(() {
      _isQuizEnded = true;
    });

    // Gọi callback để thông báo quiz đã hoàn thành
    widget.onQuizComplete?.call();
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final quizStateProvider = context.read<QuizStateProvider>();

    // Serialize messages (exclude hints)
    final messagesData = _messages
        .where((m) => !m.isHint)
        .map((m) => {
              'id': m.id,
              'role': m.role,
              'content': m.content,
              'isUser': m.isUser,
              'translate': m.translate,
            })
        .toList();

    // Determine completion
    final completedItems = _isQuizEnded ? 1 : (_messages.length > 0 ? 1 : 0);

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'free-chat',
      completedItems: completedItems,
      totalItems: 1,
      data: {
        'conversationId': _conversationId,
        'isQuizEnded': _isQuizEnded,
        'messages': messagesData,
      },
    );
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

  void _showErrorBottomSheet(String error) {
    debugPrint('Showing error: $error');

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cannot connect to server. Please try again.\nError: $error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Exit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    Navigator.of(context).pop(); // Exit quiz
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Column(
          children: [
            // Chat messages
            Expanded(
              child: ColoredBox(
                color: appColors.background,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0) + 1,
                  itemBuilder: (context, index) {
                    final contentCount =
                        _messages.length + (_isLoading ? 1 : 0);

                    if (index == contentCount) {
                      return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4);
                    }

                    if (index == _messages.length && _isLoading) {
                      return _buildLoadingIndicator(appColors);
                    }

                    final message = _messages[index];
                    return _buildMessageBubble(message, appColors);
                  },
                ),
              ),
            ),
          ],
        ),
        if (!_isQuizEnded && !_isLoading)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : appColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : appColors.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: _isListening ? 4 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        if (_isSttLoading) _buildLoadingOverlay(appColors),
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
                      Icons.mic,
                      color: appColors.primary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Cấu hình giọng nói',
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

  Widget _buildMessageBubble(ChatBubble message, AppColorsExtension appColors) {
    if (message.isHint) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(left: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: appColors.primary.withOpacity(0.3),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý câu trả lời:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: appColors.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: appColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final showTranslate =
        message.translate != null && _translateVisible.contains(message.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: appColors.primary,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? appColors.primary
                        : appColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: appColors.border,
                            width: 1,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isUser
                              ? Colors.white
                              : appColors.textPrimary,
                        ),
                      ),
                      if (showTranslate && message.translate != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: message.isUser
                                    ? Colors.white24
                                    : appColors.border,
                              ),
                            ),
                          ),
                          child: Text(
                            message.translate!,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: message.isUser
                                  ? Colors.white70
                                  : appColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action Row for AI messages
                if (!message.isUser && message.translate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Translate Toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_translateVisible.contains(message.id)) {
                                _translateVisible.remove(message.id);
                              } else {
                                _translateVisible.add(message.id);
                              }
                            });
                          },
                          child: Icon(
                            Icons.translate,
                            size: 18,
                            color: _translateVisible.contains(message.id)
                                ? appColors.primary
                                : appColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: appColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      appColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking ${_thinkingSeconds}s...',
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble {
  ChatBubble({
    this.id = '',
    required this.role,
    required this.content,
    required this.isUser,
    this.translate,
    this.responseHint,
    this.correction,
    this.gender,
    this.isHint = false,
  });

  final String id;
  final String role;
  final String content;
  final bool isUser;
  final String? translate; // Vietnamese translation
  final String? responseHint; // Suggested response for user
  final CorrectionData? correction; // Correction feedback
  final String? gender; // 'male' or 'female' for TTS
  final bool isHint;
}

class CorrectionData {
  CorrectionData({
    required this.issue,
    required this.feedback,
    required this.practicePhrases,
    required this.encouragement,
  });

  final String issue; // 'off-topic' | 'unclear' | 'pronunciation'
  final String feedback; // Explanation in Vietnamese
  final List<String> practicePhrases; // Phrases to practice
  final String encouragement; // Positive message after practice
}
