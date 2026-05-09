import 'dart:io';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/usecases/create_question_usecase.dart';
import '../../domain/usecases/upload_image_usecase.dart';
import '../../domain/usecases/get_answers_usecase.dart';
import '../../domain/usecases/create_answer_usecase.dart';
import '../../domain/usecases/vote_answer_usecase.dart';
import '../../domain/usecases/vote_question_usecase.dart';
import '../../domain/usecases/mark_best_answer_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/types/either.dart';

/// Question Repository Implementation
/// Implements the QuestionRepository interface using Dio client
@singleton
class QuestionRepositoryImpl implements QuestionRepository {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;
  final Logger _logger;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  QuestionRepositoryImpl(this._dioClient, this._secureStorage, this._logger);

  @override
  Future<Either<Failure, Question>> createQuestion(
    CreateQuestionParams params,
  ) async {
    try {
      _logger.d('Creating question with title: ${params.title}');
      _logger.d('Images to send: ${params.images}');
      _logger.d('Tags to send: ${params.tags}');
      final userId = await _secureStorage.getUserId();

      final requestData = {
        'title': params.title,
        'content': params.content,
        'subject': params.subject,
        'images': params.images,
        'tags': params.tags,
        'user_id': userId ?? '1',
      };

      _logger.d('Request data: $requestData');

      final response = await _dioClient.post(
        '$_baseUrl/create_question.php',
        data: requestData,
      );

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final question = Question.fromJson(response.data['data']);
        _logger.d('Question created successfully with ID: ${question.id}');
        _logger.d('Question images from response: ${question.images}');
        return Either.right(question);
      } else {
        return Either.left(ServerFailure('Failed to create question'));
      }
    } catch (e) {
      _logger.e('Error creating question', error: e);
      return Either.left(ServerFailure('Failed to create question'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(UploadImageParams params) async {
    try {
      _logger.d('Uploading image: ${params.imagePath}');

      final file = File(params.imagePath);
      final response = await _dioClient.upload(
        '$_baseUrl/upload_image.php',
        file,
        data: {'type': params.folder},
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['data']['url'];
        _logger.d('Image uploaded successfully: $imageUrl');
        return Either.right(imageUrl);
      } else {
        return Either.left(ServerFailure('Failed to upload image'));
      }
    } catch (e) {
      _logger.e('Error uploading image', error: e);
      return Either.left(ServerFailure('Failed to upload image'));
    }
  }

  @override
  Future<Either<Failure, Question>> getQuestionById(int id) async {
    try {
      _logger.d('Getting question by ID: $id');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_question.php',
        queryParameters: {'question_id': id, 'viewer_id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final question = Question.fromJson(response.data['data']);
        _logger.d('Question retrieved successfully');
        return Either.right(question);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Question not found'),
        );
      }
    } catch (e) {
      _logger.e('Error getting question by ID', error: e);
      return Either.left(ServerFailure('Failed to get question'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestions({
    int page = 1,
    int limit = 20,
    String? subject,
    String? search,
  }) async {
    try {
      _logger.d(
        'Getting questions - page: $page, limit: $limit, subject: $subject, search: $search',
      );
      final userId = await _secureStorage.getUserId();

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'viewer_id': userId,
      };

      if (subject != null) {
        queryParams['subject'] = subject;
      }

      if (search != null) {
        queryParams['search'] = search;
      }

      final response = await _dioClient.get(
        '$_baseUrl/get_questions.php',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();

        _logger.d('Retrieved ${questions.length} questions');
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Failed to get questions'),
        );
      }
    } catch (e) {
      _logger.e('Error getting questions', error: e);
      return Either.left(ServerFailure('Failed to get questions'));
    }
  }

  @override
  Future<Either<Failure, Question>> updateQuestion(Question question) async {
    try {
      _logger.d('Updating question: ${question.id}');

      final response = await _dioClient.post(
        '$_baseUrl/update_question.php',
        data: {
          'question_id': question.id,
          'user_id': question.authorId,
          'title': question.title,
          'content': question.content,
          'subject': question.subject,
        },
      );

      if (response.statusCode == 200) {
        final updatedQuestion = Question.fromJson(response.data['data']);
        _logger.d('Question updated successfully');
        return Either.right(updatedQuestion);
      } else {
        return Either.left(ServerFailure('Failed to update question'));
      }
    } catch (e) {
      _logger.e('Error updating question', error: e);
      return Either.left(ServerFailure('Failed to update question'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(int id) async {
    try {
      _logger.d('Deleting question: $id');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/delete_question.php',
        queryParameters: {'question_id': id, 'user_id': userId ?? '1'},
      );

      if (response.statusCode == 200) {
        _logger.d('Question deleted successfully');
        return Either.right(null);
      } else {
        return Either.left(ServerFailure('Failed to delete question'));
      }
    } catch (e) {
      _logger.e('Error deleting question', error: e);
      return Either.left(ServerFailure('Failed to delete question'));
    }
  }

  @override
  Future<Either<Failure, Question>> upvoteQuestion(int questionId) async {
    return voteQuestion(
      VoteQuestionParams(questionId: questionId, voteType: VoteType.upvote),
    );
  }

  @override
  Future<Either<Failure, Question>> downvoteQuestion(int questionId) async {
    return voteQuestion(
      VoteQuestionParams(questionId: questionId, voteType: VoteType.downvote),
    );
  }

  @override
  Future<Either<Failure, Question>> bookmarkQuestion(int questionId) async {
    try {
      _logger.d('Bookmarking question: $questionId');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.post(
        '$_baseUrl/bookmark_question.php',
        data: {'question_id': questionId, 'user_id': userId ?? '1'},
      );

      if (response.statusCode == 200) {
        final question = Question.fromJson(response.data['data']);
        _logger.d('Question bookmarked successfully');
        return Either.right(question);
      } else {
        return Either.left(ServerFailure('Failed to bookmark question'));
      }
    } catch (e) {
      _logger.e('Error bookmarking question', error: e);
      return Either.left(ServerFailure('Failed to bookmark question'));
    }
  }

  @override
  Future<Either<Failure, Question>> removeBookmark(int id) async {
    try {
      _logger.d('Removing bookmark for question: $id');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.post(
        '$_baseUrl/remove_bookmark.php',
        data: {'question_id': id, 'user_id': userId ?? '1'},
      );

      if (response.statusCode == 200) {
        final question = Question.fromJson(response.data['data']);
        _logger.d('Bookmark removed successfully');
        return Either.right(question);
      } else {
        return Either.left(ServerFailure('Failed to remove bookmark'));
      }
    } catch (e) {
      _logger.e('Error removing bookmark', error: e);
      return Either.left(ServerFailure('Failed to remove bookmark'));
    }
  }

  @override
  Future<Either<Failure, List<Answer>>> getAnswers(
    GetAnswersParams params,
  ) async {
    try {
      _logger.d('Getting answers for question: ${params.questionId}');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_answers.php',
        queryParameters: {
          'question_id': params.questionId,
          'page': params.page,
          'limit': params.limit,
          'viewer_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> answersJson =
            (data is Map && data.containsKey('answers'))
            ? data['answers']
            : (data is List ? data : []);

        final answers = answersJson
            .map((json) => Answer.fromJson(json))
            .toList();
        _logger.d('Retrieved ${answers.length} answers');
        return Either.right(answers);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Failed to get answers'),
        );
      }
    } catch (e) {
      _logger.e('Error getting answers', error: e);
      return Either.left(ServerFailure('Failed to get answers'));
    }
  }

  @override
  Future<Either<Failure, Answer>> createAnswer(
    CreateAnswerParams params,
  ) async {
    try {
      _logger.d('Creating answer for question: ${params.questionId}');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.post(
        '$_baseUrl/create_answer.php',
        data: {
          'question_id': params.questionId,
          'content': params.content,
          'user_id': userId,
        },
      );

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data['success'] == true) {
        final answer = Answer.fromJson(response.data['data']);
        _logger.d('Answer created successfully');
        return Either.right(answer);
      } else {
        return Either.left(
          ServerFailure(response.data['message'] ?? 'Failed to create answer'),
        );
      }
    } catch (e) {
      _logger.e('Error creating answer', error: e);
      return Either.left(ServerFailure('Failed to create answer'));
    }
  }

  @override
  Future<Either<Failure, Answer>> voteAnswer(VoteAnswerParams params) async {
    try {
      _logger.d('Voting on answer: ${params.answerId}');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.post(
        '$_baseUrl/vote_answer.php',
        data: {
          'answer_id': params.answerId,
          'user_id': userId ?? '1',
          'vote_type': params.voteType == VoteType.upvote ? 'up' : 'down',
        },
      );

      if (response.statusCode == 200) {
        final answer = Answer.fromJson(response.data['data']);
        _logger.d('Vote cast successfully');
        return Either.right(answer);
      } else {
        return Either.left(ServerFailure('Failed to vote on answer'));
      }
    } catch (e) {
      _logger.e('Error voting on answer', error: e);
      return Either.left(ServerFailure('Failed to vote on answer'));
    }
  }

  @override
  Future<Either<Failure, Question>> voteQuestion(
    VoteQuestionParams params,
  ) async {
    try {
      _logger.d('Voting on question: ${params.questionId}');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.post(
        '$_baseUrl/vote_question.php',
        data: {
          'question_id': params.questionId,
          'user_id': userId ?? '1',
          'vote_type': params.voteType == VoteType.upvote ? 'up' : 'down',
        },
      );

      if (response.statusCode == 200) {
        final question = Question.fromJson(response.data['data']);
        _logger.d('Vote cast successfully');
        return Either.right(question);
      } else {
        return Either.left(ServerFailure('Failed to vote on question'));
      }
    } catch (e) {
      _logger.e('Error voting on question', error: e);
      return Either.left(ServerFailure('Failed to vote on question'));
    }
  }

  @override
  Future<Either<Failure, void>> markBestAnswer(
    MarkBestAnswerParams params,
  ) async {
    try {
      _logger.d('Marking answer as best: ${params.answerId}');

      final response = await _dioClient.post(
        '$_baseUrl/mark_best_answer.php',
        data: {'answer_id': params.answerId, 'question_id': params.questionId},
      );

      if (response.statusCode == 200) {
        _logger.d('Answer marked as best');
        return Either.right(null);
      } else {
        return Either.left(ServerFailure('Failed to mark best answer'));
      }
    } catch (e) {
      _logger.e('Error marking best answer', error: e);
      return Either.left(ServerFailure('Failed to mark best answer'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> searchQuestions(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.d('Searching questions with query: $query');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/search_questions.php',
        queryParameters: {
          'query': query,
          'page': page,
          'limit': limit,
          'viewer_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();
        _logger.d('Found ${questions.length} questions');
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to search questions',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error searching questions', error: e);
      return Either.left(ServerFailure('Failed to search questions'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.d('Getting questions by subject: $subject');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_questions_by_subject.php',
        queryParameters: {
          'subject': subject,
          'page': page,
          'limit': limit,
          'viewer_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();
        _logger.d(
          'Retrieved ${questions.length} questions for subject $subject',
        );
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to get questions by subject',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error getting questions by subject', error: e);
      return Either.left(ServerFailure('Failed to get questions by subject'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByUser(
    int userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.d('Getting questions for user: $userId');
      final currentUserId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/get_questions_by_user.php',
        queryParameters: {
          'user_id': userId,
          'page': page,
          'limit': limit,
          'viewer_id': currentUserId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();
        _logger.d('Retrieved ${questions.length} questions for user $userId');
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to get questions by user',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error getting questions by user', error: e);
      return Either.left(ServerFailure('Failed to get questions by user'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getFeaturedQuestions({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      _logger.d('Getting featured questions');
      final userId = await _secureStorage.getUserId();

      final response = await _dioClient.get(
        '$_baseUrl/featured_questions.php',
        queryParameters: {'page': page, 'limit': limit, 'viewer_id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic data = response.data['data'];
        final List<dynamic> questionsJson =
            (data is Map && data.containsKey('questions'))
            ? data['questions']
            : (data is List ? data : []);

        final questions = questionsJson
            .map((json) => Question.fromJson(json))
            .toList();
        _logger.d('Retrieved ${questions.length} featured questions');
        return Either.right(questions);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to get featured questions',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error getting featured questions', error: e);
      return Either.left(ServerFailure('Failed to get featured questions'));
    }
  }

  @override
  Future<Either<Failure, void>> reportQuestion({
    required int questionId,
    required int reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      _logger.d('Reporting question: $questionId');

      final response = await _dioClient.post(
        '$_baseUrl/report_question.php',
        data: {
          'question_id': questionId,
          'reporter_id': reporterId,
          'reason': reason,
          'description': description,
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Report submitted successfully');
        return Either.right(null);
      } else {
        return Either.left(ServerFailure('Failed to submit report'));
      }
    } catch (e) {
      _logger.e('Error reporting question', error: e);
      return Either.left(ServerFailure('Failed to submit report'));
    }
  }
}
