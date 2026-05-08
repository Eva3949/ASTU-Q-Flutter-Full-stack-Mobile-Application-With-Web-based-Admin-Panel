/// App Routes
/// Centralized route definitions for navigation
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Route names
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main navigation
  static const String home = '/home';
  static const String questions = '/questions';
  static const String answers = '/answers';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String leaderboard = '/leaderboard';
  static const String myQuestions = '/my-questions';

  // Question routes
  static const String questionDetail = '/questions/:id';
  static const String askQuestion = '/questions/ask';
  static const String editQuestion = '/questions/:id/edit';

  // Answer routes
  static const String answerDetail = '/answers/:id';
  static const String editAnswer = '/answers/:id/edit';

  // Chat routes
  static const String chatRoom = '/chat/room/:id';
  static const String chatRoomList = '/chat/rooms';
  static const String newChat = '/chat/new';

  // User routes
  static const String userProfile = '/users/:id';
  static const String userQuestions = '/users/:id/questions';
  static const String userAnswers = '/users/:id/answers';
  static const String userFollowers = '/users/:id/followers';
  static const String userFollowing = '/users/:id/following';

  // Search routes
  static const String search = '/search';
  static const String searchResults = '/search/results';

  // Settings routes
  static const String accountSettings = '/settings/account';
  static const String privacySettings = '/settings/privacy';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  static const String securitySettings = '/settings/security';
  static const String aboutSettings = '/settings/about';

  // Analytics routes
  static const String analytics = '/analytics';
  static const String analyticsOverview = '/analytics/overview';
  static const String analyticsActivity = '/analytics/activity';
  static const String analyticsUsers = '/analytics/users';
  static const String analyticsPerformance = '/analytics/performance';

  // Image upload routes
  static const String imageUpload = '/upload/image';
  static const String imagePreview = '/upload/image/preview';

  // Error routes
  static const String notFound = '/404';
  static const String serverError = '/500';
  static const String networkError = '/network-error';
}

/// Route Arguments
class RouteArguments {
  // Prevent instantiation
  RouteArguments._();

  // Common argument keys
  static const String questionId = 'questionId';
  static const String answerId = 'answerId';
  static const String userId = 'userId';
  static const String roomId = 'roomId';
  static const String searchQuery = 'searchQuery';
  static const String imageUrl = 'imageUrl';
  static const String errorMessage = 'errorMessage';
  static const String returnRoute = 'returnRoute';
}
