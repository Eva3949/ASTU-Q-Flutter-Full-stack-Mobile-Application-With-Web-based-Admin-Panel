import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'chat_list_provider.dart';
import 'chat_detail_provider.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/utils/logger.dart';

/// Chat Provider
/// Main chat provider that coordinates between chat list and chat detail providers
/// Acts as a unified interface for chat functionality
class ChatProvider extends ChangeNotifier {
  ChatListProvider? _chatListProvider;
  ChatDetailProvider? _chatDetailProvider;
  final Logger _logger = Logger();

  ChatProvider() {
    _initializeProviders();
  }

  void _initializeProviders() {
    try {
      _chatListProvider = GetIt.instance<ChatListProvider>();
      _chatDetailProvider = GetIt.instance<ChatDetailProvider>();
    } catch (e) {
      _logger.e('Failed to initialize chat providers: $e');
    }
  }

  ChatListProvider get chatListProvider {
    if (_chatListProvider == null) {
      _initializeProviders();
    }
    return _chatListProvider!;
  }

  ChatDetailProvider get chatDetailProvider {
    if (_chatDetailProvider == null) {
      _initializeProviders();
    }
    return _chatDetailProvider!;
  }

  // Chat List delegation
  List<ChatConversation> get conversations => chatListProvider.conversations;
  bool get isLoadingConversations => chatListProvider.isLoading;
  bool get isLoadingMoreConversations => chatListProvider.isLoadingMore;
  String? get conversationsError => chatListProvider.errorMessage;
  bool get hasMoreConversations => chatListProvider.hasMore;
  String get searchQuery => chatListProvider.searchQuery;
  String get selectedFilter => chatListProvider.selectedFilter;
  int get conversationCount => chatListProvider.conversationCount;
  int get unreadConversationsCount => chatListProvider.unreadConversationsCount;
  int get totalUnreadMessagesCount => chatListProvider.totalUnreadMessagesCount;

  // Chat Detail delegation
  List<ChatMessage> get messages => chatDetailProvider.messages;
  bool get isLoadingMessages => chatDetailProvider.isLoading;
  bool get isLoadingMoreMessages => chatDetailProvider.isLoadingMore;
  bool get isSendingMessage => chatDetailProvider.isSendingMessage;
  String? get messagesError => chatDetailProvider.errorMessage;
  bool get hasMoreMessages => chatDetailProvider.hasMore;
  String get messageInput => chatDetailProvider.messageInput;
  bool get isTyping => chatDetailProvider.isTyping;
  int get messageCount => chatDetailProvider.messageCount;
  int get unreadMessagesCount => chatDetailProvider.unreadMessagesCount;

  // Conversation info delegation
  int? get currentConversationId => chatDetailProvider.conversationId;
  String? get currentUserName => chatDetailProvider.userName;
  String? get currentUserAvatar => chatDetailProvider.userAvatar;
  bool get isGroupChat => chatDetailProvider.isGroupChat;

  // Computed properties
  List<ChatConversation> get filteredConversations =>
      chatListProvider.filteredConversations;

  /// Initialize chat functionality
  Future<void> initialize() async {
    try {
      _logger.d('Initializing chat provider');
      await loadConversations(refresh: true);
    } catch (e) {
      _logger.e('Error initializing chat provider', error: e);
    }
  }

  // Chat List Methods
  /// Load chat conversations
  Future<void> loadConversations({bool refresh = false}) async {
    await chatListProvider.loadConversations(refresh: refresh);
    notifyListeners();
  }

  /// Load more conversations
  Future<void> loadMoreConversations() async {
    await chatListProvider.loadMoreConversations();
    notifyListeners();
  }

  /// Refresh conversations
  Future<void> refreshConversations() async {
    await chatListProvider.refreshConversations();
    notifyListeners();
  }

  /// Mark conversation as read
  Future<bool> markConversationAsRead(int conversationId) async {
    final result = await chatListProvider.markConversationAsRead(
      conversationId,
    );
    notifyListeners();
    return result;
  }

  /// Delete conversation
  Future<bool> deleteConversation(int conversationId) async {
    final result = await chatListProvider.deleteConversation(conversationId);

    // If current conversation is deleted, reset detail provider
    if (currentConversationId == conversationId) {
      chatDetailProvider.reset();
    }

    notifyListeners();
    return result;
  }

  /// Search conversations
  void searchConversations(String query) {
    chatListProvider.searchConversations(query);
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    chatListProvider.clearSearch();
    notifyListeners();
  }

  /// Set filter
  void setFilter(String filter) {
    chatListProvider.setFilter(filter);
    notifyListeners();
  }

  /// Get conversation by ID
  ChatConversation? getConversationById(int conversationId) {
    return chatListProvider.getConversationById(conversationId);
  }

  /// Get available filters
  List<Map<String, dynamic>> getAvailableFilters() {
    return chatListProvider.getAvailableFilters();
  }

  /// Format timestamp
  String formatTimestamp(DateTime timestamp) {
    return chatListProvider.formatTimestamp(timestamp);
  }

  /// Get last message preview
  String getLastMessagePreview(ChatConversation conversation) {
    return chatListProvider.getLastMessagePreview(conversation);
  }

  /// Check if conversation is active
  bool isConversationActive(ChatConversation conversation) {
    return chatListProvider.isConversationActive(conversation);
  }

  /// Get online status
  String getOnlineStatus(ChatConversation conversation) {
    return chatListProvider.getOnlineStatus(conversation);
  }

  // Chat Detail Methods
  /// Initialize chat with conversation
  void initializeChat({
    required int conversationId,
    String? userName,
    String? userAvatar,
    bool isGroupChat = false,
    ChatUser? otherUser,
  }) {
    chatDetailProvider.initializeChat(
      conversationId: conversationId,
      userName: userName,
      userAvatar: userAvatar,
      isGroupChat: isGroupChat,
      otherUser: otherUser,
    );
    notifyListeners();
  }

  /// Load chat messages
  Future<void> loadMessages({bool refresh = false}) async {
    await chatDetailProvider.loadMessages(refresh: refresh);
    notifyListeners();
  }

  /// Load more messages
  Future<void> loadMoreMessages() async {
    await chatDetailProvider.loadMoreMessages();
    notifyListeners();
  }

  /// Send message
  Future<bool> sendMessage() async {
    final result = await chatDetailProvider.sendMessage();

    if (result) {
      // Update conversation list with new message
      final lastMessage = chatDetailProvider.messages.isNotEmpty
          ? chatDetailProvider.messages.last
          : null;

      if (lastMessage != null) {
        chatListProvider.updateConversationWithMessage(lastMessage);
      }
    }

    notifyListeners();
    return result;
  }

  /// Send image message
  Future<bool> sendImageMessage(String imagePath) async {
    final result = await chatDetailProvider.sendImageMessage(imagePath);

    if (result) {
      // Update conversation list with new message
      final lastMessage = chatDetailProvider.messages.isNotEmpty
          ? chatDetailProvider.messages.last
          : null;

      if (lastMessage != null) {
        chatListProvider.updateConversationWithMessage(lastMessage);
      }
    }

    notifyListeners();
    return result;
  }

  /// Update message input
  void updateMessageInput(String input) {
    chatDetailProvider.updateMessageInput(input);
    notifyListeners();
  }

  /// Clear message input
  void clearMessageInput() {
    chatDetailProvider.clearMessageInput();
    notifyListeners();
  }

  /// Add new message (for real-time updates)
  void addNewMessage(ChatMessage message) {
    chatDetailProvider.addNewMessage(message);
    chatListProvider.updateConversationWithMessage(message);
    notifyListeners();
  }

  /// Update message (for real-time updates)
  void updateMessage(ChatMessage updatedMessage) {
    chatDetailProvider.updateMessage(updatedMessage);
    notifyListeners();
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await chatDetailProvider.refreshMessages();
    notifyListeners();
  }

  /// Get message by ID
  ChatMessage? getMessageById(int messageId) {
    return chatDetailProvider.getMessageById(messageId);
  }

  /// Get messages by date grouping
  Map<String, List<ChatMessage>> getMessagesByDate() {
    return chatDetailProvider.getMessagesByDate();
  }

  /// Format message time for display
  String formatMessageTime(DateTime timestamp) {
    return chatDetailProvider.formatMessageTime(timestamp);
  }

  /// Check if message should show timestamp
  bool shouldShowTimestamp(ChatMessage message, ChatMessage? previousMessage) {
    return chatDetailProvider.shouldShowTimestamp(message, previousMessage);
  }

  /// Check if message should show avatar
  bool shouldShowAvatar(ChatMessage message, ChatMessage? nextMessage) {
    return chatDetailProvider.shouldShowAvatar(message, nextMessage);
  }

  /// Get typing indicator text
  String getTypingIndicatorText() {
    return chatDetailProvider.getTypingIndicatorText();
  }

  // Utility Methods
  /// Get unread count for specific conversation
  int getUnreadCountForConversation(int conversationId) {
    final conversation = getConversationById(conversationId);
    return conversation?.unreadCount ?? 0;
  }

  /// Get total unread count across all conversations
  int getTotalUnreadCount() {
    return totalUnreadMessagesCount;
  }

  /// Check if there are any unread messages
  bool get hasUnreadMessages => totalUnreadMessagesCount > 0;

  /// Get most recent conversation
  ChatConversation? getMostRecentConversation() {
    if (filteredConversations.isEmpty) return null;
    return filteredConversations.first;
  }

  /// Clear all errors
  void clearErrors() {
    // Clear errors by accessing and resetting the providers
    _chatListProvider?.clearError();
    _chatDetailProvider?.clearError();
    notifyListeners();
  }

  /// Reset all chat state
  void reset() {
    _chatListProvider?.reset();
    _chatDetailProvider?.reset();
    notifyListeners();
  }

  /// Reset conversation list only
  void resetConversationList() {
    _chatListProvider?.reset();
    notifyListeners();
  }

  /// Reset current conversation only
  void resetCurrentConversation() {
    _chatDetailProvider?.reset();
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    // Don't dispose child providers here as they might be shared
    super.dispose();
  }
}
