import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/get_user_questions_usecase.dart';
import '../../domain/usecases/get_user_answers_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../questions/domain/usecases/delete_question_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/storage/local_cache_service.dart';

import '../../../authentication/presentation/providers/authentication_provider.dart';

/// Profile Provider
/// Manages user profile state and operations
@singleton
class ProfileProvider extends ChangeNotifier {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final GetUserQuestionsUseCase _getUserQuestionsUseCase;
  final GetUserAnswersUseCase _getUserAnswersUseCase;
  final LogoutUseCase _logoutUseCase;
  final DeleteQuestionUseCase _deleteQuestionUseCase;
  final Logger _logger;
  final AuthenticationProvider _authProvider;
  final LocalCacheService _cache;

  static const String _cacheKeyProfile = 'cache_profile';
  static const String _cacheKeyQuestions = 'cache_profile_questions';
  static const String _cacheKeyAnswers = 'cache_profile_answers';

  ProfileProvider(
    this._getUserProfileUseCase,
    this._getUserQuestionsUseCase,
    this._getUserAnswersUseCase,
    this._logoutUseCase,
    this._deleteQuestionUseCase,
    this._logger,
    this._authProvider,
    this._cache,
  );

  // State variables
  UserProfile? _userProfile;
  List<Question> _userQuestions = [];
  List<Answer> _userAnswers = [];
  bool _isLoading = false;
  bool _isLoadingQuestions = false;
  bool _isLoadingAnswers = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  int _questionsPage = 1;
  int _answersPage = 1;
  bool _hasMoreQuestions = true;
  bool _hasMoreAnswers = true;
  bool _isLoadingMoreQuestions = false;
  bool _isLoadingMoreAnswers = false;

  /// Safe notify listeners to avoid "setState() called during build" errors
  void _safeNotify() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<Question> get userQuestions => _userQuestions;
  List<Answer> get userAnswers => _userAnswers;
  bool get isLoading => _isLoading;
  bool get isLoadingQuestions => _isLoadingQuestions;
  bool get isLoadingAnswers => _isLoadingAnswers;
  bool get isLoggingOut => _isLoggingOut;
  String? get errorMessage => _errorMessage;
  bool get hasMoreQuestions => _hasMoreQuestions;
  bool get hasMoreAnswers => _hasMoreAnswers;
  bool get isLoadingMoreQuestions => _isLoadingMoreQuestions;
  bool get isLoadingMoreAnswers => _isLoadingMoreAnswers;
  int get questionCount => _userQuestions.length;
  int get answerCount => _userAnswers.length;

  /// Load user profile data
  Future<void> loadUserProfile({bool force = false}) async {
    // If already loading, don't load again
    if (_isLoading) return;

    // If already have profile and not forced, don't load again
    if (!force && _userProfile != null && _errorMessage == null) return;

    // Prevent re-loading if the previous error was "User ID not found" (unauthorized)
    if (!force &&
        _errorMessage != null &&
        _errorMessage!.contains('not found')) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _logger.d('Loading user profile...');

      // Try to use ID from auth provider if available
      int? userId = _authProvider.user?.id;
      _logger.d('User ID from AuthProvider: $userId');

      final result = await _getUserProfileUseCase(userId: userId);

      bool success = false;
      result.fold(
        (failure) {
          _logger.e('Failed to load user profile: ${failure.message}');
          _tryLoadProfileFromCache();
          if (_userProfile == null) {
            _setError(_getErrorMessage(failure));
          } else {
            success = true;
          }
        },
        (profile) {
          _userProfile = profile;
          _saveProfileToCache();
          _logger.d('User profile loaded: ${profile.name}');
          success = true;
        },
      );

      if (!success) return;

      // Load user questions and answers in parallel
      await Future.wait([
        _loadUserQuestions(refresh: true),
        _loadUserAnswers(refresh: true),
      ]);
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error loading user profile', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Load user questions
  Future<void> _loadUserQuestions({bool refresh = false}) async {
    if (_userProfile == null) return;

    try {
      if (refresh) {
        _setLoadingQuestions(true);
        _questionsPage = 1;
        _hasMoreQuestions = true;
        _userQuestions.clear();
      } else {
        _setLoadingMoreQuestions(true);
      }

      _logger.d('Loading user questions, page: $_questionsPage');

      final result = await _getUserQuestionsUseCase(
        GetUserQuestionsParams(
          userId: _userProfile!.id,
          page: _questionsPage,
          limit: 10,
        ),
      );

      result.fold(
        (failure) {
          if (refresh) {
            _logger.e('Failed to load user questions: ${failure.message}');
            _tryLoadQuestionsFromCache();
            if (_userQuestions.isEmpty) {
              _setError(_getErrorMessage(failure));
            }
          }
        },
        (questions) {
          if (refresh) {
            _userQuestions = questions;
          } else {
            _userQuestions.addAll(questions);
          }

          _questionsPage++;
          _hasMoreQuestions = questions.length >= 10;
          _saveQuestionsToCache();

          _logger.d('Loaded ${questions.length} user questions');
        },
      );
    } catch (e) {
      _logger.e('Error loading user questions', error: e);
    } finally {
      _setLoadingQuestions(false);
      _setLoadingMoreQuestions(false);
    }
  }

  /// Load user answers
  Future<void> _loadUserAnswers({bool refresh = false}) async {
    if (_userProfile == null) return;

    try {
      if (refresh) {
        _setLoadingAnswers(true);
        _answersPage = 1;
        _hasMoreAnswers = true;
        _userAnswers.clear();
      } else {
        _setLoadingMoreAnswers(true);
      }

      _logger.d('Loading user answers, page: $_answersPage');

      final result = await _getUserAnswersUseCase(
        GetUserAnswersParams(
          userId: _userProfile!.id,
          page: _answersPage,
          limit: 10,
          sortBy: refresh ? 'created_at' : null,
          sortOrder: 'DESC',
        ),
      );

      result.fold(
        (failure) {
          if (refresh) {
            _logger.e('Failed to load user answers: ${failure.message}');
            _tryLoadAnswersFromCache();
            if (_userAnswers.isEmpty) {
              _setError(_getErrorMessage(failure));
            }
          }
        },
        (answers) {
          if (refresh) {
            _userAnswers = answers;
          } else {
            _userAnswers.addAll(answers);
          }

          _answersPage++;
          _hasMoreAnswers = answers.length >= 10;
          _saveAnswersToCache();

          _logger.d('Loaded ${answers.length} user answers');
        },
      );
    } catch (e) {
      _logger.e('Error loading user answers', error: e);
    } finally {
      _setLoadingAnswers(false);
      _setLoadingMoreAnswers(false);
    }
  }

  /// Load more questions
  Future<void> loadMoreQuestions() async {
    if (_isLoadingMoreQuestions || !_hasMoreQuestions || _userProfile == null)
      return;

    await _loadUserQuestions(refresh: false);
  }

  /// Load more answers
  Future<void> loadMoreAnswers() async {
    if (_isLoadingMoreAnswers || !_hasMoreAnswers || _userProfile == null)
      return;

    await _loadUserAnswers(refresh: false);
  }

  /// Load user questions directly without requiring full profile
  Future<void> loadUserQuestionsDirectly({bool forceRefresh = false}) async {
    final userId = _authProvider.user?.id;
    if (userId == null) {
      _setError('User not authenticated');
      return;
    }

    try {
      _setLoadingQuestions(true);
      _questionsPage = 1;
      _hasMoreQuestions = true;
      _userQuestions.clear();

      _logger.d(
        'Loading user questions directly for user: $userId, forceRefresh: $forceRefresh',
      );

      final result = await _getUserQuestionsUseCase(
        GetUserQuestionsParams(
          userId: userId,
          page: _questionsPage,
          limit: 10,
          sortBy: forceRefresh ? 'created_at' : null,
          sortOrder: 'DESC',
        ),
      );

      result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to load user questions: ${failure.message}');
        },
        (questions) {
          _userQuestions = questions;
          _questionsPage++;
          _hasMoreQuestions = questions.length >= 10;
          _logger.d('Loaded ${questions.length} user questions directly');
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred while loading questions');
      _logger.e('Error loading user questions directly', error: e);
    } finally {
      _setLoadingQuestions(false);
    }
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      _setLoggingOut(true);
      _clearError();

      _logger.d('Logging out user...');

      final result = await _logoutUseCase();

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to logout: ${failure.message}');
          return false;
        },
        (success) {
          _logger.d('User logged out successfully');
          reset();
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error logging out', error: e);
      return false;
    } finally {
      _setLoggingOut(false);
    }
  }

  /// Delete a question
  Future<bool> deleteQuestion(int questionId) async {
    try {
      _clearError();

      _logger.d('Deleting question: $questionId');

      final result = await _deleteQuestionUseCase(questionId);

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to delete question: ${failure.message}');
          return false;
        },
        (success) {
          _logger.d('Question deleted successfully: $questionId');
          // Remove the question from the local list
          _userQuestions.removeWhere((question) => question.id == questionId);
          _safeNotify();
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred while deleting the question');
      _logger.e('Error deleting question', error: e);
      return false;
    }
  }

  /// Update a question
  Future<bool> updateQuestion(
    int questionId,
    String title,
    String content,
    String subject, {
    List<String>? tags,
    List<String>? images,
  }) async {
    try {
      _clearError();

      _logger.d('Updating question: $questionId');

      // Find the existing question
      final existingQuestion = _userQuestions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw Exception('Question not found'),
      );

      // Make HTTP request to PHP backend
      final response = await http.post(
        Uri.parse('https://evadevstudio.com/sami/edit_question.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question_id': questionId,
          'title': title,
          'content': content,
          'subject': subject,
          'user_id': existingQuestion.userId,
          'tags': tags ?? existingQuestion.tags,
          'images': images ?? existingQuestion.images,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.d('Server response: ${response.body}');
        if (responseData['success'] == true) {
          // Create updated question object using profile domain Question fields
          final updatedQuestion = Question(
            id: questionId,
            title: title,
            content: content,
            subject: subject,
            userId: existingQuestion.userId,
            userName: existingQuestion.userName,
            userAvatarUrl: existingQuestion.userAvatarUrl,
            upvotes: existingQuestion.upvotes,
            downvotes: existingQuestion.downvotes,
            answerCount: existingQuestion.answerCount,
            createdAt: existingQuestion.createdAt,
            updatedAt: DateTime.now(),
            lastActivityAt: existingQuestion.lastActivityAt,
            tags: tags ?? existingQuestion.tags,
            images: images ?? existingQuestion.images,
            isSolved: existingQuestion.isSolved,
            bestAnswerId: existingQuestion.bestAnswerId,
            status: existingQuestion.status,
          );

          // Update the question in the local list
          final index = _userQuestions.indexWhere((q) => q.id == questionId);
          if (index != -1) {
            _userQuestions[index] = updatedQuestion;
            _safeNotify();
          }

          _logger.d('Question updated successfully: $questionId');
          return true;
        } else {
          _setError(responseData['error'] ?? 'Failed to update question');
          _logger.e('Update failed: ${responseData['error']}');
          return false;
        }
      } else {
        _setError('Server error: ${response.statusCode} - ${response.body}');
        _logger.e('Server error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred while updating the question');
      _logger.e('Error updating question', error: e);
      return false;
    }
  }

  /// Get user statistics
  Map<String, int> getUserStatistics() {
    if (_userProfile == null) return {};

    return {
      'points': _userProfile!.points,
      'level': _userProfile!.level,
      'questions': _userProfile!.questionsCount,
      'answers': _userProfile!.answersCount,
      'bestAnswers': _userProfile!.bestAnswersCount,
      'upvotesReceived':
          _userQuestions.fold<int>(
            0,
            (sum, question) => sum + question.upvotes,
          ) +
          _userAnswers.fold<int>(0, (sum, answer) => sum + answer.upvotes),
    };
  }

  /// Get level progress
  Map<String, dynamic> getLevelProgress() {
    if (_userProfile == null) return {};

    final currentLevel = _userProfile!.level;
    final currentPoints = _userProfile!.points;
    final pointsForNextLevel = _calculatePointsForLevel(currentLevel + 1);
    final pointsForCurrentLevel = _calculatePointsForLevel(currentLevel);
    final pointsInCurrentLevel = currentPoints - pointsForCurrentLevel;
    final pointsNeededForNextLevel = pointsForNextLevel - pointsForCurrentLevel;
    final progress = pointsNeededForNextLevel > 0
        ? (pointsInCurrentLevel / pointsNeededForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    return {
      'currentLevel': currentLevel,
      'currentPoints': currentPoints,
      'nextLevelPoints': pointsForNextLevel,
      'pointsToNextLevel': pointsForNextLevel - currentPoints,
      'progress': progress,
      'levelName': _getLevelName(currentLevel),
    };
  }

  /// Calculate points required for a level
  int _calculatePointsForLevel(int level) {
    // Simple exponential growth: 100 * (level ^ 1.5)
    return (100 * (level * 1.5)).round();
  }

  /// Get level name based on level number
  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Novice';
      case 3:
        return 'Apprentice';
      case 4:
        return 'Journeyman';
      case 5:
        return 'Expert';
      case 6:
        return 'Master';
      case 7:
        return 'Grandmaster';
      case 8:
        return 'Legend';
      default:
        if (level < 1) return 'Beginner';
        if (level > 8) return 'Mythical';
        return 'Level $level';
    }
  }

  /// Check if user can perform certain actions
  bool canAskQuestion() {
    return _userProfile != null && _userProfile!.level >= 1;
  }

  bool canAnswerQuestion() {
    return _userProfile != null && _userProfile!.level >= 1;
  }

  bool canVote() {
    return _userProfile != null && _userProfile!.level >= 1;
  }

  /// Get user achievements
  List<String> getAchievements() {
    final achievements = <String>[];
    final stats = getUserStatistics();

    if (stats['questions']! >= 1) achievements.add('First Question');
    if (stats['questions']! >= 10) achievements.add('Question Master');
    if (stats['questions']! >= 50) achievements.add('Question Expert');

    if (stats['answers']! >= 1) achievements.add('First Answer');
    if (stats['answers']! >= 10) achievements.add('Answer Master');
    if (stats['answers']! >= 50) achievements.add('Answer Expert');

    if (stats['bestAnswers']! >= 1) achievements.add('Best Answer');
    if (stats['bestAnswers']! >= 10) achievements.add('Best Answer Expert');

    if (stats['upvotesReceived']! >= 10) achievements.add('Popular');
    if (stats['upvotesReceived']! >= 100) achievements.add('Very Popular');

    if (_userProfile?.level != null) {
      if (_userProfile!.level >= 5) achievements.add('Expert User');
      if (_userProfile!.level >= 8) achievements.add('Master User');
    }

    return achievements;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }

  /// Set loading questions state
  void _setLoadingQuestions(bool loading) {
    _isLoadingQuestions = loading;
    _safeNotify();
  }

  /// Set loading answers state
  void _setLoadingAnswers(bool loading) {
    _isLoadingAnswers = loading;
    _safeNotify();
  }

  /// Set loading more questions state
  void _setLoadingMoreQuestions(bool loading) {
    _isLoadingMoreQuestions = loading;
    _safeNotify();
  }

  /// Set loading more answers state
  void _setLoadingMoreAnswers(bool loading) {
    _isLoadingMoreAnswers = loading;
    _safeNotify();
  }

  /// Set logging out state
  void _setLoggingOut(bool loggingOut) {
    _isLoggingOut = loggingOut;
    _safeNotify();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _safeNotify();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Session not found. Please log in.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'User profile not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Save profile to local cache
  void _saveProfileToCache() {
    try {
      if (_userProfile != null) {
        _cache.saveObject(_cacheKeyProfile, _userProfile!.toJson());
        _logger.d('Saved profile to cache');
      }
    } catch (e) {
      _logger.e('Failed to save profile to cache', error: e);
    }
  }

  /// Save questions to local cache
  void _saveQuestionsToCache() {
    try {
      final data = _userQuestions.map((q) => q.toJson()).toList();
      _cache.saveList(_cacheKeyQuestions, data);
      _logger.d('Saved ${_userQuestions.length} questions to cache');
    } catch (e) {
      _logger.e('Failed to save questions to cache', error: e);
    }
  }

  /// Save answers to local cache
  void _saveAnswersToCache() {
    try {
      final data = _userAnswers.map((a) => a.toJson()).toList();
      _cache.saveList(_cacheKeyAnswers, data);
      _logger.d('Saved ${_userAnswers.length} answers to cache');
    } catch (e) {
      _logger.e('Failed to save answers to cache', error: e);
    }
  }

  /// Try loading profile from local cache
  void _tryLoadProfileFromCache() {
    try {
      final cached = _cache.getObject(_cacheKeyProfile);
      if (cached != null) {
        _userProfile = UserProfile.fromJson(cached);
        _logger.d('Loaded profile from cache');
        _safeNotify();
      }
    } catch (e) {
      _logger.e('Failed to load profile from cache', error: e);
    }
  }

  /// Try loading questions from local cache
  void _tryLoadQuestionsFromCache() {
    try {
      final cached = _cache.getList(_cacheKeyQuestions);
      if (cached != null && cached.isNotEmpty) {
        _userQuestions = cached.map((json) => Question.fromJson(json)).toList();
        _logger.d('Loaded ${_userQuestions.length} questions from cache');
        _safeNotify();
      }
    } catch (e) {
      _logger.e('Failed to load questions from cache', error: e);
    }
  }

  /// Try loading answers from local cache
  void _tryLoadAnswersFromCache() {
    try {
      final cached = _cache.getList(_cacheKeyAnswers);
      if (cached != null && cached.isNotEmpty) {
        _userAnswers = cached.map((json) => Answer.fromJson(json)).toList();
        _logger.d('Loaded ${_userAnswers.length} answers from cache');
        _safeNotify();
      }
    } catch (e) {
      _logger.e('Failed to load answers from cache', error: e);
    }
  }

  /// Reset provider state
  void reset() {
    _userProfile = null;
    _userQuestions.clear();
    _userAnswers.clear();
    _isLoading = false;
    _isLoadingQuestions = false;
    _isLoadingAnswers = false;
    _isLoggingOut = false;
    _errorMessage = null;
    _questionsPage = 1;
    _answersPage = 1;
    _hasMoreQuestions = true;
    _hasMoreAnswers = true;
    _isLoadingMoreQuestions = false;
    _isLoadingMoreAnswers = false;
    _safeNotify();
  }
}
