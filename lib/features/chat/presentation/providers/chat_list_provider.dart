import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_chat_conversations_usecase.dart';
import '../../domain/usecases/mark_conversation_read_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/usecase.dart';

/// Chat List Provider
/// Manages chat conversations list state and operations
class ChatListProvider extends ChangeNotifier {
  final UseCase<List<ChatConversation>, GetChatConversationsParams>
  _getChatConversationsUseCase;
  final UseCase<void, MarkConversationReadParams> _markConversationReadUseCase;
  final UseCase<void, DeleteConversationParams> _deleteConversationUseCase;
  final Logger _logger;

  ChatListProvider(
    this._getChatConversationsUseCase,
    this._markConversationReadUseCase,
    this._deleteConversationUseCase,
    this._logger,
  );

  // State variables
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // Getters
  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  int get conversationCount => _conversations.length;

  // Filtered conversations
  List<ChatConversation> get filteredConversations {
    var filtered = _conversations;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conversation) {
        final query = _searchQuery.toLowerCase();
        final userName = conversation.otherUser?.name.toLowerCase() ?? '';
        final lastMessage =
            conversation.lastMessage?.content.toLowerCase() ?? '';

        return userName.contains(query) || lastMessage.contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'unread':
        filtered = filtered.where((c) => c.unreadCount > 0).toList();
        break;
      case 'starred':
        filtered = filtered.where((c) => c.isStarred).toList();
        break;
      case 'groups':
        filtered = filtered.where((c) => c.isGroupChat).toList();
        break;
      case 'individual':
        filtered = filtered.where((c) => !c.isGroupChat).toList();
        break;
      case 'all':
      default:
        // No filtering
        break;
    }

    // Sort by last message time (most recent first)
    filtered.sort((a, b) {
      final aTime =
          a.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastMessage?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  // Unread conversations count
  int get unreadConversationsCount {
    return _conversations.where((c) => c.unreadCount > 0).length;
  }

  // Total unread messages count
  int get totalUnreadMessagesCount {
    return _conversations.fold<int>(
      0,
      (sum, conversation) => sum + conversation.unreadCount,
    );
  }

  /// Load chat conversations
  Future<void> loadConversations({bool refresh = false}) async {
    try {
      if (refresh) {
        _setLoading(true);
        _currentPage = 1;
        _hasMore = true;
        _conversations.clear();
      } else {
        _setLoadingMore(true);
      }

      _logger.d('Loading conversations - Page: $_currentPage');

      final result = await _getChatConversationsUseCase(
        GetChatConversationsParams(page: _currentPage, limit: 20),
      );

      result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to load conversations: ${failure.message}');
        },
        (conversations) {
          if (refresh) {
            _conversations = conversations;
          } else {
            _conversations.addAll(conversations);
          }

          _currentPage++;
          _hasMore = conversations.length >= 20;

          _logger.d('Loaded ${conversations.length} conversations');
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error loading conversations', error: e);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  /// Load more conversations
  Future<void> loadMoreConversations() async {
    if (_isLoadingMore || !_hasMore) return;

    await loadConversations(refresh: false);
  }

  /// Refresh conversations
  Future<void> refreshConversations() async {
    await loadConversations(refresh: true);
  }

  /// Mark conversation as read
  Future<bool> markConversationAsRead(int conversationId) async {
    try {
      _logger.d('Marking conversation $conversationId as read');

      final result = await _markConversationReadUseCase(
        MarkConversationReadParams(conversationId: conversationId),
      );

      return result.fold(
        (failure) {
          _logger.e('Failed to mark conversation as read: ${failure.message}');
          return false;
        },
        (success) {
          // Update local state
          final index = _conversations.indexWhere(
            (c) => c.id == conversationId,
          );
          if (index != -1) {
            _conversations[index] = _conversations[index].copyWith(
              unreadCount: 0,
              lastMessage: _conversations[index].lastMessage?.copyWith(
                isRead: true,
              ),
            );
            notifyListeners();
          }

          _logger.d('Conversation marked as read successfully');
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error marking conversation as read', error: e);
      return false;
    }
  }

  /// Delete conversation
  Future<bool> deleteConversation(int conversationId) async {
    try {
      _logger.d('Deleting conversation $conversationId');

      final result = await _deleteConversationUseCase(
        DeleteConversationParams(conversationId: conversationId),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to delete conversation: ${failure.message}');
          return false;
        },
        (success) {
          // Remove from local state
          _conversations.removeWhere((c) => c.id == conversationId);
          notifyListeners();

          _logger.d('Conversation deleted successfully');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error deleting conversation', error: e);
      return false;
    }
  }

  /// Search conversations
  void searchConversations(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Update conversation with new message
  void updateConversationWithMessage(ChatMessage message) {
    final index = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );

    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: message,
        unreadCount: message.isRead
            ? _conversations[index].unreadCount
            : _conversations[index].unreadCount + 1,
        updatedAt: DateTime.now(),
      );

      // Move conversation to top
      final conversation = _conversations.removeAt(index);
      _conversations.insert(0, conversation);

      notifyListeners();
    }
  }

  /// Get conversation by ID
  ChatConversation? getConversationById(int conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  /// Get available filters
  List<Map<String, dynamic>> getAvailableFilters() {
    return [
      {
        'key': 'all',
        'label': 'All',
        'icon': Icons.all_inbox,
        'count': _conversations.length,
      },
      {
        'key': 'unread',
        'label': 'Unread',
        'icon': Icons.mark_unread_chat_alt,
        'count': unreadConversationsCount,
      },
      {
        'key': 'starred',
        'label': 'Starred',
        'icon': Icons.star,
        'count': _conversations.where((c) => c.isStarred).length,
      },
      {
        'key': 'groups',
        'label': 'Groups',
        'icon': Icons.group,
        'count': _conversations.where((c) => c.isGroupChat).length,
      },
      {
        'key': 'individual',
        'label': 'Individual',
        'icon': Icons.person,
        'count': _conversations.where((c) => !c.isGroupChat).length,
      },
    ];
  }

  /// Format timestamp
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (timestamp.year == now.year) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get last message preview
  String getLastMessagePreview(ChatConversation conversation) {
    final lastMessage = conversation.lastMessage;

    if (lastMessage == null) {
      return conversation.isGroupChat
          ? 'No messages yet'
          : 'Start a conversation';
    }

    String content = lastMessage.content;

    // Truncate long messages
    if (content.length > 50) {
      content = '${content.substring(0, 47)}...';
    }

    // Add sender name for group chats
    if (conversation.isGroupChat && !lastMessage.isFromCurrentUser) {
      content = '${lastMessage.senderName}: $content';
    }

    // Add message type indicator
    if (lastMessage.type != 'text') {
      switch (lastMessage.type) {
        case 'image':
          content = 'Photo';
          break;
        case 'file':
          content = 'File';
          break;
        case 'voice':
          content = 'Voice message';
          break;
        case 'location':
          content = 'Location';
          break;
        default:
          content = 'Attachment';
      }
    }

    return content;
  }

  /// Check if conversation is active (recent activity)
  bool isConversationActive(ChatConversation conversation) {
    final lastMessageTime =
        conversation.lastMessage?.createdAt ??
        conversation.updatedAt ??
        conversation.createdAt;
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    return difference.inHours < 24;
  }

  /// Get online status
  String getOnlineStatus(ChatConversation conversation) {
    if (conversation.isGroupChat) {
      final activeMembers =
          conversation.participants?.where((p) => p.isOnline).length ?? 0;
      return '$activeMembers online';
    } else {
      return conversation.otherUser?.isOnline ?? false ? 'Online' : 'Offline';
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
        return 'No conversations found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Reset provider state
  void reset() {
    _conversations.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _searchQuery = '';
    _selectedFilter = 'all';
    notifyListeners();
  }
}
