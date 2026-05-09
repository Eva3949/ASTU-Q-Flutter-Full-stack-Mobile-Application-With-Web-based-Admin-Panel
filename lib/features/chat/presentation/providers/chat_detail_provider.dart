import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_message_read_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/usecase.dart';

/// Chat Detail Provider
/// Manages individual chat conversation state and operations
class ChatDetailProvider extends ChangeNotifier {
  final UseCase<List<ChatMessage>, GetChatMessagesParams>
  _getChatMessagesUseCase;
  final UseCase<ChatMessage, SendMessageParams> _sendMessageUseCase;
  final UseCase<void, MarkMessageReadParams> _markMessageReadUseCase;
  final Logger _logger;

  ChatDetailProvider(
    this._getChatMessagesUseCase,
    this._sendMessageUseCase,
    this._markMessageReadUseCase,
    this._logger,
  );

  // State variables
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _messageInput = '';
  Timer? _pollingTimer;
  bool _isTyping = false;
  Set<int> _typingUsers = <int>{};
  DateTime? _lastTypingTime;

  // Conversation info
  int? _conversationId;
  String? _userName;
  String? _userAvatar;
  bool _isGroupChat = false;
  ChatUser? _otherUser;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get messageInput => _messageInput;
  bool get isTyping => _isTyping;
  Set<int> get typingUsers => _typingUsers;
  int get messageCount => _messages.length;

  // Conversation getters
  int? get conversationId => _conversationId;
  String? get userName => _userName;
  String? get userAvatar => _userAvatar;
  bool get isGroupChat => _isGroupChat;
  ChatUser? get otherUser => _otherUser;

  // Unread messages count
  int get unreadMessagesCount {
    return _messages
        .where((message) => !message.isRead && !message.isFromCurrentUser)
        .length;
  }

  /// Initialize chat with conversation data
  void initializeChat({
    required int conversationId,
    String? userName,
    String? userAvatar,
    bool isGroupChat = false,
    ChatUser? otherUser,
  }) {
    _conversationId = conversationId;
    _userName = userName;
    _userAvatar = userAvatar;
    _isGroupChat = isGroupChat;
    _otherUser = otherUser;

    _logger.d(
      'Initializing chat - Conversation: $conversationId, User: $userName',
    );

    // Load messages and start polling
    loadMessages(refresh: true);
    _startPolling();
  }

  /// Load chat messages
  Future<void> loadMessages({bool refresh = false}) async {
    if (_conversationId == null) return;

    try {
      if (refresh) {
        _setLoading(true);
        _currentPage = 1;
        _hasMore = true;
        _messages.clear();
      } else {
        _setLoadingMore(true);
      }

      _logger.d(
        'Loading messages - Page: $_currentPage, Conversation: $_conversationId',
      );

      final result = await _getChatMessagesUseCase(
        GetChatMessagesParams(
          conversationId: _conversationId!,
          page: _currentPage,
          limit: 50,
        ),
      );

      result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to load messages: ${failure.message}');
        },
        (messages) {
          if (refresh) {
            _messages = messages;
          } else {
            _messages.insertAll(0, messages);
          }

          _currentPage++;
          _hasMore = messages.length >= 50;

          // Mark messages as read
          _markMessagesAsRead();

          _logger.d('Loaded ${messages.length} messages');
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error loading messages', error: e);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  /// Load more messages (older messages)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _conversationId == null) return;

    await loadMessages(refresh: false);
  }

  /// Send message
  Future<bool> sendMessage() async {
    if (_messageInput.trim().isEmpty || _conversationId == null) return false;

    final content = _messageInput.trim();

    try {
      _setSendingMessage(true);
      _clearError();

      _logger.d('Sending message: "$content"');

      // Create temporary message for immediate UI update
      final tempMessage = ChatMessage(
        id: -1, // Temporary ID
        conversationId: _conversationId!,
        senderId: 0, // Current user ID (to be set by auth provider)
        senderName: 'You',
        content: content,
        type: 'text',
        isFromCurrentUser: true,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Add message to UI immediately
      _messages.add(tempMessage);
      _messageInput = '';
      notifyListeners();

      final result = await _sendMessageUseCase(
        SendMessageParams(
          conversationId: _conversationId!,
          content: content,
          type: 'text',
        ),
      );

      return result.fold(
        (failure) {
          // Remove temporary message and show error
          _messages.removeWhere((m) => m.id == -1);
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to send message: ${failure.message}');
          return false;
        },
        (sentMessage) {
          // Replace temporary message with real message
          final index = _messages.indexWhere((m) => m.id == -1);
          if (index != -1) {
            _messages[index] = sentMessage;
          }

          _logger.d('Message sent successfully');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error sending message', error: e);
      return false;
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Send image message
  Future<bool> sendImageMessage(String imagePath) async {
    if (_conversationId == null) return false;

    try {
      _setSendingMessage(true);
      _clearError();

      _logger.d('Sending image message: $imagePath');

      final result = await _sendMessageUseCase(
        SendMessageParams(
          conversationId: _conversationId!,
          content: imagePath,
          type: 'image',
        ),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to send image: ${failure.message}');
          return false;
        },
        (sentMessage) {
          _messages.add(sentMessage);
          _logger.d('Image sent successfully');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error sending image', error: e);
      return false;
    } finally {
      _setSendingMessage(false);
    }
  }

  /// Update message input
  void updateMessageInput(String input) {
    _messageInput = input;
    _handleTypingIndicator();
    notifyListeners();
  }

  /// Clear message input
  void clearMessageInput() {
    _messageInput = '';
    notifyListeners();
  }

  /// Handle typing indicator
  void _handleTypingIndicator() {
    final now = DateTime.now();
    _lastTypingTime = now;

    if (!_isTyping) {
      _isTyping = true;
      notifyListeners();

      // Stop typing indicator after 3 seconds of inactivity
      Future.delayed(const Duration(seconds: 3), () {
        if (_lastTypingTime != null &&
            DateTime.now().difference(_lastTypingTime!).inSeconds >= 3) {
          _isTyping = false;
          notifyListeners();
        }
      });
    }
  }

  /// Add new message (for real-time updates)
  void addNewMessage(ChatMessage message) {
    if (message.conversationId == _conversationId) {
      _messages.add(message);

      // Mark as read if not from current user
      if (!message.isFromCurrentUser) {
        _markMessageAsRead(message.id);
      }

      notifyListeners();
    }
  }

  /// Update message (for real-time updates)
  void updateMessage(ChatMessage updatedMessage) {
    final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  /// Mark messages as read
  Future<void> _markMessagesAsRead() async {
    if (_conversationId == null) return;

    final unreadMessages = _messages
        .where((message) => !message.isRead && !message.isFromCurrentUser)
        .toList();

    for (final message in unreadMessages) {
      await _markMessageAsRead(message.id);
    }
  }

  /// Mark single message as read
  Future<void> _markMessageAsRead(int messageId) async {
    try {
      await _markMessageReadUseCase(
        MarkMessageReadParams(messageId: messageId),
      );

      // Update local state
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error marking message as read', error: e);
    }
  }

  /// Start polling for new messages
  void _startPolling() {
    _stopPolling(); // Stop any existing polling

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_conversationId != null) {
        _pollForNewMessages();
      }
    });

    _logger.d('Started polling for conversation $_conversationId');
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _logger.d('Stopped polling');
  }

  /// Poll for new messages
  Future<void> _pollForNewMessages() async {
    if (_conversationId == null) return;

    try {
      final result = await _getChatMessagesUseCase(
        GetChatMessagesParams(
          conversationId: _conversationId!,
          page: 1,
          limit: 1, // Only get the latest message
        ),
      );

      result.fold(
        (failure) {
          // Silently handle polling errors
          _logger.e('Polling error: ${failure.message}');
        },
        (messages) {
          if (messages.isNotEmpty) {
            final latestMessage = messages.first;

            // Check if this is a new message
            if (_messages.isEmpty ||
                latestMessage.id > _messages.first.id ||
                !_messages.any((m) => m.id == latestMessage.id)) {
              // Add new message if it doesn't exist
              if (!_messages.any((m) => m.id == latestMessage.id)) {
                addNewMessage(latestMessage);
              }
            }
          }
        },
      );
    } catch (e) {
      _logger.e('Error polling for messages', error: e);
    }
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await loadMessages(refresh: true);
  }

  /// Get message by ID
  ChatMessage? getMessageById(int messageId) {
    try {
      return _messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Get messages by date grouping
  Map<String, List<ChatMessage>> getMessagesByDate() {
    final Map<String, List<ChatMessage>> groupedMessages = {};

    for (final message in _messages) {
      final date = _formatMessageDate(message.createdAt);

      if (!groupedMessages.containsKey(date)) {
        groupedMessages[date] = [];
      }

      groupedMessages[date]!.add(message);
    }

    return groupedMessages;
  }

  /// Format message date for grouping
  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return '${date.day} ${_getMonthName(date.month)}';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Format timestamp for display
  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (timestamp.year == now.year) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Check if message should show timestamp
  bool shouldShowTimestamp(ChatMessage message, ChatMessage? previousMessage) {
    if (previousMessage == null) return true;

    final timeDifference = message.createdAt.difference(
      previousMessage.createdAt,
    );
    return timeDifference.inMinutes >= 5;
  }

  /// Check if message should show avatar
  bool shouldShowAvatar(ChatMessage message, ChatMessage? nextMessage) {
    if (message.isFromCurrentUser) return false;
    if (nextMessage == null) return true;
    if (nextMessage.isFromCurrentUser) return true;

    final timeDifference = nextMessage.createdAt.difference(message.createdAt);
    return timeDifference.inMinutes >= 5;
  }

  /// Get typing indicator text
  String getTypingIndicatorText() {
    if (_typingUsers.isEmpty) return '';

    final count = _typingUsers.length;
    if (count == 1) {
      return 'Someone is typing...';
    } else if (count <= 3) {
      return '$count people are typing...';
    } else {
      return 'Several people are typing...';
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set loading more state
  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  /// Set sending message state
  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Public method to clear error
  void clearError() {
    _clearError();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Session expired. Please login again.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'Conversation not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Reset provider state
  void reset() {
    _stopPolling();
    _messages.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _isSendingMessage = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _messageInput = '';
    _isTyping = false;
    _typingUsers.clear();
    _lastTypingTime = null;
    _conversationId = null;
    _userName = null;
    _userAvatar = null;
    _isGroupChat = false;
    _otherUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
