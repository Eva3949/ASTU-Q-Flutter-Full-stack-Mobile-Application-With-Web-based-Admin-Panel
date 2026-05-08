import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/types/either.dart';

import '../../core/utils/logger.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_info.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/storage/local_cache_service.dart';
import '../../features/authentication/presentation/providers/authentication_provider.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notifications/domain/usecases/delete_notification_usecase.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/entities/notification.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/questions/domain/entities/question.dart';
import '../../features/questions/domain/entities/answer.dart';
import '../../features/questions/domain/repositories/question_repository.dart';
import '../../features/questions/data/repositories/question_repository_impl.dart';
import '../../features/questions/domain/usecases/vote_answer_usecase.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/chat/presentation/providers/chat_list_provider.dart';
import '../../features/chat/presentation/providers/chat_detail_provider.dart';
import '../../features/chat/domain/usecases/get_chat_conversations_usecase.dart';
import '../../features/chat/domain/usecases/mark_conversation_read_usecase.dart';
import '../../features/chat/domain/usecases/delete_conversation_usecase.dart';
import '../../features/chat/domain/usecases/get_chat_messages_usecase.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/domain/usecases/mark_message_read_usecase.dart';
import '../../features/chat/domain/entities/chat_conversation.dart';
import '../../features/chat/domain/entities/chat_message.dart';
import '../../features/chat/domain/usecases/usecase.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/profile/domain/usecases/get_user_profile_usecase.dart';
import '../../features/profile/domain/usecases/get_user_questions_usecase.dart';
import '../../features/profile/domain/usecases/get_user_answers_usecase.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/usecases/logout_usecase.dart'
    as profile_logout;
import '../../features/questions/presentation/providers/simple_question_provider.dart';
import '../../features/questions/presentation/providers/question_provider.dart';
import '../../features/questions/presentation/providers/question_detail_provider.dart';
import '../../features/questions/presentation/providers/ask_question_provider.dart';
import '../../features/leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import '../../features/leaderboard/domain/entities/leaderboard_user.dart';
import '../../features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';
import '../../features/leaderboard/domain/repositories/leaderboard_repository.dart';
import '../../features/questions/domain/usecases/get_questions_usecase.dart';
import '../../features/questions/domain/usecases/search_questions_usecase.dart';
import '../../features/questions/domain/usecases/filter_questions_by_subject_usecase.dart';
import '../../features/questions/domain/usecases/vote_question_usecase.dart';
import '../../features/questions/domain/usecases/create_question_usecase.dart';
import '../../features/questions/domain/usecases/update_question_usecase.dart';
import '../../features/questions/domain/usecases/delete_question_usecase.dart';
import '../../features/questions/domain/usecases/get_question_detail_usecase.dart';
import '../../features/questions/domain/usecases/get_answers_usecase.dart';
import '../../features/questions/domain/usecases/create_answer_usecase.dart';
import '../../features/questions/domain/usecases/mark_best_answer_usecase.dart';
import '../../features/questions/domain/usecases/upload_image_usecase.dart';
import '../notifications/notification_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Logger
  sl.registerLazySingleton<Logger>(() => Logger('App'));

  // Network dependencies
  sl.registerLazySingleton<NetworkInfo>(() => MockNetworkInfo());
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage(sl<Logger>()));
  final cacheService = LocalCacheService();
  await cacheService.init();
  sl.registerSingleton<LocalCacheService>(cacheService);

  sl.registerLazySingleton<DioClient>(
    () => DioClient(sl<NetworkInfo>(), sl<Logger>()),
  );

  // API Service
  sl.registerLazySingleton<ApiService>(
    () => ApiService(sl<DioClient>().dio, sl<SecureStorage>(), sl<Logger>()),
  );

  // Notification Service
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl<Logger>()),
  );

  // Real Repositories
  sl.registerLazySingleton<AuthRepository>(
    () =>
        AuthRepositoryImpl(sl<DioClient>(), sl<SecureStorage>(), sl<Logger>()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sl<DioClient>(),
      sl<Logger>(),
      sl<SecureStorage>(),
    ),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      sl<DioClient>(),
      sl<SecureStorage>(),
      sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<QuestionRepository>(
    () => QuestionRepositoryImpl(
      sl<DioClient>(),
      sl<SecureStorage>(),
      sl<Logger>(),
    ),
  );

  // Auth Use Cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ChangePasswordUseCase>(
    () => ChangePasswordUseCase(sl<AuthRepository>()),
  );

  // Auth Provider
  sl.registerLazySingleton<AuthenticationProvider>(
    () => AuthenticationProvider(
      sl<LoginUseCase>(),
      sl<RegisterUseCase>(),
      sl<LogoutUseCase>(),
      sl<GetCurrentUserUseCase>(),
      sl<Logger>(),
    ),
  );

  // Real Notification use cases
  sl.registerLazySingleton<GetNotificationsUseCase>(
    () => GetNotificationsUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<MarkNotificationReadUseCase>(
    () => MarkNotificationReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<MarkAllNotificationsReadUseCase>(
    () => MarkAllNotificationsReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton<DeleteNotificationUseCase>(
    () => DeleteNotificationUseCase(sl<NotificationRepository>()),
  );

  // Real Notification Provider
  sl.registerLazySingleton<NotificationProvider>(
    () => NotificationProvider(
      sl<GetNotificationsUseCase>(),
      sl<MarkNotificationReadUseCase>(),
      sl<MarkAllNotificationsReadUseCase>(),
      sl<DeleteNotificationUseCase>(),
      sl<Logger>(),
      sl<LocalCacheService>(),
      sl<NotificationService>(),
    ),
  );

  sl.registerFactory<SimpleQuestionProvider>(() => SimpleQuestionProvider());

  // Real Question use cases
  sl.registerLazySingleton<GetQuestionsUseCase>(
    () => GetQuestionsUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<SearchQuestionsUseCase>(
    () => SearchQuestionsUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<FilterQuestionsBySubjectUseCase>(
    () => FilterQuestionsBySubjectUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<VoteQuestionUseCase>(
    () => VoteQuestionUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<GetQuestionDetailUseCase>(
    () => GetQuestionDetailUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<GetAnswersUseCase>(
    () => GetAnswersUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<CreateAnswerUseCase>(
    () => CreateAnswerUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<VoteAnswerUseCase>(
    () => VoteAnswerUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<MarkBestAnswerUseCase>(
    () => MarkBestAnswerUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<CreateQuestionUseCase>(
    () => CreateQuestionUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<UpdateQuestionUseCase>(
    () => UpdateQuestionUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<DeleteQuestionUseCase>(
    () => DeleteQuestionUseCase(sl<QuestionRepository>()),
  );
  sl.registerLazySingleton<UploadImageUseCase>(
    () => UploadImageUseCase(sl<QuestionRepository>()),
  );

  // Question providers
  sl.registerFactory<QuestionProvider>(
    () => QuestionProvider(
      sl<GetQuestionsUseCase>(),
      sl<FilterQuestionsBySubjectUseCase>(),
      sl<VoteQuestionUseCase>(),
      sl<Logger>(),
      sl<LocalCacheService>(),
    ),
  );

  sl.registerFactory<QuestionDetailProvider>(
    () => QuestionDetailProvider(
      sl<GetQuestionDetailUseCase>(),
      sl<GetAnswersUseCase>(),
      sl<CreateAnswerUseCase>(),
      sl<VoteAnswerUseCase>(),
      sl<VoteQuestionUseCase>(),
      sl<MarkBestAnswerUseCase>(),
      sl<Logger>(),
      sl<AuthenticationProvider>(),
      sl<ApiService>(),
      sl<ProfileProvider>(),
    ),
  );

  sl.registerFactory<AskQuestionProvider>(
    () => AskQuestionProvider(
      sl<CreateQuestionUseCase>(),
      sl<UpdateQuestionUseCase>(),
      sl<UploadImageUseCase>(),
      sl<Logger>(),
      sl<AuthenticationProvider>(),
      sl<ApiService>(),
      sl<ProfileProvider>(),
    ),
  );

  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(sl<DioClient>(), sl<Logger>()),
  );

  sl.registerLazySingleton<GetLeaderboardUseCase>(
    () => GetLeaderboardUseCase(sl<LeaderboardRepository>()),
  );

  sl.registerFactory<LeaderboardProvider>(
    () => LeaderboardProvider(
      sl<GetLeaderboardUseCase>(),
      sl<Logger>(),
      sl<AuthenticationProvider>(),
    ),
  );

  // Profile Use Cases
  sl.registerLazySingleton<GetUserProfileUseCase>(
    () => GetUserProfileUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<GetUserQuestionsUseCase>(
    () => GetUserQuestionsUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<GetUserAnswersUseCase>(
    () => GetUserAnswersUseCase(sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<profile_logout.LogoutUseCase>(
    () => profile_logout.LogoutUseCase(sl<ProfileRepository>()),
  );

  // Profile Provider
  sl.registerFactory<ProfileProvider>(
    () => ProfileProvider(
      sl<GetUserProfileUseCase>(),
      sl<GetUserQuestionsUseCase>(),
      sl<GetUserAnswersUseCase>(),
      sl<profile_logout.LogoutUseCase>(),
      sl<DeleteQuestionUseCase>(),
      sl<Logger>(),
      sl<AuthenticationProvider>(),
      sl<LocalCacheService>(),
    ),
  );

  // Chat providers and dependencies
  sl.registerLazySingleton<MockGetChatConversationsUseCase>(
    () => MockGetChatConversationsUseCase(),
  );
  sl.registerLazySingleton<MockMarkConversationReadUseCase>(
    () => MockMarkConversationReadUseCase(),
  );
  sl.registerLazySingleton<MockDeleteConversationUseCase>(
    () => MockDeleteConversationUseCase(),
  );
  sl.registerLazySingleton<MockGetChatMessagesUseCase>(
    () => MockGetChatMessagesUseCase(),
  );
  sl.registerLazySingleton<MockChatSendMessageUseCase>(
    () => MockChatSendMessageUseCase(),
  );
  sl.registerLazySingleton<MockMarkMessageReadUseCase>(
    () => MockMarkMessageReadUseCase(),
  );

  sl.registerLazySingleton<ChatListProvider>(
    () => ChatListProvider(
      sl<MockGetChatConversationsUseCase>(),
      sl<MockMarkConversationReadUseCase>(),
      sl<MockDeleteConversationUseCase>(),
      sl<Logger>(),
    ),
  );

  sl.registerLazySingleton<ChatDetailProvider>(
    () => ChatDetailProvider(
      sl<MockGetChatMessagesUseCase>(),
      sl<MockChatSendMessageUseCase>(),
      sl<MockMarkMessageReadUseCase>(),
      sl<Logger>(),
    ),
  );

  sl.registerFactory<ChatProvider>(() => ChatProvider());
}

// Simple QuestionProvider interface for mock implementation
abstract class QuestionProviderInterface extends ChangeNotifier {
  List<Question> get questions;
  bool get isLoading;
  bool get isRefreshing;
  bool get isLoadingMore;
  String? get errorMessage;
  String get searchQuery;
  String? get selectedSubject;
  bool get hasMore;
  bool get isSearching;
  int get questionCount;

  Future<void> refreshQuestions();
  Future<void> loadMoreQuestions();
  Future<void> searchQuestions(String query);
  Future<void> filterBySubject(String? subject);
  Future<void> clearSearchAndFilters();
  Future<void> voteQuestion(int questionId, VoteType voteType);
  List<String> getAvailableSubjects();
}

// Simple mock provider that implements QuestionProvider interface
class MockQuestionProvider extends QuestionProviderInterface {
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedSubject;
  bool _hasMore = false;

  // Getters that match QuestionProvider interface
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSubject => _selectedSubject;
  bool get hasMore => _hasMore;
  bool get isSearching => _searchQuery.isNotEmpty || _selectedSubject != null;
  int get questionCount => _questions.length;

  MockQuestionProvider() {
    // Initialize with empty data to avoid async initialization issues
    _questions = [];
    _isLoading = false;
    _errorMessage = null;
  }

  Future<void> refreshQuestions() async {
    try {
      _isRefreshing = true;
      notifyListeners();
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      _questions = []; // Empty for now
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh questions';
      _isRefreshing = false;
      notifyListeners();
    }
  }

  List<String> getAvailableSubjects() {
    return [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Computer Science',
    ];
  }

  Future<void> loadMoreQuestions() async {
    // Mock implementation - does nothing for now
    await Future.delayed(Duration(milliseconds: 500));
    notifyListeners();
  }

  @override
  Future<void> searchQuestions(String query) async {
    try {
      _isLoading = true;
      notifyListeners();
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      _searchQuery = query;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to search questions';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> filterBySubject(String? subject) async {
    try {
      _isLoading = true;
      notifyListeners();
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      _selectedSubject = subject;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to filter questions';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> clearSearchAndFilters() async {
    _searchQuery = '';
    _selectedSubject = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> voteQuestion(int questionId, VoteType voteType) async {
    try {
      // Mock implementation - simulate voting
      await Future.delayed(Duration(milliseconds: 500));
      // In a real implementation, this would update the question's vote count
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to vote on question';
      notifyListeners();
    }
  }
}

class MockChatProvider extends ChatProvider {
  MockChatProvider() : super();
}

// Mock Notification Repository
final NotificationRepository mockNotificationRepository =
    MockNotificationRepository();

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<Either<Failure, List<Notification>>> getNotifications(
    GetNotificationsParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(<Notification>[]);
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(
    MarkNotificationReadParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead() async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    DeleteNotificationParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

// Mock Auth Repository
class MockAuthRepository implements AuthRepository {
  final SecureStorage _secureStorage;

  MockAuthRepository(this._secureStorage);

  @override
  Future<Either<Failure, User>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    final now = DateTime.now();
    final user = User(
      id: 1,
      email: email,
      name: 'Test User',
      emailVerifiedAt: now,
      lastLoginAt: now,
      createdAt: now,
      updatedAt: now,
    );

    // Save user data to secure storage for session persistence
    await _secureStorage.saveToken('mock_token');
    await _secureStorage.saveUserData({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'email_verified_at': user.emailVerifiedAt?.toIso8601String(),
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt?.toIso8601String(),
      'updated_at': user.updatedAt?.toIso8601String(),
    });
    await _secureStorage.saveRememberMe(rememberMe);

    return Either.right(user);
  }

  @override
  Future<Either<Failure, User>> register(
    String name,
    String email,
    String password,
    String confirmPassword, {
    String? username,
    String? phone,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final now = DateTime.now();
    final user = User(
      id: 1,
      email: email,
      name: name,
      phone: phone,
      emailVerifiedAt: now,
      lastLoginAt: now,
      createdAt: now,
      updatedAt: now,
    );

    // Save user data to secure storage for session persistence
    await _secureStorage.saveToken('mock_token');
    await _secureStorage.saveUserData({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'phone': user.phone,
      'email_verified_at': user.emailVerifiedAt?.toIso8601String(),
      'last_login_at': user.lastLoginAt?.toIso8601String(),
      'created_at': user.createdAt?.toIso8601String(),
      'updated_at': user.updatedAt?.toIso8601String(),
    });

    return Either.right(user);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    await Future.delayed(Duration(seconds: 1));
    // Clear all authentication data
    await _secureStorage.clearAll();
    return Either.right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    await Future.delayed(Duration(milliseconds: 500));

    // Check if user data exists in secure storage
    final userData = await _secureStorage.getUserData(quiet: true);
    if (userData != null) {
      final now = DateTime.now();
      return Either.right(
        User(
          id: userData['id'] as int? ?? 1,
          email: userData['email'] as String? ?? 'test@example.com',
          name: userData['name'] as String? ?? 'Test User',
          phone: userData['phone'] as String?,
          emailVerifiedAt: userData['email_verified_at'] != null
              ? DateTime.parse(userData['email_verified_at'] as String)
              : now,
          lastLoginAt: userData['last_login_at'] != null
              ? DateTime.parse(userData['last_login_at'] as String)
              : now,
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'] as String)
              : now,
          updatedAt: userData['updated_at'] != null
              ? DateTime.parse(userData['updated_at'] as String)
              : now,
        ),
      );
    }

    return Either.left(UnauthorizedFailure('No user logged in'));
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final now = DateTime.now();

    // Get current user data
    final userData = await _secureStorage.getUserData(quiet: true);
    if (userData != null) {
      // Update user data
      userData['name'] = name ?? userData['name'];
      userData['email'] = email ?? userData['email'];
      userData['phone'] = phone ?? userData['phone'];
      userData['bio'] = bio;
      userData['updated_at'] = now.toIso8601String();

      await _secureStorage.saveUserData(userData);

      return Either.right(
        User(
          id: userData['id'] as int? ?? 1,
          email: userData['email'] as String? ?? 'test@example.com',
          name: userData['name'] as String? ?? 'Test User',
          phone: userData['phone'] as String?,
          bio: userData['bio'] as String?,
          emailVerifiedAt: userData['email_verified_at'] != null
              ? DateTime.parse(userData['email_verified_at'] as String)
              : now,
          lastLoginAt: userData['last_login_at'] != null
              ? DateTime.parse(userData['last_login_at'] as String)
              : now,
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'] as String)
              : now,
          updatedAt: now,
        ),
      );
    }

    return Either.left(UnauthorizedFailure('No user logged in'));
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right('mock_token');
  }

  @override
  bool isAuthenticated() {
    return false;
  }

  @override
  Future<void> saveToken(String token) async {
    // Mock implementation
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Future<void> clearAuthData() async {
    // Mock implementation
  }
}

// Mock Use Cases
class MockLoginUseCase extends LoginUseCase {
  MockLoginUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Mock implementation - return a successful login for demo purposes
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    final now = DateTime.now();
    return Either.right(
      User(
        id: 1,
        email: params.email,
        name: 'Test User',
        emailVerifiedAt: now,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class MockRegisterUseCase extends RegisterUseCase {
  MockRegisterUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    await Future.delayed(Duration(seconds: 1));
    final now = DateTime.now();
    return Either.right(
      User(
        id: 1,
        email: params.email,
        name: params.name,
        emailVerifiedAt: now,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class MockLogoutUseCase extends LogoutUseCase {
  MockLogoutUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, void>> call() async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockGetCurrentUserUseCase extends GetCurrentUserUseCase {
  MockGetCurrentUserUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, User>> call() async {
    await Future.delayed(Duration(seconds: 1));
    return Either.left(UnauthorizedFailure('No user logged in'));
  }
}

class MockUpdateProfileUseCase extends UpdateProfileUseCase {
  MockUpdateProfileUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    await Future.delayed(Duration(seconds: 1));
    final now = DateTime.now();
    return Either.right(
      User(
        id: 1,
        email: params.email ?? 'test@example.com',
        name: params.name ?? 'Test User',
        emailVerifiedAt: now,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

// Mock Question Repository (for testing)
final QuestionRepository mockQuestionRepository = MockQuestionRepository();

class MockQuestionRepository implements QuestionRepository {
  final List<Question> _questions = [
    Question(
      id: 1,
      title: 'How do I solve this calculus limit?',
      content: 'I am stuck on evaluating a limit using L Hospital rule.',
      subject: 'Mathematics',
      authorId: '1',
      authorName: 'Test User',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      tags: const ['calculus', 'limits'],
      upvotes: 5,
      answerCount: 1,
    ),
    Question(
      id: 2,
      title: 'Why is my Flutter widget not rebuilding?',
      content: 'State changes are happening but the UI is not updating.',
      subject: 'Computer Science',
      authorId: '2',
      authorName: 'Student Two',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      tags: const ['flutter', 'state-management'],
      upvotes: 3,
      answerCount: 0,
    ),
  ];

  final List<Answer> _answers = [
    Answer(
      id: 1,
      content: 'Try checking the indeterminate form before applying the rule.',
      questionId: 1,
      authorId: '3',
      authorName: 'Tutor One',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      upvotes: 2,
    ),
  ];

  int _nextQuestionId = 3;
  int _nextAnswerId = 2;

  @override
  Future<Either<Failure, Question>> createQuestion(
    CreateQuestionParams params,
  ) async {
    final question = Question(
      id: _nextQuestionId++,
      title: params.title,
      content: params.content,
      subject: params.subject,
      authorId: '1',
      authorName: 'Test User',
      images: params.images,
      createdAt: DateTime.now(),
      tags: const [],
    );
    _questions.insert(0, question);
    return Either.right(question);
  }

  @override
  Future<Either<Failure, String>> uploadImage(UploadImageParams params) async {
    final fileName = params.imagePath.split(RegExp(r'[\\/]')).last;
    return Either.right('http://10.0.2.2/astuq/uploads/questions/$fileName');
  }

  @override
  Future<Either<Failure, Question>> getQuestionById(int id) async {
    try {
      return Either.right(
        _questions.firstWhere((question) => question.id == id),
      );
    } catch (_) {
      return Either.left(NotFoundFailure('Question not found'));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestions({
    int page = 1,
    int limit = 20,
    String? subject,
    String? search,
  }) async {
    Iterable<Question> filtered = _questions;

    if (subject != null && subject.isNotEmpty) {
      filtered = filtered.where((question) => question.subject == subject);
    }

    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered.where(
        (question) =>
            question.title.toLowerCase().contains(query) ||
            question.content.toLowerCase().contains(query) ||
            question.subject.toLowerCase().contains(query),
      );
    }

    final start = (page - 1) * limit;
    final items = filtered.toList();
    if (start >= items.length) {
      return Either.right([]);
    }

    final end = (start + limit).clamp(0, items.length);
    return Either.right(items.sublist(start, end));
  }

  @override
  Future<Either<Failure, Question>> updateQuestion(Question question) async {
    final index = _questions.indexWhere((item) => item.id == question.id);
    if (index == -1) {
      return Either.left(NotFoundFailure('Question not found'));
    }
    _questions[index] = question;
    return Either.right(question);
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(int id) async {
    _questions.removeWhere((question) => question.id == id);
    _answers.removeWhere((answer) => answer.questionId == id);
    return Either.right(null);
  }

  @override
  Future<Either<Failure, Question>> upvoteQuestion(int questionId) async {
    return getQuestionById(questionId).then(
      (result) => result.fold((failure) => Either.left(failure), (question) {
        final updated = question.copyWith(upvotes: question.upvotes + 1);
        return updateQuestion(updated);
      }),
    );
  }

  @override
  Future<Either<Failure, Question>> downvoteQuestion(int questionId) async {
    return getQuestionById(questionId).then(
      (result) => result.fold((failure) => Either.left(failure), (question) {
        final updated = question.copyWith(downvotes: question.downvotes + 1);
        return updateQuestion(updated);
      }),
    );
  }

  @override
  Future<Either<Failure, Question>> bookmarkQuestion(int questionId) async {
    return getQuestionById(questionId).then(
      (result) => result.fold(
        (failure) => Either.left(failure),
        (question) => updateQuestion(question.copyWith(isBookmarked: true)),
      ),
    );
  }

  @override
  Future<Either<Failure, Question>> removeBookmark(int id) async {
    return getQuestionById(id).then(
      (result) => result.fold(
        (failure) => Either.left(failure),
        (question) => updateQuestion(question.copyWith(isBookmarked: false)),
      ),
    );
  }

  @override
  Future<Either<Failure, List<Answer>>> getAnswers(
    GetAnswersParams params,
  ) async {
    final filtered = _answers
        .where((answer) => answer.questionId == params.questionId)
        .toList();
    final start = (params.page - 1) * params.limit;
    if (start >= filtered.length) {
      return Either.right([]);
    }
    final end = (start + params.limit).clamp(0, filtered.length);
    return Either.right(filtered.sublist(start, end));
  }

  @override
  Future<Either<Failure, Answer>> createAnswer(
    CreateAnswerParams params,
  ) async {
    final answer = Answer(
      id: _nextAnswerId++,
      content: params.content,
      questionId: params.questionId,
      authorId: '1',
      authorName: 'Test User',
      createdAt: DateTime.now(),
    );
    _answers.add(answer);

    final index = _questions.indexWhere(
      (question) => question.id == params.questionId,
    );
    if (index != -1) {
      final question = _questions[index];
      _questions[index] = question.copyWith(
        answerCount: question.answerCount + 1,
      );
    }

    return Either.right(answer);
  }

  @override
  Future<Either<Failure, Answer>> voteAnswer(VoteAnswerParams params) async {
    final index = _answers.indexWhere((answer) => answer.id == params.answerId);
    if (index == -1) {
      return Either.left(NotFoundFailure('Answer not found'));
    }

    final answer = _answers[index];
    final updated = params.voteType == VoteType.upvote
        ? answer.copyWith(upvotes: answer.upvotes + 1, isUpvoted: true)
        : answer.copyWith(downvotes: answer.downvotes + 1, isDownvoted: true);
    _answers[index] = updated;
    return Either.right(updated);
  }

  @override
  Future<Either<Failure, Question>> voteQuestion(
    VoteQuestionParams params,
  ) async {
    return params.voteType == VoteType.upvote
        ? upvoteQuestion(params.questionId)
        : downvoteQuestion(params.questionId);
  }

  @override
  Future<Either<Failure, void>> markBestAnswer(
    MarkBestAnswerParams params,
  ) async {
    final answerIndex = _answers.indexWhere(
      (answer) => answer.id == params.answerId,
    );
    if (answerIndex == -1) {
      return Either.left(NotFoundFailure('Answer not found'));
    }

    final target = _answers[answerIndex];
    for (var i = 0; i < _answers.length; i++) {
      if (_answers[i].questionId == target.questionId) {
        _answers[i] = _answers[i].copyWith(isBest: _answers[i].id == target.id);
      }
    }

    final questionIndex = _questions.indexWhere(
      (question) => question.id == target.questionId,
    );
    if (questionIndex != -1) {
      final question = _questions[questionIndex];
      _questions[questionIndex] = question.copyWith(
        isResolved: true,
        acceptedAnswerId: target.id.toString(),
      );
    }

    return Either.right(null);
  }
}

class MockChangePasswordUseCase extends ChangePasswordUseCase {
  MockChangePasswordUseCase() : super(MockAuthRepository(sl<SecureStorage>()));

  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockGetNotificationsUseCase extends GetNotificationsUseCase {
  MockGetNotificationsUseCase() : super(mockNotificationRepository);

  @override
  Future<Either<Failure, List<Notification>>> call(
    GetNotificationsParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right([]);
  }
}

class MockMarkNotificationReadUseCase extends MarkNotificationReadUseCase {
  MockMarkNotificationReadUseCase() : super(mockNotificationRepository);

  @override
  Future<Either<Failure, void>> call(MarkNotificationReadParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockMarkAllNotificationsReadUseCase
    extends MarkAllNotificationsReadUseCase {
  MockMarkAllNotificationsReadUseCase() : super(mockNotificationRepository);

  @override
  Future<Either<Failure, void>> call() async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockDeleteNotificationUseCase extends DeleteNotificationUseCase {
  MockDeleteNotificationUseCase() : super(mockNotificationRepository);

  @override
  Future<Either<Failure, void>> call(DeleteNotificationParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockGetQuestionsUseCase extends GetQuestionsUseCase {
  MockGetQuestionsUseCase() : super(mockQuestionRepository);
}

class MockSearchQuestionsUseCase extends SearchQuestionsUseCase {
  MockSearchQuestionsUseCase() : super(mockQuestionRepository);
}

class MockFilterQuestionsBySubjectUseCase
    extends FilterQuestionsBySubjectUseCase {
  MockFilterQuestionsBySubjectUseCase() : super(mockQuestionRepository);
}

class MockVoteQuestionUseCase extends VoteQuestionUseCase {
  MockVoteQuestionUseCase() : super(mockQuestionRepository);
}

class MockCreateQuestionUseCase extends CreateQuestionUseCase {
  MockCreateQuestionUseCase() : super(mockQuestionRepository);
}

class MockUpdateQuestionUseCase {
  MockUpdateQuestionUseCase();
}

class MockGetQuestionDetailUseCase extends GetQuestionDetailUseCase {
  MockGetQuestionDetailUseCase() : super(mockQuestionRepository);
}

class MockGetAnswersUseCase extends GetAnswersUseCase {
  MockGetAnswersUseCase() : super(mockQuestionRepository);
}

class MockCreateAnswerUseCase extends CreateAnswerUseCase {
  MockCreateAnswerUseCase() : super(mockQuestionRepository);
}

class MockVoteAnswerUseCase extends VoteAnswerUseCase {
  MockVoteAnswerUseCase() : super(mockQuestionRepository);
}

class MockMarkBestAnswerUseCase extends MarkBestAnswerUseCase {
  MockMarkBestAnswerUseCase() : super(mockQuestionRepository);
}

class MockUploadImageUseCase extends UploadImageUseCase {
  MockUploadImageUseCase() : super(mockQuestionRepository);
}

class MockDeleteQuestionUseCase {
  MockDeleteQuestionUseCase();
}

class MockGetChatsUseCase {
  MockGetChatsUseCase();
}

class MockCreateChatUseCase {
  MockCreateChatUseCase();
}

class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Future<Either<Failure, List<LeaderboardUser>>> getLeaderboard({
    required int page,
    required int limit,
    required String timeFilter,
    required String category,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    // Return mock leaderboard data
    final mockUsers = [
      LeaderboardUser(
        id: 1,
        name: 'John Doe',
        points: 1250,
        level: 5,
        rank: 1,
        questions: 45,
        answers: 120,
        badges: ['gold', 'helpful'],
        avatarUrl: null,
      ),
      LeaderboardUser(
        id: 2,
        name: 'Jane Smith',
        points: 1100,
        level: 4,
        rank: 2,
        questions: 38,
        answers: 95,
        badges: ['silver', 'expert'],
        avatarUrl: null,
      ),
      LeaderboardUser(
        id: 3,
        name: 'Bob Johnson',
        points: 950,
        level: 4,
        rank: 3,
        questions: 30,
        answers: 80,
        badges: ['bronze'],
        avatarUrl: null,
      ),
      LeaderboardUser(
        id: 4,
        name: 'Alice Williams',
        points: 850,
        level: 3,
        rank: 4,
        questions: 25,
        answers: 70,
        badges: ['rising_star'],
        avatarUrl: null,
      ),
      LeaderboardUser(
        id: 5,
        name: 'Charlie Brown',
        points: 750,
        level: 3,
        rank: 5,
        questions: 20,
        answers: 60,
        badges: [],
        avatarUrl: null,
      ),
    ];
    return Either.right(mockUsers);
  }

  @override
  Future<Either<Failure, int>> getUserRank({
    required int userId,
    required String timeFilter,
    required String category,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));
    return Either.right(userId);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getLeaderboardStats({
    required String timeFilter,
    required String category,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));
    return Either.right({'totalUsers': 5, 'totalPoints': 4900});
  }
}

class MockGetLeaderboardUseCase {
  MockGetLeaderboardUseCase();
}

// Mock Chat Use Cases
class MockGetChatConversationsUseCase
    implements UseCase<List<ChatConversation>, GetChatConversationsParams> {
  @override
  Future<Either<Failure, List<ChatConversation>>> call(
    GetChatConversationsParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right([]);
  }
}

class MockMarkConversationReadUseCase
    implements UseCase<void, MarkConversationReadParams> {
  @override
  Future<Either<Failure, void>> call(MarkConversationReadParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockDeleteConversationUseCase
    implements UseCase<void, DeleteConversationParams> {
  @override
  Future<Either<Failure, void>> call(DeleteConversationParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

class MockGetChatMessagesUseCase
    implements UseCase<List<ChatMessage>, GetChatMessagesParams> {
  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetChatMessagesParams params,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right([]);
  }
}

class MockChatSendMessageUseCase
    implements UseCase<ChatMessage, SendMessageParams> {
  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    await Future.delayed(Duration(seconds: 1));
    // Return a mock message
    final now = DateTime.now();
    return Either.right(
      ChatMessage(
        id: 1,
        conversationId: params.conversationId,
        senderId: 1,
        senderName: 'You',
        content: params.content,
        type: params.type,
        isFromCurrentUser: true,
        isRead: false,
        createdAt: now,
      ),
    );
  }
}

class MockMarkMessageReadUseCase
    implements UseCase<void, MarkMessageReadParams> {
  @override
  Future<Either<Failure, void>> call(MarkMessageReadParams params) async {
    await Future.delayed(Duration(seconds: 1));
    return Either.right(null);
  }
}

// Mock NetworkInfo for dependency injection
class MockNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Future<ConnectivityResult> get connectivityResult async =>
      ConnectivityResult.wifi;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged =>
      Stream.value(ConnectivityResult.wifi);
}
