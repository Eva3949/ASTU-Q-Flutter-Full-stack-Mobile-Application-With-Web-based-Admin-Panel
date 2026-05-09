import '../../../../core/network/dio_client.dart';

/// Question Remote Data Source
/// Handles remote API calls for question-related operations
class QuestionRemoteDataSource {
  final DioClient _dioClient;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  QuestionRemoteDataSource(this._dioClient);

  /// Get questions from API
  Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int limit = 20,
    String? subject,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

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

    return response.data;
  }

  /// Get single question by ID
  Future<Map<String, dynamic>> getQuestionById(int id) async {
    final response = await _dioClient.get(
      '$_baseUrl/get_question.php',
      queryParameters: {'question_id': id},
    );

    return response.data;
  }

  /// Create new question
  Future<Map<String, dynamic>> createQuestion(
    Map<String, dynamic> questionData,
  ) async {
    final response = await _dioClient.post(
      '$_baseUrl/create_question.php',
      data: questionData,
    );

    return response.data;
  }

  /// Update question
  Future<Map<String, dynamic>> updateQuestion(
    int id,
    Map<String, dynamic> questionData,
  ) async {
    // Add question_id to the data if not present
    questionData['question_id'] = id;
    final response = await _dioClient.post(
      '$_baseUrl/update_question.php',
      data: questionData,
    );

    return response.data;
  }

  /// Delete question
  Future<Map<String, dynamic>> deleteQuestion(int id, int userId) async {
    final response = await _dioClient.get(
      '$_baseUrl/delete_question.php',
      queryParameters: {'question_id': id, 'user_id': userId},
    );

    return response.data;
  }

  /// Vote on question
  Future<Map<String, dynamic>> voteQuestion(
    int id,
    int userId,
    String voteType,
  ) async {
    final response = await _dioClient.post(
      '$_baseUrl/vote_question.php',
      data: {'question_id': id, 'user_id': userId, 'vote_type': voteType},
    );

    return response.data;
  }

  /// Search questions
  Future<Map<String, dynamic>> searchQuestions(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_baseUrl/search_questions.php',
      queryParameters: {'query': query, 'page': page, 'limit': limit},
    );

    return response.data;
  }

  /// Get questions by subject
  Future<Map<String, dynamic>> getQuestionsBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_baseUrl/get_questions_by_subject.php',
      queryParameters: {'subject': subject, 'page': page, 'limit': limit},
    );

    return response.data;
  }

  /// Get questions by user
  Future<Map<String, dynamic>> getQuestionsByUser(
    int userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_baseUrl/get_questions_by_user.php',
      queryParameters: {'user_id': userId, 'page': page, 'limit': limit},
    );

    return response.data;
  }

  /// Get featured questions
  Future<Map<String, dynamic>> getFeaturedQuestions({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dioClient.get(
      '$_baseUrl/featured_questions.php',
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data;
  }

  /// Report question
  Future<Map<String, dynamic>> reportQuestion(
    int id,
    int reporterId,
    String reason,
    String? description,
  ) async {
    final response = await _dioClient.post(
      '$_baseUrl/report_question.php',
      data: {
        'question_id': id,
        'reporter_id': reporterId,
        'reason': reason,
        'description': description,
      },
    );

    return response.data;
  }

  /// Bookmark question
  Future<Map<String, dynamic>> bookmarkQuestion(int id, int userId) async {
    final response = await _dioClient.post(
      '$_baseUrl/bookmark_question.php',
      data: {'question_id': id, 'user_id': userId},
    );

    return response.data;
  }

  /// Remove bookmark
  Future<Map<String, dynamic>> removeBookmark(int id, int userId) async {
    final response = await _dioClient.post(
      '$_baseUrl/remove_bookmark.php',
      data: {'question_id': id, 'user_id': userId},
    );

    return response.data;
  }

  /// Get answers for a question
  Future<Map<String, dynamic>> getAnswers(
    int questionId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.get(
      '$_baseUrl/get_answers.php',
      queryParameters: {
        'question_id': questionId,
        'page': page,
        'limit': limit,
      },
    );

    return response.data;
  }

  /// Create answer
  Future<Map<String, dynamic>> createAnswer(
    Map<String, dynamic> answerData,
  ) async {
    final response = await _dioClient.post(
      '$_baseUrl/create_answer.php',
      data: answerData,
    );

    return response.data;
  }

  /// Vote on answer
  Future<Map<String, dynamic>> voteAnswer(
    int id,
    int userId,
    String voteType,
  ) async {
    final response = await _dioClient.post(
      '$_baseUrl/vote_answer.php',
      data: {'answer_id': id, 'user_id': userId, 'vote_type': voteType},
    );

    return response.data;
  }

  /// Mark answer as best
  Future<Map<String, dynamic>> markBestAnswer(int id, int questionId) async {
    final response = await _dioClient.post(
      '$_baseUrl/mark_best_answer.php',
      data: {'answer_id': id, 'question_id': questionId},
    );

    return response.data;
  }

  /// Upload image
  Future<Map<String, dynamic>> uploadImage(
    dynamic image, {
    String? type,
  }) async {
    final response = await _dioClient.upload(
      '$_baseUrl/upload_image.php',
      image,
      data: {'type': type ?? 'question_image'},
    );

    return response.data;
  }
}
