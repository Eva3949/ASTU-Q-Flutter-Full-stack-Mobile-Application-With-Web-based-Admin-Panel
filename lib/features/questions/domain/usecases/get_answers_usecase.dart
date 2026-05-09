import '../../../../core/types/either.dart';
import '../entities/answer.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Get Answers Use Case
/// Handles fetching answers for a specific question with pagination
class GetAnswersUseCase {
  final QuestionRepository _repository;

  GetAnswersUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [List<Answer>] on success
  Future<Either<Failure, List<Answer>>> call(GetAnswersParams params) async {
    return await _repository.getAnswers(params);
  }
}

/// Parameters for getting answers
class GetAnswersParams {
  final int questionId;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  GetAnswersParams({
    required this.questionId,
    required this.page,
    required this.limit,
    this.sortBy,
    this.sortOrder,
  });
}
