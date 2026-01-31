import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service để gọi LLM API cho free-chat quiz
class LlmService {
  LlmService() {
    _selectedUrl = _selectRandomUrl();
  }

  String? _selectedUrl;
  static const String _model = 'allenai/molmo-2-8b:free';

  /// Chọn ngẫu nhiên 1 URL từ LLM_URL trong env
  String _selectRandomUrl() {
    final llmUrlsString = dotenv.env['LLM_URL'] ?? '';
    if (llmUrlsString.isEmpty) {
      throw Exception('LLM_URL not found in environment variables');
    }

    final urls = llmUrlsString.split(',').map((e) => e.trim()).toList();
    if (urls.isEmpty) {
      throw Exception('No valid URLs found in LLM_URL');
    }

    final random = Random();
    final selectedUrl = urls[random.nextInt(urls.length)];

    // Ensure URL has https:// prefix
    if (!selectedUrl.startsWith('http://') &&
        !selectedUrl.startsWith('https://')) {
      return 'https://$selectedUrl';
    }

    return selectedUrl;
  }

  /// Lấy URL đã chọn cho quiz này
  String get selectedUrl => _selectedUrl ?? '';

  /// Gửi message đầu tiên với system prompt
  Future<LlmResponse> sendInitialMessage({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': systemPrompt,
      },
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    return _sendRequest(messages: messages, conversationId: '');
  }

  /// Gửi message tiếp theo trong conversation
  Future<LlmResponse> sendMessage({
    required List<Map<String, String>> messages,
    required String conversationId,
  }) async {
    return _sendRequest(messages: messages, conversationId: conversationId);
  }

  /// Gửi request đến LLM API
  Future<LlmResponse> _sendRequest({
    required List<Map<String, String>> messages,
    required String conversationId,
  }) async {
    if (_selectedUrl == null) {
      throw Exception('No URL selected');
    }

    try {
      final response = await http.post(
        Uri.parse(_selectedUrl!),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'conversationId': conversationId,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          return LlmResponse(
            success: true,
            conversationId: data['conversationId'] as String? ?? '',
            message: LlmMessage.fromJson(
              data['message'] as Map<String, dynamic>,
            ),
          );
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

/// Response từ LLM API
class LlmResponse {
  LlmResponse({
    required this.success,
    required this.conversationId,
    required this.message,
  });

  factory LlmResponse.fromJson(Map<String, dynamic> json) {
    return LlmResponse(
      success: json['success'] as bool? ?? false,
      conversationId: json['conversationId'] as String? ?? '',
      message: LlmMessage.fromJson(json['message'] as Map<String, dynamic>),
    );
  }

  final bool success;
  final String conversationId;
  final LlmMessage message;
}

/// Message từ LLM
class LlmMessage {
  LlmMessage({
    required this.role,
    required this.content,
  });

  factory LlmMessage.fromJson(Map<String, dynamic> json) {
    return LlmMessage(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
    );
  }

  final String role;
  final String content;

  Map<String, String> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
