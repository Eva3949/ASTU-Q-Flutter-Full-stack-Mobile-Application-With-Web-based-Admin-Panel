import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../chat/domain/entities/chat_message.dart';

class AIProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://evadevstudio.com/sami'));

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  AIProvider() {
    // Initial welcome message from AI
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        conversationId: 0,
        senderId: -1, // AI ID
        senderName: 'ASTU-Q AI',
        content:
            'Hello! I am your AI assistant. How can I help you with your studies today?',
        type: 'text',
        isFromCurrentUser: false,
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      conversationId: 0,
      senderId: 1, // User ID (placeholder)
      senderName: 'You',
      content: content,
      type: 'text',
      isFromCurrentUser: true,
      isRead: true,
      createdAt: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Call the real PHP AI backend
      final response = await _dio.post(
        '/ai_chat.php',
        data: {'message': content},
      );

      String aiResponse = "";

      if (response.statusCode == 200 && response.data['success'] == true) {
        aiResponse = response.data['ai_response'];
      } else {
        // Show actual server error for debugging
        final serverMsg = response.data['message'] ?? 'Unknown error';
        aiResponse = "Error: $serverMsg";
      }

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        conversationId: 0,
        senderId: -1,
        senderName: 'ASTU-Q AI',
        content: aiResponse,
        type: 'text',
        isFromCurrentUser: false,
        isRead: true,
        createdAt: DateTime.now(),
      );

      _messages.add(aiMessage);
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          conversationId: 0,
          senderId: -1,
          senderName: 'ASTU-Q AI',
          content:
              'Sorry, I encountered an error. Please check your internet and try again.',
          type: 'text',
          isFromCurrentUser: false,
          isRead: true,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        conversationId: 0,
        senderId: -1,
        senderName: 'ASTU-Q AI',
        content: 'Chat cleared. How can I help you now?',
        type: 'text',
        isFromCurrentUser: false,
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
