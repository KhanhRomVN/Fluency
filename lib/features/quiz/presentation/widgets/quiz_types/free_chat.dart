import 'package:fluency/core/services/llm_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
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
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _llmService = LlmService();

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
              role: map['role'] as String,
              content: map['content'] as String,
              isUser: map['isUser'] as bool,
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
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prompt = widget.quiz.prompt ??
          'You are a helpful AI assistant. Have a natural conversation with the user.';
      final context = widget.quiz.context ?? '';
      final aiRole = widget.quiz.aiRole ?? 'AI Assistant';

      // Tạo message đầu tiên từ system prompt và context
      final initialUserMessage = context.isNotEmpty
          ? 'Hello! $context'
          : 'Hello! Let\'s have a conversation.';

      final response = await _llmService.sendInitialMessage(
        systemPrompt: prompt,
        userMessage: initialUserMessage,
      );

      setState(() {
        _conversationId = response.conversationId;
        // Thêm message đầu tiên từ AI
        _messages.add(
          ChatBubble(
            role: aiRole,
            content: response.message.content,
            isUser: false,
          ),
        );
        _isLoading = false;
      });

      _saveProgress();

      _scrollToBottom();

      // Auto-speak AI's first message
      _speakAiMessage(response.message.content);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorBottomSheet(e.toString());
    }
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty || _isQuizEnded) return;

    final userRole = widget.quiz.userRole ?? 'You';

    // Thêm message của user vào UI
    setState(() {
      _messages.add(
        ChatBubble(
          role: userRole,
          content: text,
          isUser: true,
        ),
      );
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      // Tạo danh sách messages để gửi lên API
      final apiMessages = <Map<String, String>>[];

      // Thêm tất cả messages hiện tại
      for (final msg in _messages) {
        apiMessages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      final response = await _llmService.sendMessage(
        messages: apiMessages,
        conversationId: _conversationId ?? '',
      );

      setState(() {
        _conversationId = response.conversationId;
        _isLoading = false;
      });

      _handleApiResponse(response.message.content);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorBottomSheet(e.toString());
    }
  }

  void _handleApiResponse(String content) {
    final aiRole = widget.quiz.aiRole ?? 'AI Assistant';

    // Kiểm tra xem có [*END*] không
    final hasEndMarker = content.contains('[*END*]');

    // Loại bỏ [*END*] khỏi nội dung hiển thị
    final displayContent = content.replaceAll('[*END*]', '').trim();

    setState(() {
      _messages.add(
        ChatBubble(
          role: aiRole,
          content: displayContent,
          isUser: false,
        ),
      );
    });

    _scrollToBottom();

    // Auto-speak AI response
    _speakAiMessage(displayContent);

    // Nếu có [*END*], tự động kết thúc quiz
    if (hasEndMarker) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _endQuiz();
      });
    }
  }

  Future<void> _speakAiMessage(String text) async {
    try {
      final ttsProvider = context.read<TtsProvider>();
      if (ttsProvider.isInitialized && text.isNotEmpty) {
        await ttsProvider.ttsService?.speak(text);
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

    // Serialize messages
    final messagesData = _messages
        .map((m) => {
              'role': m.role,
              'content': m.content,
              'isUser': m.isUser,
            })
        .toList();

    // Determine completion. Maybe number of turns > 5? Or just isQuizEnded?
    // Let's use isQuizEnded for "completion" status, but progress bar can use turns?
    final completedItems = _isQuizEnded ? 1 : (_messages.length > 0 ? 1 : 0);
    // Actually, "Total Items" for FreeChat is vague. Let's say 1.

    await quizStateProvider.saveQuizProgress(
      lessonId: widget.lessonId,
      quizId: widget.quizId,
      quizType: 'free-chat',
      completedItems: _isQuizEnded ? 1 : 0,
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
                'Cannot connect to server. Please try again.',
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ColoredBox(
            color: appColors.background,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator(appColors);
                }

                final message = _messages[index];
                return _buildMessageBubble(message, appColors);
              },
            ),
          ),
        ),

        // Input area
        if (!_isQuizEnded)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              border: Border(
                top: BorderSide(
                  color: appColors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: appColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: appColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: appColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: appColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: appColors.textPrimary,
                      fontSize: 14,
                    ),
                    onSubmitted: _isLoading ? null : _sendUserMessage,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _sendUserMessage(_inputController.text),
                  icon: Icon(
                    Icons.send,
                    color: _isLoading
                        ? appColors.textSecondary
                        : appColors.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _isLoading
                        ? appColors.inputBackground
                        : appColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatBubble message, AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
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
                  if (!message.isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          message.isUser ? Colors.white : appColors.textPrimary,
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
                  'Typing...',
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
    required this.role,
    required this.content,
    required this.isUser,
  });

  final String role;
  final String content;
  final bool isUser;
}
