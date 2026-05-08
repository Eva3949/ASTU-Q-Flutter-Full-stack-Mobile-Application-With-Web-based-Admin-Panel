import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../di/injection_container.dart';
import '../../features/questions/presentation/providers/question_detail_provider.dart';
import '../../features/questions/presentation/providers/ask_question_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/reset_password_screen.dart';
import '../../features/questions/presentation/screens/home_screen.dart';
import '../../features/questions/presentation/screens/question_detail_screen.dart';
import '../../features/questions/presentation/screens/ask_question_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/profile/presentation/screens/modern_profile_screen.dart';
import '../../features/profile/presentation/screens/my_questions_screen.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../features/image_upload/presentation/screens/image_upload_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../shared/screens/not_found_screen.dart';
import '../../shared/screens/error_screen.dart';
import '../../shared/screens/network_error_screen.dart';

/// App Router
/// Handles all navigation with named routes and route generation
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Generate route based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Splash and Onboarding
      case AppRoutes.splash:
        return _buildPageRoute(const SplashScreen(), settings: settings);

      case AppRoutes.onboarding:
        return _buildPageRoute(const OnboardingScreen(), settings: settings);

      // Authentication
      case AppRoutes.auth:
      case AppRoutes.login:
        return _buildPageRoute(const LoginScreen(), settings: settings);

      case AppRoutes.register:
        return _buildPageRoute(const RegisterScreen(), settings: settings);

      case AppRoutes.forgotPassword:
        return _buildPageRoute(
          const ForgotPasswordScreen(),
          settings: settings,
        );

      case AppRoutes.resetPassword:
        return _buildPageRoute(const ResetPasswordScreen(), settings: settings);

      // Main Navigation
      case AppRoutes.home:
        return _buildPageRoute(const MainScreen(), settings: settings);

      case AppRoutes.questions:
        return _buildPageRoute(const MainScreen(), settings: settings);

      case AppRoutes.leaderboard:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<LeaderboardProvider>(),
            child: const LeaderboardScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.chat:
        return _buildPageRoute(const ChatDetailScreen(), settings: settings);

      case AppRoutes.profile:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<ProfileProvider>(),
            child: const ModernProfileScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.notifications:
        return _buildPageRoute(const NotificationScreen(), settings: settings);

      case AppRoutes.myQuestions:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<ProfileProvider>(),
            child: const MyQuestionsScreen(),
          ),
          settings: settings,
        );

      // Question Routes
      case AppRoutes.questionDetail:
      case '/question-details': // Add alias for backward compatibility
        final dynamic rawArgs = settings.arguments;
        int qId = 0;

        if (rawArgs is Map<String, dynamic>) {
          qId = rawArgs[RouteArguments.questionId] ?? 0;
        } else if (rawArgs is int) {
          qId = rawArgs;
        }

        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<QuestionDetailProvider>(),
            child: QuestionDetailScreen(questionId: qId),
          ),
          settings: settings,
        );

      case AppRoutes.askQuestion:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<AskQuestionProvider>(),
            child: const AskQuestionScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.editQuestion:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<AskQuestionProvider>(),
            child: const AskQuestionScreen(),
          ),
          settings: settings,
        );

      // Answer Routes
      case AppRoutes.answerDetail:
        final dynamic rawArgs = settings.arguments;
        int qId = 0;

        if (rawArgs is Map<String, dynamic>) {
          qId =
              rawArgs[RouteArguments.questionId] ??
              rawArgs[RouteArguments.answerId] ??
              0;
        } else if (rawArgs is int) {
          qId = rawArgs;
        }

        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<QuestionDetailProvider>(),
            child: QuestionDetailScreen(questionId: qId),
          ),
          settings: settings,
        );

      case AppRoutes.editAnswer:
        return _buildPageRoute(
          ChangeNotifierProvider(
            create: (_) => sl<QuestionDetailProvider>(),
            child: QuestionDetailScreen(questionId: 0),
          ),
          settings: settings,
        );

      // Chat Routes
      case AppRoutes.chatRoom:
        return _buildPageRoute(const ChatDetailScreen(), settings: settings);

      case AppRoutes.chatRoomList:
        return _buildPageRoute(const ChatListScreen(), settings: settings);

      case AppRoutes.newChat:
        return _buildPageRoute(const ChatDetailScreen(), settings: settings);

      // User Routes
      case AppRoutes.userProfile:
        return _buildPageRoute(const ModernProfileScreen(), settings: settings);

      case AppRoutes.userQuestions:
      case AppRoutes.userAnswers:
      case AppRoutes.userFollowers:
      case AppRoutes.userFollowing:
        return _buildPageRoute(const ModernProfileScreen(), settings: settings);

      // Search Routes
      case AppRoutes.search:
        return _buildPageRoute(const HomeScreen(), settings: settings);

      case AppRoutes.searchResults:
        return _buildPageRoute(const HomeScreen(), settings: settings);

      // Settings Routes
      case AppRoutes.accountSettings:
      case AppRoutes.privacySettings:
      case AppRoutes.notificationSettings:
      case AppRoutes.appearanceSettings:
      case AppRoutes.securitySettings:
        return _buildPageRoute(const ModernProfileScreen(), settings: settings);

      case AppRoutes.aboutSettings:
        return _buildPageRoute(const ErrorScreen(), settings: settings);

      // Analytics Routes
      case AppRoutes.analytics:
        return _buildPageRoute(const AnalyticsScreen(), settings: settings);

      case AppRoutes.analyticsOverview:
      case AppRoutes.analyticsActivity:
      case AppRoutes.analyticsUsers:
      case AppRoutes.analyticsPerformance:
        return _buildPageRoute(const AnalyticsScreen(), settings: settings);

      // Image Upload Routes
      case AppRoutes.imageUpload:
        return _buildPageRoute(const ImageUploadScreen(), settings: settings);

      case AppRoutes.imagePreview:
        return _buildPageRoute(const ImageUploadScreen(), settings: settings);

      // Error Routes
      case AppRoutes.notFound:
        return _buildPageRoute(const NotFoundScreen(), settings: settings);

      case AppRoutes.serverError:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildPageRoute(
          ErrorScreen(errorMessage: args?[RouteArguments.errorMessage]),
          settings: settings,
        );

      case AppRoutes.networkError:
        return _buildPageRoute(const NetworkErrorScreen(), settings: settings);

      default:
        return _buildPageRoute(const NotFoundScreen(), settings: settings);
    }
  }

  /// Build page route with custom transition
  static PageRouteBuilder _buildPageRoute(
    Widget child, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration? transitionDuration,
  }) {
    return PageRouteBuilder(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      reverseTransitionDuration:
          transitionDuration ?? const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Build fade transition route
  static PageRouteBuilder _buildFadeRoute(
    Widget child, {
    RouteSettings? settings,
    Duration? transitionDuration,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 250),
      reverseTransitionDuration:
          transitionDuration ?? const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Build scale transition route
  static PageRouteBuilder _buildScaleRoute(
    Widget child, {
    RouteSettings? settings,
    Duration? transitionDuration,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 200),
      reverseTransitionDuration:
          transitionDuration ?? const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }
}

/// Navigation Service
/// Provides helper methods for navigation
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to named route
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final currentState = navigatorKey.currentState;
    if (currentState != null) {
      return currentState.pushNamed<T>(routeName, arguments: arguments);
    }
    return Future.value(null);
  }

  /// Navigate to named route and replace
  static Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
  }) {
    final currentState = navigatorKey.currentState;
    if (currentState != null) {
      return currentState.pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => false,
        arguments: arguments,
      );
    }
    return Future.value(null);
  }

  /// Navigate to named route and replace current
  static Future<T?> pushReplacementNamed<T>(
    String routeName, {
    Object? arguments,
  }) {
    final currentState = navigatorKey.currentState;
    if (currentState != null) {
      return currentState.pushReplacementNamed(routeName, arguments: arguments);
    }
    return Future.value(null);
  }

  /// Pop current route
  static void pop<T>([T? result]) {
    final currentState = navigatorKey.currentState;
    if (currentState != null && currentState.canPop()) {
      currentState.pop<T>(result);
    }
  }

  /// Pop until specific route
  static void popUntil(String routeName) {
    final currentState = navigatorKey.currentState;
    if (currentState != null) {
      currentState.popUntil(ModalRoute.withName(routeName));
    }
  }

  /// Check if can pop
  static bool canPop() {
    final currentState = navigatorKey.currentState;
    return currentState?.canPop() ?? false;
  }

  /// Navigate to question detail
  static Future<void> navigateToQuestionDetail(int questionId) {
    return pushNamed(
      AppRoutes.questionDetail,
      arguments: {RouteArguments.questionId: questionId},
    );
  }

  /// Navigate to ask question
  static Future<void> navigateToAskQuestion() {
    return pushNamed(AppRoutes.askQuestion);
  }

  /// Navigate to edit question
  static Future<void> navigateToEditQuestion(int questionId) {
    return pushNamed(
      AppRoutes.editQuestion,
      arguments: {RouteArguments.questionId: questionId},
    );
  }

  /// Navigate to answer detail
  static Future<void> navigateToAnswerDetail(int answerId) {
    return pushNamed(
      AppRoutes.answerDetail,
      arguments: {RouteArguments.answerId: answerId},
    );
  }

  /// Navigate to edit answer
  static Future<void> navigateToEditAnswer(int answerId) {
    return pushNamed(
      AppRoutes.editAnswer,
      arguments: {RouteArguments.answerId: answerId},
    );
  }

  /// Navigate to chat room
  static Future<void> navigateToChatRoom(int roomId) {
    return pushNamed(
      AppRoutes.chatRoom,
      arguments: {RouteArguments.roomId: roomId},
    );
  }

  /// Navigate to user profile
  static Future<void> navigateToUserProfile(int userId) {
    return pushNamed(
      AppRoutes.userProfile,
      arguments: {RouteArguments.userId: userId},
    );
  }

  /// Navigate to search results
  static Future<void> navigateToSearchResults(String query) {
    return pushNamed(
      AppRoutes.searchResults,
      arguments: {RouteArguments.searchQuery: query},
    );
  }

  /// Navigate to image preview
  static Future<void> navigateToImagePreview(String imageUrl) {
    return pushNamed(
      AppRoutes.imagePreview,
      arguments: {RouteArguments.imageUrl: imageUrl},
    );
  }

  /// Navigate to login
  static Future<void> navigateToLogin({String? returnRoute}) {
    return pushNamed(
      AppRoutes.login,
      arguments: returnRoute != null
          ? {RouteArguments.returnRoute: returnRoute}
          : null,
    );
  }

  /// Navigate to register
  static Future<void> navigateToRegister({String? returnRoute}) {
    return pushNamed(
      AppRoutes.register,
      arguments: returnRoute != null
          ? {RouteArguments.returnRoute: returnRoute}
          : null,
    );
  }

  /// Navigate to home and clear stack
  static Future<void> navigateToHomeAndClearStack() {
    return pushNamedAndRemoveUntil(AppRoutes.home);
  }

  /// Navigate to leaderboard
  static Future<void> navigateToLeaderboard() {
    return pushNamed(AppRoutes.leaderboard);
  }

  /// Navigate to error screen
  static Future<void> navigateToError(String? errorMessage) {
    return pushNamed(
      AppRoutes.serverError,
      arguments: errorMessage != null
          ? {RouteArguments.errorMessage: errorMessage}
          : null,
    );
  }

  /// Navigate to network error screen
  static Future<void> navigateToNetworkError() {
    return pushNamed(AppRoutes.networkError);
  }

  /// Navigate to not found screen
  static Future<void> navigateToNotFound() {
    return pushNamed(AppRoutes.notFound);
  }

  /// Navigate back with result
  static void popWithResult<T>(T result) {
    pop<T>(result);
  }

  /// Navigate to settings with specific tab
  static Future<void> navigateToSettingsTab(String tab) {
    switch (tab) {
      case 'account':
        return pushNamed(AppRoutes.accountSettings);
      case 'privacy':
        return pushNamed(AppRoutes.privacySettings);
      case 'notifications':
        return pushNamed(AppRoutes.notificationSettings);
      case 'appearance':
        return pushNamed(AppRoutes.appearanceSettings);
      case 'security':
        return pushNamed(AppRoutes.securitySettings);
      case 'about':
        return pushNamed(AppRoutes.aboutSettings);
      default:
        return pushNamed(AppRoutes.settings);
    }
  }

  /// Check if current route is specific route
  static bool isCurrentRoute(String routeName) {
    final currentContext = context;
    if (currentContext == null) return false;
    final currentRoute = ModalRoute.of(currentContext);
    return currentRoute?.settings.name == routeName;
  }

  /// Get current route name
  static String? getCurrentRouteName() {
    final currentContext = context;
    if (currentContext == null) return null;
    final currentRoute = ModalRoute.of(currentContext);
    return currentRoute?.settings.name;
  }

  /// Get route arguments
  static Object? getRouteArguments() {
    final currentContext = context;
    if (currentContext == null) return null;
    final currentRoute = ModalRoute.of(currentContext);
    return currentRoute?.settings.arguments;
  }

  /// Get specific route argument
  static T? getRouteArgument<T>(String key) {
    final arguments = getRouteArguments();
    if (arguments is Map<String, dynamic>) {
      return arguments[key] as T?;
    }
    return null;
  }
}

/// Route Guard
/// Protects routes that require authentication
class RouteGuard {
  static bool canAccessRoute(String routeName, {bool isAuthenticated = false}) {
    // Routes that don't require authentication
    final publicRoutes = [
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.resetPassword,
      AppRoutes.notFound,
      AppRoutes.serverError,
      AppRoutes.networkError,
    ];

    // Routes that require authentication
    final protectedRoutes = [
      AppRoutes.home,
      AppRoutes.questions,
      AppRoutes.answers,
      AppRoutes.chat,
      AppRoutes.profile,
      AppRoutes.notifications,
      AppRoutes.settings,
      AppRoutes.questionDetail,
      AppRoutes.askQuestion,
      AppRoutes.editQuestion,
      AppRoutes.answerDetail,
      AppRoutes.editAnswer,
      AppRoutes.chatRoom,
      AppRoutes.chatRoomList,
      AppRoutes.newChat,
      AppRoutes.userProfile,
      AppRoutes.userQuestions,
      AppRoutes.userAnswers,
      AppRoutes.userFollowers,
      AppRoutes.userFollowing,
      AppRoutes.search,
      AppRoutes.searchResults,
      AppRoutes.accountSettings,
      AppRoutes.privacySettings,
      AppRoutes.notificationSettings,
      AppRoutes.appearanceSettings,
      AppRoutes.securitySettings,
      AppRoutes.aboutSettings,
      AppRoutes.analytics,
      AppRoutes.analyticsOverview,
      AppRoutes.analyticsActivity,
      AppRoutes.analyticsUsers,
      AppRoutes.analyticsPerformance,
      AppRoutes.imageUpload,
      AppRoutes.imagePreview,
    ];

    if (publicRoutes.contains(routeName)) {
      return true; // Always accessible
    }

    if (protectedRoutes.contains(routeName)) {
      return isAuthenticated; // Require authentication
    }

    // For dynamic routes, check if they start with protected prefixes
    if (routeName.startsWith('/questions/') &&
        routeName != AppRoutes.questions) {
      return isAuthenticated;
    }
    if (routeName.startsWith('/answers/') && routeName != AppRoutes.answers) {
      return isAuthenticated;
    }
    if (routeName.startsWith('/users/') && routeName != AppRoutes.profile) {
      return isAuthenticated;
    }
    if (routeName.startsWith('/chat/') && routeName != AppRoutes.chat) {
      return isAuthenticated;
    }
    if (routeName.startsWith('/settings/') && routeName != AppRoutes.settings) {
      return isAuthenticated;
    }
    if (routeName.startsWith('/analytics/') &&
        routeName != AppRoutes.analytics) {
      return isAuthenticated;
    }

    return true; // Default to accessible
  }

  /// Get redirect route for unauthenticated users
  static String getRedirectRoute(String requestedRoute) {
    // Save the requested route to return after login
    return '${AppRoutes.login}?return_to=$requestedRoute';
  }
}

/// Deep Link Handler
/// Handles deep linking and app links
class DeepLinkHandler {
  static Future<bool> handleDeepLink(Uri uri) async {
    final path = uri.path;
    final queryParameters = uri.queryParameters;

    try {
      switch (path) {
        case '/questions':
          if (queryParameters.containsKey('id')) {
            final questionId = int.tryParse(queryParameters['id']!);
            if (questionId != null) {
              await NavigationService.navigateToQuestionDetail(questionId);
              return true;
            }
          }
          await NavigationService.pushNamed(AppRoutes.questions);
          return true;

        case '/answers':
          if (queryParameters.containsKey('id')) {
            final answerId = int.tryParse(queryParameters['id']!);
            if (answerId != null) {
              await NavigationService.navigateToAnswerDetail(answerId);
              return true;
            }
          }
          await NavigationService.pushNamed(AppRoutes.answers);
          return true;

        case '/users':
          if (queryParameters.containsKey('id')) {
            final userId = int.tryParse(queryParameters['id']!);
            if (userId != null) {
              await NavigationService.navigateToUserProfile(userId);
              return true;
            }
          }
          return false;

        case '/chat':
          if (queryParameters.containsKey('room')) {
            final roomId = int.tryParse(queryParameters['room']!);
            if (roomId != null) {
              await NavigationService.navigateToChatRoom(roomId);
              return true;
            }
          }
          await NavigationService.pushNamed(AppRoutes.chat);
          return true;

        case '/search':
          if (queryParameters.containsKey('q')) {
            final query = queryParameters['q']!;
            await NavigationService.navigateToSearchResults(query);
            return true;
          }
          await NavigationService.pushNamed(AppRoutes.search);
          return true;

        default:
          // Handle custom deep links
          if (path.startsWith('/question/')) {
            final idString = path.split('/').last;
            final questionId = int.tryParse(idString);
            if (questionId != null) {
              await NavigationService.navigateToQuestionDetail(questionId);
              return true;
            }
          }
          return false;
      }
    } catch (e) {
      // Handle deep link errors
      await NavigationService.navigateToError('Failed to handle deep link: $e');
      return false;
    }
  }

  /// Generate deep link for question
  static String generateQuestionDeepLink(int questionId) {
    return 'https://astuq.app/questions?id=$questionId';
  }

  /// Generate deep link for answer
  static String generateAnswerDeepLink(int answerId) {
    return 'https://astuq.app/answers?id=$answerId';
  }

  /// Generate deep link for user profile
  static String generateUserProfileDeepLink(int userId) {
    return 'https://astuq.app/users?id=$userId';
  }

  /// Generate deep link for chat room
  static String generateChatRoomDeepLink(int roomId) {
    return 'https://astuq.app/chat?room=$roomId';
  }

  /// Generate deep link for search
  static String generateSearchDeepLink(String query) {
    return 'https://astuq.app/search?q=${Uri.encodeComponent(query)}';
  }
}
