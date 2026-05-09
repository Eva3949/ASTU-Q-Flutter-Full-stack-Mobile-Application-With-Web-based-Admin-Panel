import '../../../../core/types/either.dart';
import '../entities/answer.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Create Answer Use Case
/// Handles the creation of a new answer
class CreateAnswerUseCase {
  final QuestionRepository _repository;

  CreateAnswerUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Answer] on success
  Future<Either<Failure, Answer>> call(CreateAnswerParams params) async {
    return await _repository.createAnswer(params);
  }
}

/// Parameters for creating an answer
class CreateAnswerParams {
  final int questionId;
  final String content;
  final String? userId;

  CreateAnswerParams({
    required this.questionId,
    required this.content,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {'question_id': questionId, 'content': content, 'user_id': userId};
  }
}
