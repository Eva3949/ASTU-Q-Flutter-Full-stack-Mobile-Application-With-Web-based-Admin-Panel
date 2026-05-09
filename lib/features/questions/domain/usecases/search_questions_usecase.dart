import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Search Questions Use Case
/// Handles searching questions by query with pagination
class SearchQuestionsUseCase {
  final QuestionRepository _repository;

  SearchQuestionsUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [List<Question>] on success
  Future<Either<Failure, List<Question>>> call(
    SearchQuestionsParams params,
  ) async {
    return await _repository.getQuestions(
      page: params.page,
      limit: params.limit,
      search: params.query,
    );
  }
}

/// Parameters for searching questions
class SearchQuestionsParams {
  final String query;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  SearchQuestionsParams({
    required this.query,
    required this.page,
    required this.limit,
    this.sortBy,
    this.sortOrder,
  });
}
