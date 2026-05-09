import '../../../../core/types/either.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Delete Question Use Case
/// Handles the deletion of a question
class DeleteQuestionUseCase {
  final QuestionRepository _repository;

  DeleteQuestionUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [void] on success
  Future<Either<Failure, void>> call(int questionId) async {
    return await _repository.deleteQuestion(questionId);
  }
}
