import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';
import '../errors/failures.dart';
import '../constants/api_constants.dart';

/// API Service Class
/// Handles all HTTP requests with authentication, error handling, and token management
@singleton
class ApiService {
  final Dio _dio;
  final SecureStorage _secureStorage;
  final Logger _logger;

  static const String _baseUrl = 'https://evadevstudio.com/sami';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  ApiService(this._dio, this._secureStorage, this._logger) {
    _initializeDio();
  }

  /// Initialize Dio with default configuration
  void _initializeDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add request interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthToken(options);
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          await _handleError(error, handler);
        },
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        options: const RetryOptions(
          retries: _maxRetries,
          retryInterval: Duration(seconds: 1),
        ),
      ),
    );
  }

  /// Add authentication token to request headers
  Future<void> _addAuthToken(RequestOptions options) async {
    try {
      final token = await _secureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _logger.e('Error adding auth token', error: e);
    }
  }

  /// Log request details
  void _logRequest(RequestOptions options) {
    _logger.d('API Request: ${options.method} ${options.path}');
    _logger.d('Headers: ${options.headers}');
    if (options.data != null) {
      _logger.d('Request Data: ${options.data}');
    }
  }

  /// Log response details
  void _logResponse(Response response) {
    _logger.d(
      'API Response: ${response.statusCode} ${response.requestOptions.path}',
    );
    _logger.d('Response Data: ${response.data}');
  }

  /// Handle API errors
  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('API Error: ${error.message}', error: error);

    // Handle 401 Unauthorized - token refresh
    if (error.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request with new token
        try {
          final response = await _dio.fetch(error.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          _logger.e('Retry failed after token refresh', error: e);
        }
      }

      // Clear token and redirect to login
      await _secureStorage.clearToken();
      handler.next(error);
      return;
    }

    // Handle other errors
    handler.next(error);
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        await _secureStorage.saveToken(newToken);
        if (newRefreshToken != null) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }

        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
    }

    return false;
  }

  /// Generic GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generic POST request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generic PUT request
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generic DELETE request
  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generic upload request
  Future<Response> upload(
    String endpoint,
    File file, {
    Map<String, dynamic>? data,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        if (data != null) ...data,
      });

      return await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: options ?? Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generic PATCH request
  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// File upload with progress tracking
  Future<Response> uploadFile(
    String endpoint,
    File file, {
    String? fileName,
    Map<String, dynamic>? additionalFields,
    ProgressCallback? onProgress,
  }) async {
    try {
      final uploadOptions = Options(contentType: 'multipart/form-data');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName ?? file.path.split('/').last,
        ),
        ...?additionalFields,
      });

      return await _dio.post(
        endpoint,
        data: formData,
        options: uploadOptions,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Multiple files upload
  Future<Response> uploadMultipleFiles(
    String endpoint,
    List<File> files, {
    List<String>? fileNames,
    Map<String, dynamic>? additionalFields,
    ProgressCallback? onProgress,
  }) async {
    try {
      final uploadOptions = Options(contentType: 'multipart/form-data');

      final Map<String, dynamic> formData = {};

      // Add files
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = fileNames?[i] ?? file.path.split('/').last;

        formData['files[$i]'] = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );
      }

      // Add additional fields
      if (additionalFields != null) {
        formData.addAll(additionalFields);
      }

      return await _dio.post(
        endpoint,
        data: FormData.fromMap(formData),
        options: uploadOptions,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Download file
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Map DioException to custom Failure
  Failure _mapDioExceptionToFailure(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          'Request timeout. Please check your connection and try again.',
        );

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final message = exception.response?.data?['message'] ?? 'Unknown error';

        switch (statusCode) {
          case 400:
            return ValidationFailure(message);
          case 401:
            return UnauthorizedFailure(
              'Authentication failed. Please login again.',
            );
          case 403:
            return UnauthorizedFailure(
              'You don\'t have permission to perform this action.',
            );
          case 404:
            return NotFoundFailure('The requested resource was not found.');
          case 422:
            return ValidationFailure(message);
          case 429:
            return ServerFailure('Too many requests. Please try again later.');
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerFailure('Server error. Please try again later.');
          default:
            return ServerFailure('HTTP Error $statusCode: $message');
        }

      case DioExceptionType.cancel:
        return ServerFailure('Request was cancelled.');

      case DioExceptionType.unknown:
        if (exception.error is SocketException) {
          return NetworkFailure(
            'No internet connection. Please check your network and try again.',
          );
        }
        return ServerFailure('Network error: ${exception.message}');

      default:
        return ServerFailure(
          'An unexpected error occurred: ${exception.message}',
        );
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  /// User login
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await post(
      '$_baseUrl/login.php',
      data: {'email': email, 'password': password},
    );
  }

  /// User registration
  Future<Response> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    return await post(
      '$_baseUrl/signup.php',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
        if (phone != null) 'phone': phone,
      },
    );
  }

  /// Refresh token
  Future<Response> refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    return await post(
      '$_baseUrl/refresh_token.php',
      data: {'refresh_token': refreshToken},
    );
  }

  /// Logout
  Future<Response> logout() async {
    return await post('$_baseUrl/logout.php');
  }

  /// Get current user profile
  Future<Response> getCurrentUser() async {
    return await get('$_baseUrl/get_profile.php');
  }

  /// Update user profile
  Future<Response> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) async {
    return await post(
      '$_baseUrl/update_profile.php',
      data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
      },
    );
  }

  /// Update user points
  Future<Response> updateUserPoints({
    required int userId,
    required int points,
    required String action, // 'question', 'answer', 'best_answer', 'upvote'
  }) async {
    return await post(
      '$_baseUrl/update_points.php',
      data: {'user_id': userId, 'points': points, 'action': action},
    );
  }

  /// Change password
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await post(
      '$_baseUrl/change_password.php',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
  }

  // ==================== SUBJECT ENDPOINTS ====================

  /// Get all available subjects
  Future<Response> getSubjects() async {
    return await get('$_baseUrl/get_subjects.php');
  }

  /// Get categories for a specific subject
  Future<Response> getSubjectCategories(String subject) async {
    return await get(
      '$_baseUrl/get_subject_categories.php',
      queryParameters: {'subject': subject},
    );
  }

  // ==================== QUESTION ENDPOINTS ====================

  /// Get questions with pagination
  Future<Response> getQuestions({
    int page = 1,
    int limit = 20,
    String? search,
    String? subject,
    String? sortBy,
    String? sortOrder,
  }) async {
    return await get(
      '$_baseUrl/get_questions.php',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (subject != null) 'subject': subject,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
  }

  /// Get question by ID
  Future<Response> getQuestionById(int questionId) async {
    return await get(
      '$_baseUrl/get_question.php',
      queryParameters: {'question_id': questionId},
    );
  }

  /// Create new question
  Future<Response> createQuestion({
    required String title,
    required String content,
    required String subject,
    List<String>? tags,
  }) async {
    return await post(
      '$_baseUrl/create_question.php',
      data: {
        'title': title,
        'content': content,
        'subject': subject,
        if (tags != null) 'tags': tags,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Update question
  Future<Response> updateQuestion(
    int questionId, {
    String? title,
    String? content,
    String? subject,
    List<String>? tags,
  }) async {
    return await post(
      '$_baseUrl/update_question.php',
      data: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (subject != null) 'subject': subject,
        if (tags != null) 'tags': tags,
      },
    );
  }

  /// Delete question
  Future<Response> deleteQuestion(int questionId) async {
    return await get(
      '$_baseUrl/delete_question.php',
      queryParameters: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Get user's questions
  Future<Response> getUserQuestions({int page = 1, int limit = 20}) async {
    return await get(
      '$_baseUrl/get_questions_by_user.php',
      queryParameters: {
        'page': page,
        'limit': limit,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Upvote question
  Future<Response> upvoteQuestion(int questionId) async {
    return await post(
      '$_baseUrl/vote_question.php',
      data: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
        'vote_type': 'up',
      },
    );
  }

  /// Downvote question
  Future<Response> downvoteQuestion(int questionId) async {
    return await post(
      '$_baseUrl/vote_question.php',
      data: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
        'vote_type': 'down',
      },
    );
  }

  /// Bookmark question
  Future<Response> bookmarkQuestion(int questionId) async {
    return await post(
      '$_baseUrl/bookmark_question.php',
      data: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Remove bookmark from question
  Future<Response> removeBookmarkQuestion(int questionId) async {
    return await post(
      '$_baseUrl/remove_bookmark.php',
      data: {
        'question_id': questionId,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Get bookmarked questions
  Future<Response> getBookmarkedQuestions({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '$_baseUrl/get_bookmarks.php',
      queryParameters: {
        'page': page,
        'limit': limit,
        'user_id': 1, // Placeholder
      },
    );
  }

  // ==================== ANSWER ENDPOINTS ====================

  /// Get answers for a question
  Future<Response> getAnswers(
    int questionId, {
    int page = 1,
    int limit = 20,
    String? sortBy,
  }) async {
    return await get(
      '$_baseUrl/get_answers.php',
      queryParameters: {
        'question_id': questionId,
        'page': page,
        'limit': limit,
        if (sortBy != null) 'sort_by': sortBy,
        'viewer_id': 1, // Placeholder
      },
    );
  }

  /// Create answer
  Future<Response> createAnswer({
    required int questionId,
    required String content,
  }) async {
    return await post(
      '$_baseUrl/create_answer.php',
      data: {
        'question_id': questionId,
        'content': content,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Update answer
  Future<Response> updateAnswer(int answerId, {required String content}) async {
    return await post(
      '$_baseUrl/update_answer.php',
      data: {
        'answer_id': answerId,
        'content': content,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Delete answer
  Future<Response> deleteAnswer(int answerId) async {
    return await get(
      '$_baseUrl/delete_answer.php',
      queryParameters: {
        'answer_id': answerId,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Accept answer (Mark as best)
  Future<Response> acceptAnswer(int answerId, int questionId) async {
    return await post(
      '$_baseUrl/mark_best_answer.php',
      data: {'answer_id': answerId, 'question_id': questionId},
    );
  }

  /// Upvote answer
  Future<Response> upvoteAnswer(int answerId) async {
    return await post(
      '$_baseUrl/vote_answer.php',
      data: {
        'answer_id': answerId,
        'user_id': 1, // Placeholder
        'vote_type': 'up',
      },
    );
  }

  /// Downvote answer
  Future<Response> downvoteAnswer(int answerId) async {
    return await post(
      '$_baseUrl/vote_answer.php',
      data: {
        'answer_id': answerId,
        'user_id': 1, // Placeholder
        'vote_type': 'down',
      },
    );
  }

  /// Get user's answers
  Future<Response> getUserAnswers({int page = 1, int limit = 20}) async {
    return await get(
      '$_baseUrl/get_answers_by_user.php',
      queryParameters: {
        'page': page,
        'limit': limit,
        'user_id': 1, // Placeholder
      },
    );
  }

  // ==================== CHAT ENDPOINTS ====================

  /// Get chat rooms
  Future<Response> getChatRooms({int page = 1, int limit = 20}) async {
    return await get(
      '/chat/rooms',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Get chat room by ID
  Future<Response> getChatRoomById(int roomId) async {
    return await get('/chat/rooms/$roomId');
  }

  /// Create chat room
  Future<Response> createChatRoom({
    required String name,
    required String type, // 'private', 'group', 'public'
    List<int>? participantIds,
    String? description,
  }) async {
    return await post(
      '/chat/rooms',
      data: {
        'name': name,
        'type': type,
        if (participantIds != null) 'participant_ids': participantIds,
        if (description != null) 'description': description,
      },
    );
  }

  /// Join chat room
  Future<Response> joinChatRoom(int roomId) async {
    return await post('/chat/rooms/$roomId/join');
  }

  /// Leave chat room
  Future<Response> leaveChatRoom(int roomId) async {
    return await post('/chat/rooms/$roomId/leave');
  }

  /// Get chat messages
  Future<Response> getChatMessages(
    int roomId, {
    int page = 1,
    int limit = 50,
    String? before,
  }) async {
    return await get(
      '/chat/rooms/$roomId/messages',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (before != null) 'before': before,
      },
    );
  }

  /// Send chat message
  Future<Response> sendChatMessage({
    required int roomId,
    required String content,
    String? type = 'text', // 'text', 'image', 'file'
    File? attachment,
  }) async {
    if (attachment != null) {
      return await uploadFile(
        '/chat/rooms/$roomId/messages',
        attachment,
        additionalFields: {'content': content, 'type': type ?? 'text'},
      );
    } else {
      return await post(
        '/chat/rooms/$roomId/messages',
        data: {'content': content, 'type': type ?? 'text'},
      );
    }
  }

  /// Mark messages as read
  Future<Response> markMessagesAsRead(int roomId, {int? messageId}) async {
    return await post(
      '/chat/rooms/$roomId/read',
      data: {if (messageId != null) 'message_id': messageId},
    );
  }

  /// Get unread message count
  Future<Response> getUnreadMessageCount() async {
    return await get('/chat/unread-count');
  }

  /// Delete chat message
  Future<Response> deleteChatMessage(int messageId) async {
    return await delete('/chat/messages/$messageId');
  }

  /// Edit chat message
  Future<Response> editChatMessage(
    int messageId, {
    required String content,
  }) async {
    return await put('/chat/messages/$messageId', data: {'content': content});
  }

  // ==================== REPORT ENDPOINTS ====================

  /// Create a new report
  Future<Response> createReport({
    required String type, // 'question', 'answer', 'user'
    required int itemId,
    required String reason,
    String? description,
  }) async {
    return await post(
      '$_baseUrl/create_report.php',
      data: {
        'reported_item_type': type,
        'reported_item_id': itemId,
        'reporter_id': 1, // Placeholder
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
  }

  /// Get reports (Admin only)
  Future<Response> getReports({int page = 1, int limit = 20}) async {
    return await get(
      '$_baseUrl/get_reports.php',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Update report status (Admin only)
  Future<Response> updateReport({
    required int reportId,
    required String status, // 'reviewed', 'resolved', 'dismissed'
    String? notes,
  }) async {
    return await post(
      '$_baseUrl/update_report.php',
      data: {
        'report_id': reportId,
        'status': status,
        'admin_id': 1, // Placeholder
        if (notes != null) 'review_notes': notes,
      },
    );
  }

  // ==================== ANALYTICS ENDPOINTS ====================

  /// Get user statistics
  Future<Response> getUserStats(int userId) async {
    return await get(
      '$_baseUrl/get_user_stats.php',
      queryParameters: {'user_id': userId},
    );
  }

  /// Get general question statistics
  Future<Response> getQuestionStats() async {
    return await get('$_baseUrl/get_question_stats.php');
  }

  /// Get popular subjects
  Future<Response> getPopularSubjects() async {
    return await get('$_baseUrl/get_popular_subjects.php');
  }

  // ==================== FILE UPLOAD ENDPOINTS ====================

  /// Upload a generic file to the server
  Future<Response> uploadGenericFile(File file) async {
    return await upload('$_baseUrl/upload_file.php', file);
  }

  /// Upload an image to the server
  Future<Response> uploadImageFile(File file) async {
    return await upload('$_baseUrl/upload_image.php', file);
  }

  /// Upload a document to the server
  Future<Response> uploadDocumentFile(File file) async {
    return await upload('$_baseUrl/upload_document.php', file);
  }

  /// Get notifications
  Future<Response> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? unread,
  }) async {
    return await get(
      '$_baseUrl/get_notifications.php',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (unread != null) 'unread': unread,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Mark notification as read
  Future<Response> markNotificationAsRead(int notificationId) async {
    return await post(
      '$_baseUrl/mark_notification_read.php',
      data: {
        'notification_id': notificationId,
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Mark all notifications as read
  Future<Response> markAllNotificationsAsRead() async {
    return await post(
      '$_baseUrl/mark_all_notifications_read.php',
      data: {
        'user_id': 1, // Placeholder
      },
    );
  }

  /// Delete notification
  Future<Response> deleteNotification(int notificationId) async {
    return await get(
      '$_baseUrl/delete_notification.php',
      queryParameters: {
        'notification_id': notificationId,
        'user_id': 1, // Placeholder
      },
    );
  }

  // ==================== USER ENDPOINTS ====================

  /// Get user profile
  Future<Response> getUserProfile(int userId) async {
    return await get('/users/$userId');
  }

  /// Follow user
  Future<Response> followUser(int userId) async {
    return await post('/users/$userId/follow');
  }

  /// Unfollow user
  Future<Response> unfollowUser(int userId) async {
    return await delete('/users/$userId/follow');
  }

  /// Get user's followers
  Future<Response> getUserFollowers(
    int userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/users/$userId/followers',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Get user's following
  Future<Response> getUserFollowing(
    int userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      '/users/$userId/following',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  /// Report content
  Future<Response> reportContent({
    required String type, // 'question', 'answer', 'user', 'message'
    required int id,
    required String reason,
    String? description,
  }) async {
    return await post(
      '/reports',
      data: {
        'type': type,
        'id': id,
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
  }
}

/// Retry Interceptor for automatic retry on failures
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final RetryOptions options;

  RetryInterceptor({required this.dio, required this.options});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && retryCount < options.retries) {
      extra['retryCount'] = retryCount + 1;

      await Future.delayed(options.retryInterval);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Retry failed, continue with original error
        handler.next(err);
        return;
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && (statusCode >= 500 || statusCode == 429);
      default:
        return false;
    }
  }
}

/// Retry Options
class RetryOptions {
  final int retries;
  final Duration retryInterval;

  const RetryOptions({
    this.retries = 3,
    this.retryInterval = const Duration(seconds: 1),
  });
}
