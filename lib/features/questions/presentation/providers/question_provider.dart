import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import '../../domain/usecases/filter_questions_by_subject_usecase.dart';
import '../../domain/usecases/vote_question_usecase.dart';
import '../../domain/usecases/vote_answer_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/storage/local_cache_service.dart';

/// Question Provider
/// Manages question feed state and operations
@singleton
class QuestionProvider extends ChangeNotifier {
  final GetQuestionsUseCase _getQuestionsUseCase;
  final FilterQuestionsBySubjectUseCase _filterQuestionsBySubjectUseCase;
  final VoteQuestionUseCase _voteQuestionUseCase;
  final Logger _logger;
  final LocalCacheService _cache;

  static const String _cacheKey = 'cache_questions';

  QuestionProvider(
    this._getQuestionsUseCase,
    this._filterQuestionsBySubjectUseCase,
    this._voteQuestionUseCase,
    this._logger,
    this._cache,
  ) {
    _loadQuestions();
  }

  // State variables
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedSubject;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Getters
  List<Question> get questions =>
      _filteredQuestions.isEmpty ? _questions : _filteredQuestions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSubject => _selectedSubject;
  bool get hasMore => _hasMore;
  bool get isSearching => _searchQuery.isNotEmpty || _selectedSubject != null;
  int get questionCount => questions.length;

  /// Load initial questions
  Future<void> _loadQuestions() async {
    try {
      _setLoading(true);
      _clearError();

      _logger.d('Loading initial questions...');

      final result = await _getQuestionsUseCase(
        GetQuestionsParams(page: 1, limit: 20),
      );

      result.fold(
        (failure) {
          _logger.e('Failed to load questions: ${failure.message}');
          _tryLoadFromCache();
          if (_questions.isEmpty) {
            _setError(_getErrorMessage(failure));
          }
        },
        (questions) {
          _questions = questions;
          _currentPage = 1;
          _hasMore = questions.length >= 20;
          _saveQuestionsToCache();
          _logger.d('Loaded ${questions.length} questions');
        },
      );
    } catch (e) {
      _logger.e('Error loading questions', error: e);
      _tryLoadFromCache();
      if (_questions.isEmpty) {
        _setError('An unexpected error occurred');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh questions list
  Future<void> refreshQuestions() async {
    try {
      _setRefreshing(true);
      _clearError();

      _logger.d('Refreshing questions...');

      final result = await _getQuestionsUseCase(
        GetQuestionsParams(page: 1, limit: 20),
      );

      result.fold(
        (failure) {
          _logger.e('Failed to refresh questions: ${failure.message}');
          _tryLoadFromCache();
          if (_questions.isEmpty) {
            _setError(_getErrorMessage(failure));
          }
        },
        (questions) {
          _questions = questions;
          _currentPage = 1;
          _hasMore = questions.length >= 20;
          // Apply current filters if any
          _applyCurrentFilters();
          _saveQuestionsToCache();
          _logger.d('Refreshed ${questions.length} questions');
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error refreshing questions', error: e);
    } finally {
      _setRefreshing(false);
    }
  }

  /// Load more questions (pagination)
  Future<void> loadMoreQuestions() async {
    if (_isLoadingMore || !_hasMore || isSearching) return;

    try {
      _setLoadingMore(true);

      _logger.d('Loading more questions (page ${_currentPage + 1})...');

      final result = await _getQuestionsUseCase(
        GetQuestionsParams(page: _currentPage + 1, limit: 20),
      );

      result.fold(
        (failure) {
          _logger.e('Failed to load more questions: ${failure.message}');
        },
        (newQuestions) {
          if (newQuestions.isNotEmpty) {
            _questions.addAll(newQuestions);
            _currentPage++;
            _hasMore = newQuestions.length >= 20;
            // Apply current filters if any
            _applyCurrentFilters();
            _logger.d('Loaded ${newQuestions.length} more questions');
          } else {
            _hasMore = false;
          }
        },
      );
    } catch (e) {
      _logger.e('Error loading more questions', error: e);
    } finally {
      _setLoadingMore(false);
    }
  }

  /// Search questions by tags
  Future<void> searchQuestions(String query) async {
    if (query.trim().isEmpty) {
      _clearSearch();
      return;
    }

    try {
      _setLoading(true);
      _clearError();
      _searchQuery = query.trim().toLowerCase();

      _logger.d('Searching questions by tag: "$query"');

      // Filter questions by tags client-side
      _filteredQuestions = _questions.where((question) {
        // Check if any tag matches the search query (case-insensitive)
        return question.tags.any(
          (tag) =>
              tag.toLowerCase().contains(_searchQuery) ||
              _searchQuery.contains(tag.toLowerCase()),
        );
      }).toList();

      _logger.d(
        'Found ${_filteredQuestions.length} questions with matching tags',
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error searching questions by tags', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Filter questions by subject
  Future<void> filterBySubject(String? subject) async {
    if (subject == null || subject.isEmpty) {
      _clearFilter();
      return;
    }

    try {
      _setLoading(true);
      _clearError();
      _selectedSubject = subject;

      _logger.d('Filtering questions by subject: "$subject"');

      final result = await _filterQuestionsBySubjectUseCase(
        FilterQuestionsParams(subject: subject, page: 1, limit: 20),
      );

      result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to filter questions: ${failure.message}');
        },
        (questions) {
          _filteredQuestions = questions;
          _logger.d(
            'Filtered ${questions.length} questions for subject "$subject"',
          );
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error filtering questions', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Clear search and filters
  void clearSearchAndFilters() {
    _clearSearch();
    _clearFilter();
    notifyListeners();
  }

  /// Clear search
  void _clearSearch() {
    _searchQuery = '';
    if (_selectedSubject == null) {
      _filteredQuestions = [];
    } else {
      // Re-apply subject filter if active
      filterBySubject(_selectedSubject);
    }
  }

  /// Clear filter
  void _clearFilter() {
    _selectedSubject = null;
    if (_searchQuery.isEmpty) {
      _filteredQuestions = [];
    } else {
      // Re-apply search if active
      searchQuestions(_searchQuery);
    }
  }

  /// Apply current filters
  void _applyCurrentFilters() {
    if (_searchQuery.isNotEmpty) {
      searchQuestions(_searchQuery);
    } else if (_selectedSubject != null) {
      filterBySubject(_selectedSubject!);
    }
  }

  /// Vote on a question
  Future<bool> voteQuestion(int questionId, VoteType voteType) async {
    try {
      _logger.d('Voting on question $questionId with type: $voteType');

      // Find the question in the list for optimistic update
      final mainIndex = _questions.indexWhere((q) => q.id == questionId);
      final filteredIndex = _filteredQuestions.indexWhere(
        (q) => q.id == questionId,
      );

      Question? originalQuestion;
      Question? originalFilteredQuestion;

      if (mainIndex != -1) {
        originalQuestion = _questions[mainIndex];
        // Optimistic update - update UI immediately
        if (voteType == VoteType.upvote) {
          _questions[mainIndex] = _questions[mainIndex].copyWith(
            isUpvoted: !_questions[mainIndex].isUpvoted,
            upvotes: _questions[mainIndex].isUpvoted
                ? _questions[mainIndex].upvotes - 1
                : _questions[mainIndex].upvotes + 1,
          );
        }
      }

      if (filteredIndex != -1) {
        originalFilteredQuestion = _filteredQuestions[filteredIndex];
        // Optimistic update for filtered list
        if (voteType == VoteType.upvote) {
          _filteredQuestions[filteredIndex] = _filteredQuestions[filteredIndex]
              .copyWith(
                isUpvoted: !_filteredQuestions[filteredIndex].isUpvoted,
                upvotes: _filteredQuestions[filteredIndex].isUpvoted
                    ? _filteredQuestions[filteredIndex].upvotes - 1
                    : _filteredQuestions[filteredIndex].upvotes + 1,
              );
        }
      }

      if (mainIndex != -1 || filteredIndex != -1) {
        notifyListeners();
      }

      final result = await _voteQuestionUseCase(
        VoteQuestionParams(questionId: questionId, voteType: voteType),
      );

      return result.fold(
        (failure) {
          // Revert on error
          if (mainIndex != -1 && originalQuestion != null) {
            _questions[mainIndex] = originalQuestion;
          }
          if (filteredIndex != -1 && originalFilteredQuestion != null) {
            _filteredQuestions[filteredIndex] = originalFilteredQuestion;
          }
          if (mainIndex != -1 || filteredIndex != -1) {
            notifyListeners();
          }
          _logger.e('Failed to vote on question: ${failure.message}');
          return false;
        },
        (updatedQuestion) {
          // Update the question in the list with server response
          _updateQuestionInList(updatedQuestion);
          _logger.d('Successfully voted on question $questionId');
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error voting on question', error: e);
      return false;
    }
  }

  /// Update question in the list
  void _updateQuestionInList(Question updatedQuestion) {
    // Update in main questions list - only update vote-related fields
    final mainIndex = _questions.indexWhere((q) => q.id == updatedQuestion.id);
    if (mainIndex != -1) {
      _questions[mainIndex] = _questions[mainIndex].copyWith(
        upvotes: updatedQuestion.upvotes,
        downvotes: updatedQuestion.downvotes,
        isUpvoted: updatedQuestion.isUpvoted,
        isDownvoted: updatedQuestion.isDownvoted,
      );
    }

    // Update in filtered questions list - only update vote-related fields
    final filteredIndex = _filteredQuestions.indexWhere(
      (q) => q.id == updatedQuestion.id,
    );
    if (filteredIndex != -1) {
      _filteredQuestions[filteredIndex] = _filteredQuestions[filteredIndex]
          .copyWith(
            upvotes: updatedQuestion.upvotes,
            downvotes: updatedQuestion.downvotes,
            isUpvoted: updatedQuestion.isUpvoted,
            isDownvoted: updatedQuestion.isDownvoted,
          );
    }

    notifyListeners();
  }

  /// Get available subjects
  List<String> getAvailableSubjects() {
    final subjects = <String>{};
    for (final question in _questions) {
      if (question.subject.isNotEmpty) {
        subjects.add(question.subject);
      }
    }
    return subjects.toList()..sort();
  }

  /// Get question by ID
  Question? getQuestionById(int id) {
    try {
      return questions.firstWhere((question) => question.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get questions statistics
  Map<String, int> getQuestionsStats() {
    final stats = <String, int>{};

    // Count by subject
    final subjectCounts = <String, int>{};
    for (final question in _questions) {
      subjectCounts[question.subject] =
          (subjectCounts[question.subject] ?? 0) + 1;
    }

    stats['total'] = _questions.length;
    stats['subjects'] = subjectCounts.length;
    stats['withAnswers'] = _questions.where((q) => q.answerCount > 0).length;
    stats['unanswered'] = _questions.where((q) => q.answerCount == 0).length;

    return stats;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set refreshing state
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  /// Set loading more state
  void _setLoadingMore(bool loadingMore) {
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure _:
        return 'Server error. Please try again later.';
      case ValidationFailure _:
        return failure.message;
      case UnauthorizedFailure _:
        return 'Please login to continue.';
      case TimeoutFailure _:
        return 'Request timeout. Please try again.';
      case NotFoundFailure _:
        return 'No questions found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Save questions to local cache
  void _saveQuestionsToCache() {
    try {
      final data = _questions.map((q) => q.toJson()).toList();
      _cache.saveList(_cacheKey, data);
      _logger.d('Saved ${_questions.length} questions to cache');
    } catch (e) {
      _logger.e('Failed to save questions to cache', error: e);
    }
  }

  /// Try loading questions from local cache
  void _tryLoadFromCache() {
    try {
      final cached = _cache.getList(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _questions = cached.map((json) => Question.fromJson(json)).toList();
        _clearError(); // Clear error when cache is loaded
        _logger.d('Loaded ${_questions.length} questions from cache');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to load questions from cache', error: e);
    }
  }

  /// Reset provider state
  void reset() {
    _questions = [];
    _filteredQuestions = [];
    _isLoading = false;
    _isRefreshing = false;
    _errorMessage = null;
    _searchQuery = '';
    _selectedSubject = null;
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();
  }
}
