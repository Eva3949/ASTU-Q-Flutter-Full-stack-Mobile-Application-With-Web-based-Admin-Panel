/// API Constants for ASTU-Q App
/// Contains all API endpoints and base URLs
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://your-api-domain.com/api';
  static const String baseUrlDev = 'https://evadevstudio.com/sami';
  static const String baseUrlStaging = 'https://staging-api-domain.com/api';

  // API Endpoints
  static const String auth = '/auth';
  static const String login = '/login.php';
  static const String register = '/signup.php';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';

  // User endpoints
  static const String users = '/users';
  static const String userProfile = '/users/profile';
  static const String updateUser = '/users/update';
  static const String uploadAvatar = '/users/upload-avatar';
  static const String changePassword = '/users/change-password';
  static const String deleteAccount = '/users/delete';

  // Question endpoints
  static const String questions = '/questions';
  static const String createQuestion = '/questions';
  static const String updateQuestion = '/questions';
  static const String deleteQuestion = '/questions';
  static const String getQuestion = '/questions';
  static const String searchQuestions = '/questions';
  static const String getQuestionsBySubject = '/questions';
  static const String getQuestionsByUser = '/questions/user';
  static const String featuredQuestions = '/questions';
  static const String reportQuestion = '/questions';
  static const String voteQuestion = '/questions';

  // Answer endpoints
  static const String answers = '/answers';
  static const String createAnswer = '/answers';
  static const String updateAnswer = '/answers';
  static const String deleteAnswer = '/answers';
  static const String voteAnswer = '/answers/vote';
  static const String markBestAnswer = '/answers/best';
  static const String getAnswersByQuestion = '/answers/question';

  // Subject endpoints
  static const String subjects = '/subjects';
  static const String getSubjects = '/subjects/list';
  static const String getSubjectCategories = '/subjects/categories';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String getNotifications = '/notifications/list';
  static const String markNotificationRead = '/notifications/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String deleteNotification = '/notifications/delete';

  // Report endpoints
  static const String reports = '/reports';
  static const String createReport = '/reports/create';
  static const String getReports = '/reports/list';
  static const String updateReport = '/reports/update';

  // Analytics endpoints
  static const String analytics = '/analytics';
  static const String getUserStats = '/analytics/user-stats';
  static const String getQuestionStats = '/analytics/question-stats';
  static const String getPopularSubjects = '/analytics/popular-subjects';

  // File upload endpoints
  static const String uploadFile = '/upload/file';
  static const String uploadImage = '/upload/image';
  static const String uploadDocument = '/upload/document';

  // WebSocket endpoints
  static const String websocketUrl = 'wss://your-api-domain.com/ws';
  static const String websocketUrlDev = 'ws://localhost';

  // API Keys (should be stored securely)
  static const String apiKey = 'your-api-key';
  static const String appVersion = '1.0.0';

  // Request timeouts (in milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Retry settings
  static const int maxRetries = 3;
  static const int retryDelay = 1000;

  // Cache settings
  static const int cacheMaxAge = 300; // 5 minutes
  static const int cacheMaxSize = 100; // Maximum cached items

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File upload limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ];

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxUploadsPerHour = 10;

  // Error codes
  static const String errorNetwork = 'NETWORK_ERROR';
  static const String errorTimeout = 'TIMEOUT_ERROR';
  static const String errorUnauthorized = 'UNAUTHORIZED';
  static const String errorForbidden = 'FORBIDDEN';
  static const String errorNotFound = 'NOT_FOUND';
  static const String errorServerError = 'SERVER_ERROR';
  static const String errorValidation = 'VALIDATION_ERROR';
  static const String errorFileTooLarge = 'FILE_TOO_LARGE';
  static const String errorUnsupportedFileType = 'UNSUPPORTED_FILE_TYPE';

  // HTTP Headers
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String accept = 'Accept';
  static const String userAgent = 'User-Agent';
  static const String apiKeyHeader = 'X-API-Key';
  static const String appVersionHeader = 'X-App-Version';

  // Content Types
  static const String json = 'application/json';
  static const String formData = 'multipart/form-data';
  static const String urlEncoded = 'application/x-www-form-urlencoded';

  // Cache keys
  static const String userCacheKey = 'user_profile';
  static const String subjectsCacheKey = 'subjects_list';
  static const String notificationsCacheKey = 'notifications_list';

  // Environment detection
  static bool get isDebugMode => !bool.fromEnvironment('dart.vm.product');
  static String get currentBaseUrl =>
      isDebugMode ? baseUrlDev : ApiConstants.baseUrl;
  static String get currentWebsocketUrl =>
      isDebugMode ? websocketUrlDev : ApiConstants.websocketUrl;
}
