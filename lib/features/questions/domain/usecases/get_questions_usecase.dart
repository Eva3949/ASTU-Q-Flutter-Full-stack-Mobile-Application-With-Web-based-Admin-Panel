import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Get Questions Use Case
/// Handles retrieving a list of questions with pagination
class GetQuestionsUseCase {
  final QuestionRepository _repository;

  GetQuestionsUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [List<Question>] on success
  Future<Either<Failure, List<Question>>> call(
    GetQuestionsParams params,
  ) async {
    return await _repository.getQuestions(
      page: params.page,
      limit: params.limit,
      subject: params.subject,
      search: params.search,
    );
  }
}

/// Parameters for getting questions
class GetQuestionsParams {
  final int page;
  final int limit;
  final String? subject;
  final String? search;
  final String? sortBy;
  final String? sortOrder;

  GetQuestionsParams({
    required this.page,
    required this.limit,
    this.subject,
    this.search,
    this.sortBy,
    this.sortOrder,
  });
}
