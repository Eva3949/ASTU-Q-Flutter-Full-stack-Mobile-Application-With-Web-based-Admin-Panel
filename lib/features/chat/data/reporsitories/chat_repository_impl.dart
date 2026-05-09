import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';

/// Mock implementation of ChatRepository for development/testing
/// In production, this would make actual API calls
class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations({
    required int page,
    required int limit,
    String? search,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 500));

      // Mock data - in production this would be an API call
      final mockConversations = <ChatConversation>[];

      // Add some mock conversations if search is not filtering them out
      if (search == null || search.isEmpty) {
        final now = DateTime.now();
        mockConversations.addAll([
          ChatConversation(
            id: 1,
            otherUser: ChatUser(id: 2, name: 'Dr. Sarah Johnson', avatar: null),
            lastMessage: ChatMessage(
              id: 3,
              conversationId: 1,
              senderId: 2,
              senderName: 'Dr. Sarah Johnson',
              content: 'Thank you for your question about calculus!',
              type: 'text',
              isFromCurrentUser: false,
              isRead: false,
              createdAt: now.subtract(Duration(minutes: 5)),
            ),
            unreadCount: 2,
            createdAt: now.subtract(Duration(days: 1)),
          ),
          ChatConversation(
            id: 2,
            otherUser: ChatUser(
              id: 3,
              name: 'Prof. Michael Chen',
              avatar: null,
            ),
            lastMessage: ChatMessage(
              id: 4,
              conversationId: 2,
              senderId: 3,
              senderName: 'Prof. Michael Chen',
              content: 'Here are the resources for physics homework...',
              type: 'text',
              isFromCurrentUser: false,
              isRead: true,
              createdAt: now.subtract(Duration(hours: 1)),
            ),
            unreadCount: 0,
            createdAt: now.subtract(Duration(days: 2)),
          ),
        ]);
      }

      return Either.right(mockConversations);
    } catch (e) {
      return Either.left(ServerFailure('Failed to load conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required int conversationId,
    required int page,
    required int limit,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 300));

      // Mock messages based on conversation ID
      final mockMessages = <ChatMessage>[];

      if (conversationId == 1) {
        mockMessages.addAll([
          ChatMessage(
            id: 1,
            conversationId: 1,
            senderId: 2,
            senderName: 'Dr. Sarah Johnson',
            content: 'Hello! How can I help you today?',
            type: 'text',
            isFromCurrentUser: false,
            isRead: true,
            createdAt: DateTime.now().subtract(Duration(hours: 2)),
          ),
          ChatMessage(
            id: 2,
            conversationId: 1,
            senderId: 1,
            senderName: 'You',
            content: 'I have a question about calculus derivatives',
            type: 'text',
            isFromCurrentUser: true,
            isRead: true,
            createdAt: DateTime.now().subtract(Duration(hours: 1, minutes: 50)),
          ),
          ChatMessage(
            id: 3,
            conversationId: 1,
            senderId: 2,
            senderName: 'Dr. Sarah Johnson',
            content: 'Thank you for your question about calculus!',
            type: 'text',
            isFromCurrentUser: false,
            isRead: false,
            createdAt: DateTime.now().subtract(Duration(minutes: 5)),
          ),
        ]);
      } else if (conversationId == 2) {
        mockMessages.addAll([
          ChatMessage(
            id: 4,
            conversationId: 2,
            senderId: 3,
            senderName: 'Prof. Michael Chen',
            content: 'Here are the resources for physics homework...',
            type: 'text',
            isFromCurrentUser: false,
            isRead: true,
            createdAt: DateTime.now().subtract(Duration(hours: 1)),
          ),
        ]);
      }

      return Either.right(mockMessages);
    } catch (e) {
      return Either.left(ServerFailure('Failed to load messages: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required int conversationId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 800));

      // Create a mock message representing the sent message
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch, // Mock ID
        conversationId: conversationId,
        senderId: 1, // Current user ID
        senderName: 'You',
        content: content,
        type: type,
        metadata: metadata,
        isFromCurrentUser: true,
        isRead: false,
        createdAt: DateTime.now(),
      );

      return Either.right(newMessage);
    } catch (e) {
      return Either.left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(int conversationId) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 500));

      // Mock deletion - in production this would make an API call
      // For now we just simulate success
      if (conversationId <= 0) {
        return Either.left(ValidationFailure('Invalid conversation ID'));
      }

      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure('Failed to delete conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markConversationAsRead(
    int conversationId,
  ) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 200));

      // Mock marking as read - in production this would make an API call
      if (conversationId <= 0) {
        return Either.left(ValidationFailure('Invalid conversation ID'));
      }

      return Either.right(null);
    } catch (e) {
      return Either.left(
        ServerFailure('Failed to mark conversation as read: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead(int messageId) async {
    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 200));

      // Mock marking as read - in production this would make an API call
      if (messageId <= 0) {
        return Either.left(ValidationFailure('Invalid message ID'));
      }

      return Either.right(null);
    } catch (e) {
      return Either.left(ServerFailure('Failed to mark message as read: $e'));
    }
  }
}
