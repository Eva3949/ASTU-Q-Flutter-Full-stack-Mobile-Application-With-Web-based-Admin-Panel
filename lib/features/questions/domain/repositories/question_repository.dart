import '../../../../core/types/either.dart';
import '../entities/question.dart';
import '../entities/answer.dart';
import '../usecases/create_question_usecase.dart';
import '../usecases/upload_image_usecase.dart';
import '../usecases/get_answers_usecase.dart';
import '../usecases/create_answer_usecase.dart';
import '../usecases/vote_answer_usecase.dart';
import '../usecases/vote_question_usecase.dart';
import '../usecases/mark_best_answer_usecase.dart';
import '../../../../core/errors/failures.dart';

/// Question Repository Interface
/// Defines the contract for question data operations
abstract class QuestionRepository {
  /// Create a new question
  Future<Either<Failure, Question>> createQuestion(CreateQuestionParams params);

  /// Upload an image
  Future<Either<Failure, String>> uploadImage(UploadImageParams params);

  /// Get question by ID
  Future<Either<Failure, Question>> getQuestionById(int id);

  /// Get questions list with pagination
  Future<Either<Failure, List<Question>>> getQuestions({
    int page = 1,
    int limit = 20,
    String? subject,
    String? search,
  });

  /// Update question
  Future<Either<Failure, Question>> updateQuestion(Question question);

  /// Delete question
  Future<Either<Failure, void>> deleteQuestion(int id);

  /// Upvote question
  Future<Either<Failure, Question>> upvoteQuestion(int questionId);

  /// Downvote question
  Future<Either<Failure, Question>> downvoteQuestion(int questionId);

  /// Bookmark question
  Future<Either<Failure, Question>> bookmarkQuestion(int questionId);

  /// Remove bookmark
  Future<Either<Failure, Question>> removeBookmark(int id);

  /// Get answers for a question
  Future<Either<Failure, List<Answer>>> getAnswers(GetAnswersParams params);

  /// Create a new answer
  Future<Either<Failure, Answer>> createAnswer(CreateAnswerParams params);

  /// Vote on an answer
  Future<Either<Failure, Answer>> voteAnswer(VoteAnswerParams params);

  /// Vote on a question
  Future<Either<Failure, Question>> voteQuestion(VoteQuestionParams params);

  /// Mark an answer as best answer
  Future<Either<Failure, void>> markBestAnswer(MarkBestAnswerParams params);
}
