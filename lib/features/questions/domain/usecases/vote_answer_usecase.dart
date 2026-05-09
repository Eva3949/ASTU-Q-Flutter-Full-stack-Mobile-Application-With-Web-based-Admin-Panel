import '../../../../core/types/either.dart';
import '../entities/answer.dart';
import '../repositories/question_repository.dart';
import '../../../../core/errors/failures.dart';

/// Vote Answer Use Case
/// Handles voting on an answer (upvote/downvote)
class VoteAnswerUseCase {
  final QuestionRepository _repository;

  VoteAnswerUseCase(this._repository);

  /// Execute the use case
  /// Returns [Failure] on error or [Answer] on success
  Future<Either<Failure, Answer>> call(VoteAnswerParams params) async {
    return await _repository.voteAnswer(params);
  }
}

/// Vote Types
enum VoteType { upvote, downvote }

/// Parameters for voting on an answer
class VoteAnswerParams {
  final int answerId;
  final VoteType voteType;

  VoteAnswerParams({required this.answerId, required this.voteType});
}
