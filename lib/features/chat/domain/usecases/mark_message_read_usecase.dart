import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/types/either.dart';
import 'usecase.dart';

/// Mark Message Read Parameters
class MarkMessageReadParams {
  final int messageId;

  const MarkMessageReadParams({required this.messageId});
}

/// Mark Message Read Use Case
/// Marks a message as read
class MarkMessageReadUseCase implements UseCase<void, MarkMessageReadParams> {
  final ChatRepository _repository;

  MarkMessageReadUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(MarkMessageReadParams params) async {
    return await _repository.markMessageAsRead(params.messageId);
  }
}
