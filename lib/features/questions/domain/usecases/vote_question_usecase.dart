import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';
import 'vote_answer_usecase.dart'; // Import VoteType

/// Vote Question Use Case
/// Handles voting on a question (upvote/downvote)
class VoteQuestionUseCase {
  final QuestionRepository _repository;

  VoteQuestionUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Question] on success
  Future<Either<Failure, Question>> call(VoteQuestionParams params) async {
    return await _repository.voteQuestion(params);
  }
}

/// Parameters for voting on a question
class VoteQuestionParams {
  final int questionId;
  final VoteType voteType;

  VoteQuestionParams({required this.questionId, required this.voteType});
}
