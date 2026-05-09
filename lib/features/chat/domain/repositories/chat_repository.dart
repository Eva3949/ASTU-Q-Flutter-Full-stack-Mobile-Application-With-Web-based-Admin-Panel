import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/types/either.dart';

/// Chat repository interface
/// Defines the contract for chat data operations
abstract class ChatRepository {
  /// Get all conversations for the current user
  Future<Either<Failure, List<ChatConversation>>> getConversations({
    required int page,
    required int limit,
    String? search,
  });

  /// Get messages for a specific conversation
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required int conversationId,
    required int page,
    required int limit,
  });

  /// Send a new message
  Future<Either<Failure, ChatMessage>> sendMessage({
    required int conversationId,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
  });

  /// Delete a conversation and all its messages
  Future<Either<Failure, void>> deleteConversation(int conversationId);

  /// Mark a conversation as read
  Future<Either<Failure, void>> markConversationAsRead(int conversationId);

  /// Mark a message as read
  Future<Either<Failure, void>> markMessageAsRead(int messageId);
}
