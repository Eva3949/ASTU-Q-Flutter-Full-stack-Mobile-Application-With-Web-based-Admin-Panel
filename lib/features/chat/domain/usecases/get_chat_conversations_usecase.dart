import '../../../../core/errors/failures.dart';
import '../entities/chat_conversation.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Get Chat Conversations Parameters
class GetChatConversationsParams {
  final int page;
  final int limit;
  final String? search;

  const GetChatConversationsParams({
    required this.page,
    required this.limit,
    this.search,
  });
}

/// Get Chat Conversations Use Case
/// Retrieves all conversations for the current user
class GetChatConversationsUseCase
    implements UseCase<List<ChatConversation>, GetChatConversationsParams> {
  final ChatRepository _repository;

  GetChatConversationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChatConversation>>> call(
    GetChatConversationsParams params,
  ) async {
    return await _repository.getConversations(
      page: params.page,
      limit: params.limit,
      search: params.search,
    );
  }
}
