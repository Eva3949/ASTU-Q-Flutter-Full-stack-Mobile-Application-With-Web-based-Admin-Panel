import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/question.dart';
import '../../domain/entities/answer.dart';
import '../../domain/usecases/get_question_detail_usecase.dart';
import '../../domain/usecases/get_answers_usecase.dart';
import '../../domain/usecases/create_answer_usecase.dart';
import '../../domain/usecases/vote_answer_usecase.dart';
import '../../domain/usecases/vote_question_usecase.dart';
import '../../domain/usecases/mark_best_answer_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/api_service.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Question Detail Provider
/// Manages question detail and answer state
@singleton
class QuestionDetailProvider extends ChangeNotifier {
  final GetQuestionDetailUseCase _getQuestionDetailUseCase;
  final GetAnswersUseCase _getAnswersUseCase;
  final CreateAnswerUseCase _createAnswerUseCase;
  final VoteAnswerUseCase _voteAnswerUseCase;
  final VoteQuestionUseCase _voteQuestionUseCase;
  final MarkBestAnswerUseCase _markBestAnswerUseCase;
  final Logger _logger;
  final AuthenticationProvider _authProvider;
  final ApiService _apiService;
  final ProfileProvider _profileProvider;

  QuestionDetailProvider(
    this._getQuestionDetailUseCase,
    this._getAnswersUseCase,
    this._createAnswerUseCase,
    this._voteAnswerUseCase,
    this._voteQuestionUseCase,
    this._markBestAnswerUseCase,
    this._logger,
    this._authProvider,
    this._apiService,
    this._profileProvider,
  ) {
    _answerController.addListener(_onAnswerTextChanged);
  }

  void _onAnswerTextChanged() {
    _safeNotify();
  }

  // State variables
  Question? _question;
  List<Answer> _answers = [];
  bool _isLoading = false;
  bool _isLoadingAnswers = false;
  bool _isSubmittingAnswer = false;
  String? _errorMessage;
  String? _answerErrorMessage;
  final _answerController = TextEditingController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Getters
  Question? get question => _question;
  List<Answer> get answers => _answers;
  bool get isLoading => _isLoading;
  bool get isLoadingAnswers => _isLoadingAnswers;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  String? get errorMessage => _errorMessage;
  String? get answerErrorMessage => _answerErrorMessage;
  TextEditingController get answerController => _answerController;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get answerCount => _answers.length;
  bool get hasBestAnswer => _answers.any((answer) => answer.isBest);

  @override
  void dispose() {
    _answerController.removeListener(_onAnswerTextChanged);
    _answerController.dispose();
    super.dispose();
  }

  /// Load question details and answers
  Future<void> loadQuestionDetail(int questionId) async {
    try {
      // Clear existing state to avoid showing old question data
      _question = null;
      _answers = [];
      _errorMessage = null;
      _answerErrorMessage = null;
      _currentPage = 1;
      _hasMore = true;

      _setLoading(true);
      _clearError();

      _logger.d('Loading question detail for ID: $questionId');

      // Load question details
      final questionResult = await _getQuestionDetailUseCase(questionId);

      bool questionLoaded = false;
      questionResult.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to load question detail: ${failure.message}');
        },
        (question) {
          _question = question;
          questionLoaded = true;
          _logger.d('Question loaded: ${question.title}');
        },
      );

      // Only load answers if question was successfully loaded
      if (questionLoaded) {
        await _loadAnswers(questionId, refresh: true);
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error loading question detail', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Load answers for the question
  Future<void> _loadAnswers(int questionId, {bool refresh = false}) async {
    try {
      if (refresh) {
        _setLoadingAnswers(true);
        _currentPage = 1;
        _hasMore = true;
        _answers.clear();
      } else {
        _setLoadingMore(true);
      }

      _logger.d(
        'Loading answers for question ID: $questionId, page: $_currentPage',
      );

      final result = await _getAnswersUseCase(
        GetAnswersParams(questionId: questionId, page: _currentPage, limit: 10),
      );

      result.fold(
        (failure) {
          if (refresh) {
            _setAnswerError(_getErrorMessage(failure));
          }
          _logger.e('Failed to load answers: ${failure.message}');
        },
        (newAnswers) {
          if (refresh) {
            _answers = newAnswers;
          } else {
            _answers.addAll(newAnswers);
          }

          _currentPage++;
          _hasMore = newAnswers.length >= 10;

          // Sort answers: best answer first, then by votes
          _sortAnswers();

          _logger.d('Loaded ${newAnswers.length} answers');
        },
      );
    } catch (e) {
      _logger.e('Error loading answers', error: e);
    } finally {
      _setLoadingAnswers(false);
      _setLoadingMore(false);
    }
  }

  /// Load more answers (pagination)
  Future<void> loadMoreAnswers() async {
    if (_isLoadingMore || !_hasMore || _question == null) return;

    await _loadAnswers(_question!.id, refresh: false);
  }

  /// Vote on question
  Future<bool> voteQuestion(VoteType voteType) async {
    if (_question == null) return false;

    try {
      _logger.d('Voting on question ${_question!.id} with type: $voteType');

      final result = await _voteQuestionUseCase(
        VoteQuestionParams(questionId: _question!.id, voteType: voteType),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to vote on question: ${failure.message}');
          return false;
        },
        (updatedQuestion) {
          // Only update vote-related fields to preserve question content
          _question = _question!.copyWith(
            upvotes: updatedQuestion.upvotes,
            downvotes: updatedQuestion.downvotes,
            isUpvoted: updatedQuestion.isUpvoted,
            isDownvoted: updatedQuestion.isDownvoted,
          );
          _safeNotify();
          _logger.d('Successfully voted on question');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error voting on question', error: e);
      return false;
    }
  }

  /// Vote on answer
  Future<bool> voteAnswer(int answerId, VoteType voteType) async {
    try {
      _logger.d('Voting on answer $answerId with type: $voteType');

      // Find the answer in the list for optimistic update
      final index = _answers.indexWhere((answer) => answer.id == answerId);

      Answer? originalAnswer;
      if (index != -1) {
        originalAnswer = _answers[index];
        // Optimistic update - update UI immediately
        if (voteType == VoteType.upvote) {
          _answers[index] = _answers[index].copyWith(
            isUpvoted: !_answers[index].isUpvoted,
            upvotes: _answers[index].isUpvoted
                ? _answers[index].upvotes - 1
                : _answers[index].upvotes + 1,
          );
        }
        _safeNotify();
      }

      final result = await _voteAnswerUseCase(
        VoteAnswerParams(answerId: answerId, voteType: voteType),
      );

      return result.fold(
        (failure) {
          // Revert on error
          if (index != -1 && originalAnswer != null) {
            _answers[index] = originalAnswer;
            _safeNotify();
          }
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to vote on answer: ${failure.message}');
          return false;
        },
        (updatedAnswer) async {
          // Update the answer in the list with server response
          _updateAnswerInList(updatedAnswer);
          _logger.d('Successfully voted on answer');

          // Award points for receiving an upvote (only if upvoted)
          if (voteType == VoteType.upvote && !originalAnswer!.isUpvoted) {
            final userId = _authProvider.user?.id;
            if (userId != null) {
              try {
                await _apiService.updateUserPoints(
                  userId: userId,
                  points: 2, // 2 points for receiving an upvote
                  action: 'upvote',
                );
                _logger.d('Points awarded for upvote');
                // Refresh profile to update points display
                _profileProvider.refreshProfile();
              } catch (e) {
                _logger.e('Failed to award points for upvote', error: e);
              }
            }
          }

          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error voting on answer', error: e);
      return false;
    }
  }

  /// Submit answer
  Future<bool> submitAnswer() async {
    if (_question == null) return false;

    final content = _answerController.text.trim();
    if (content.isEmpty) {
      _setAnswerError('Please enter your answer');
      return false;
    }

    try {
      _setSubmittingAnswer(true);
      _clearAnswerError();

      _logger.d('Submitting answer for question ${_question!.id}');

      final result = await _createAnswerUseCase(
        CreateAnswerParams(
          questionId: _question!.id,
          content: content,
          userId: _authProvider.user?.id?.toString(),
        ),
      );

      return result.fold(
        (failure) {
          _setAnswerError(_getErrorMessage(failure));
          _logger.e('Failed to submit answer: ${failure.message}');
          return false;
        },
        (newAnswer) async {
          _answers.insert(0, newAnswer); // Add new answer at the top
          _answerController.clear();
          _sortAnswers(); // Re-sort answers
          _safeNotify();
          _logger.d('Answer submitted successfully');

          // Award points for answering a question
          final userId = _authProvider.user?.id;
          if (userId != null) {
            try {
              await _apiService.updateUserPoints(
                userId: userId,
                points: 5, // 5 points for answering a question
                action: 'answer',
              );
              _logger.d('Points awarded for answering question');
              // Refresh profile to update points display
              _profileProvider.refreshProfile();
            } catch (e) {
              _logger.e('Failed to award points for answer', error: e);
            }
          }

          return true;
        },
      );
    } catch (e) {
      _setAnswerError('An unexpected error occurred');
      _logger.e('Error submitting answer', error: e);
      return false;
    } finally {
      _setSubmittingAnswer(false);
    }
  }

  /// Mark answer as best answer
  Future<bool> markBestAnswer(int answerId) async {
    if (_question == null) return false;
    try {
      _logger.d('Marking answer $answerId as best answer');

      final result = await _markBestAnswerUseCase(
        MarkBestAnswerParams(answerId: answerId, questionId: _question!.id),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to mark best answer: ${failure.message}');
          return false;
        },
        (success) async {
          // Update all answers to reflect the best answer change
          _updateBestAnswer(answerId);
          _logger.d('Successfully marked best answer');

          // Award points for best answer
          final userId = _authProvider.user?.id;
          if (userId != null) {
            try {
              await _apiService.updateUserPoints(
                userId: userId,
                points: 20, // 20 points for best answer
                action: 'best_answer',
              );
              _logger.d('Points awarded for best answer');
              // Refresh profile to update points display
              _profileProvider.refreshProfile();
            } catch (e) {
              _logger.e('Failed to award points for best answer', error: e);
            }
          }

          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error marking best answer', error: e);
      return false;
    }
  }

  /// Update answer in the list
  void _updateAnswerInList(Answer updatedAnswer) {
    final index = _answers.indexWhere(
      (answer) => answer.id == updatedAnswer.id,
    );
    if (index != -1) {
      _answers[index] = updatedAnswer;
      _sortAnswers(); // Re-sort to maintain order
      _safeNotify();
    }
  }

  /// Update best answer
  void _updateBestAnswer(int bestAnswerId) {
    for (int i = 0; i < _answers.length; i++) {
      _answers[i] = _answers[i].copyWith(
        isBest: _answers[i].id == bestAnswerId,
      );
    }
    _sortAnswers(); // Re-sort to put best answer first
    _safeNotify();
  }

  /// Sort answers (best answer first, then by votes)
  void _sortAnswers() {
    _answers.sort((a, b) {
      // Best answers always come first
      if (a.isBest && !b.isBest) return -1;
      if (!a.isBest && b.isBest) return 1;

      // Then sort by vote count (descending)
      final aVotes = a.upvotes - a.downvotes;
      final bVotes = b.upvotes - b.downvotes;

      if (aVotes != bVotes) {
        return bVotes.compareTo(aVotes); // Descending
      }

      // Finally sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Get answer by ID
  Answer? getAnswerById(int id) {
    try {
      return _answers.firstWhere((answer) => answer.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get question statistics
  Map<String, int> getQuestionStats() {
    if (_question == null) return {};

    return {
      'upvotes': _question!.upvotes,
      'downvotes': _question!.downvotes,
      'answers': _answers.length,
      'bestAnswer': hasBestAnswer ? 1 : 0,
    };
  }

  /// Get answer statistics
  Map<String, int> getAnswerStats() {
    int totalUpvotes = 0;
    int totalDownvotes = 0;

    for (final answer in _answers) {
      totalUpvotes += answer.upvotes;
      totalDownvotes += answer.downvotes;
    }

    return {
      'total': _answers.length,
      'upvotes': totalUpvotes,
      'downvotes': totalDownvotes,
      'bestAnswer': hasBestAnswer ? 1 : 0,
    };
  }

  /// Clear answer input
  void clearAnswerInput() {
    _answerController.clear();
    _clearAnswerError();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    _safeNotify();
  }

  /// Set loading answers state
  void _setLoadingAnswers(bool loading) {
    if (_isLoadingAnswers == loading) return;
    _isLoadingAnswers = loading;
    _safeNotify();
  }

  /// Set loading more state
  void _setLoadingMore(bool loading) {
    if (_isLoadingMore == loading) return;
    _isLoadingMore = loading;
    _safeNotify();
  }

  /// Set submitting answer state
  void _setSubmittingAnswer(bool submitting) {
    if (_isSubmittingAnswer == submitting) return;
    _isSubmittingAnswer = submitting;
    _safeNotify();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _safeNotify();
  }

  /// Set answer error message
  void _setAnswerError(String error) {
    _answerErrorMessage = error;
    _safeNotify();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotify();
  }

  /// Clear answer error message
  void _clearAnswerError() {
    if (_answerErrorMessage == null) return;
    _answerErrorMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
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
        return 'Please login to continue.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'Question not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Reset provider state
  void reset() {
    _question = null;
    _answers.clear();
    _isLoading = false;
    _isLoadingAnswers = false;
    _isSubmittingAnswer = false;
    _errorMessage = null;
    _answerErrorMessage = null;
    _answerController.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _safeNotify();
  }
}
