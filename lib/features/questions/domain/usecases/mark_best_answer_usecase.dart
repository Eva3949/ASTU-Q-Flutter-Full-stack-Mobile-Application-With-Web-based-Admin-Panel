import '../../../../core/types/either.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Mark Best Answer Use Case
/// Handles marking an answer as the best answer for a question
class MarkBestAnswerUseCase {
  final QuestionRepository _repository;

  MarkBestAnswerUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [void] on success
  Future<Either<Failure, void>> call(MarkBestAnswerParams params) async {
    return await _repository.markBestAnswer(params);
  }
}

/// Parameters for marking best answer
class MarkBestAnswerParams {
  final int answerId;
  final int questionId;

  MarkBestAnswerParams({required this.answerId, required this.questionId});
}
