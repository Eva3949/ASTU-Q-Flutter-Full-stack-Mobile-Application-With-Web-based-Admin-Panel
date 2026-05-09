import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Filter Questions By Subject Use Case
/// Handles filtering questions by subject with pagination
class FilterQuestionsBySubjectUseCase {
  final QuestionRepository _repository;

  FilterQuestionsBySubjectUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [List<Question>] on success
  Future<Either<Failure, List<Question>>> call(
    FilterQuestionsParams params,
  ) async {
    return await _repository.getQuestions(
      page: params.page,
      limit: params.limit,
      subject: params.subject,
    );
  }
}

/// Parameters for filtering questions by subject
class FilterQuestionsParams {
  final String subject;
  final int page;
  final int limit;
  final String? sortBy;
  final String? sortOrder;

  FilterQuestionsParams({
    required this.subject,
    required this.page,
    required this.limit,
    this.sortBy,
    this.sortOrder,
  });
}
