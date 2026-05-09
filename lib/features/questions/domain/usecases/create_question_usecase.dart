import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Create Question Use Case
/// Handles the creation of a new question
class CreateQuestionUseCase {
  final QuestionRepository _repository;

  CreateQuestionUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Question] on success
  Future<Either<Failure, Question>> call(CreateQuestionParams params) async {
    return await _repository.createQuestion(params);
  }
}

/// Parameters for creating a question
class CreateQuestionParams {
  final String title;
  final String content;
  final String subject;
  final List<String> images;
  final List<String> tags;
  final String? userId;

  CreateQuestionParams({
    required this.title,
    required this.content,
    required this.subject,
    required this.images,
    required this.tags,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'subject': subject,
      'images': images,
      'tags': tags,
      'user_id': userId,
    };
  }
}
