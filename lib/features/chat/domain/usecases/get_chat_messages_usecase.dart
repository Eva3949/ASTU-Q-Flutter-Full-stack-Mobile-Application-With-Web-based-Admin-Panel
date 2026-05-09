import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Get Chat Messages Parameters
class GetChatMessagesParams {
  final int conversationId;
  final int page;
  final int limit;

  const GetChatMessagesParams({
    required this.conversationId,
    required this.page,
    required this.limit,
  });
}

/// Get Chat Messages Use Case
/// Retrieves messages for a specific conversation with pagination
class GetChatMessagesUseCase
    implements UseCase<List<ChatMessage>, GetChatMessagesParams> {
  final ChatRepository _repository;

  GetChatMessagesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetChatMessagesParams params,
  ) async {
    return await _repository.getMessages(
      conversationId: params.conversationId,
      page: params.page,
      limit: params.limit,
    );
  }
}
