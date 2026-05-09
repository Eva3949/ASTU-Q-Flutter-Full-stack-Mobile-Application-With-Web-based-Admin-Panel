import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Send Message Parameters
class SendMessageParams {
  final int conversationId;
  final String content;
  final String type;
  final Map<String, dynamic>? metadata;

  const SendMessageParams({
    required this.conversationId,
    required this.content,
    required this.type,
    this.metadata,
  });
}

/// Send Message Use Case
/// Sends a new message to a conversation
class SendMessageUseCase implements UseCase<ChatMessage, SendMessageParams> {
  final ChatRepository _repository;

  SendMessageUseCase(this._repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return await _repository.sendMessage(
      conversationId: params.conversationId,
      content: params.content,
      type: params.type,
      metadata: params.metadata,
    );
  }
}
