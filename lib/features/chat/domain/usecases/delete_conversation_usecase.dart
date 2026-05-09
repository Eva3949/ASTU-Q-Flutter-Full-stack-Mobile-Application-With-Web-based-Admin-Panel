import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Delete Conversation Parameters
class DeleteConversationParams {
  final int conversationId;

  const DeleteConversationParams({required this.conversationId});
}

/// Delete Conversation Use Case
/// Deletes a conversation and all its messages
class DeleteConversationUseCase
    implements UseCase<void, DeleteConversationParams> {
  final ChatRepository _repository;

  DeleteConversationUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) async {
    return await _repository.deleteConversation(params.conversationId);
  }
}
