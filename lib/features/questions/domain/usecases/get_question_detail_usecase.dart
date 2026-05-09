import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Get Question Detail Use Case
/// Handles fetching a single question by its ID
class GetQuestionDetailUseCase {
  final QuestionRepository _repository;

  GetQuestionDetailUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Question] on success
  Future<Either<Failure, Question>> call(int questionId) async {
    return await _repository.getQuestionById(questionId);
  }
}
