import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Mark Conversation Read Parameters
class MarkConversationReadParams {
  final int conversationId;

  const MarkConversationReadParams({required this.conversationId});
}

/// Mark Conversation Read Use Case
/// Marks all messages in a conversation as read
class MarkConversationReadUseCase
    implements UseCase<void, MarkConversationReadParams> {
  final ChatRepository _repository;

  MarkConversationReadUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(MarkConversationReadParams params) async {
    return await _repository.markConversationAsRead(params.conversationId);
  }
}
