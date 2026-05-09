import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Update Question Use Case
/// Handles the updating of an existing question
class UpdateQuestionUseCase {
  final QuestionRepository _repository;

  UpdateQuestionUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Question] on success
  Future<Either<Failure, Question>> call(Question question) async {
    return await _repository.updateQuestion(question);
  }
}
