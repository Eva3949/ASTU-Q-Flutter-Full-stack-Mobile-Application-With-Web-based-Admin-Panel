import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/leaderboard_user.dart';
import '../../domain/usecases/get_leaderboard_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../authentication/presentation/providers/authentication_provider.dart';

/// Leaderboard Provider
/// Manages leaderboard state and operations
class LeaderboardProvider extends ChangeNotifier {
  final GetLeaderboardUseCase _getLeaderboardUseCase;
  final Logger _logger;
  final AuthenticationProvider _authProvider;

  LeaderboardProvider(
    this._getLeaderboardUseCase,
    this._logger,
    this._authProvider,
  );

  // State variables
  List<LeaderboardUser> _leaderboardUsers = [];
  List<LeaderboardUser> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _selectedTimeFilter = 'all';
  String _selectedCategory = 'points';
  String? _searchQuery;

  // Getters
  List<LeaderboardUser> get leaderboardUsers => _leaderboardUsers;
  List<LeaderboardUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get selectedTimeFilter => _selectedTimeFilter;
  String get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  int get userCount => _leaderboardUsers.length;

  // Top 3 users
  List<LeaderboardUser> get top3Users => _leaderboardUsers.take(3).toList();

  // Current user rank (if available)
  int? get currentUserRank {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId == null) return null;
    final index = _leaderboardUsers.indexWhere(
      (user) => user.id == currentUserId,
    );
    return index != -1 ? index + 1 : null;
  }

  LeaderboardUser? get currentUser {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId == null) return null;
    try {
      return _leaderboardUsers.firstWhere((user) => user.id == currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// Load leaderboard data
  Future<void> loadLeaderboard({
    String? timeFilter,
    String? category,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _setLoading(true);
        _currentPage = 1;
        _hasMore = true;
        _leaderboardUsers.clear();
      } else {
        _setLoadingMore(true);
      }

      if (timeFilter != null) {
        _selectedTimeFilter = timeFilter;
      }
      if (category != null) {
        _selectedCategory = category;
      }

      _logger.d(
        'Loading leaderboard - Page: $_currentPage, Filter: $_selectedTimeFilter, Category: $_selectedCategory',
      );

      // Try to load with retry logic
      var retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          final result = await _getLeaderboardUseCase(
            GetLeaderboardParams(
              page: _currentPage,
              limit: 20,
              timeFilter: _selectedTimeFilter,
              category: _selectedCategory,
            ),
          );

          return result.fold(
            (failure) {
              _setError(_getErrorMessage(failure));
              _logger.e(
                'Failed to load leaderboard: ${failure.message}',
                error: failure,
              );
              return;
            },
            (users) {
              // Calculate ranks for users
              final rankedUsers = <LeaderboardUser>[];
              for (int i = 0; i < users.length; i++) {
                final user = users[i];
                final rank = refresh ? i + 1 : _leaderboardUsers.length + i + 1;
                rankedUsers.add(user.copyWith(rank: rank));
              }

              if (refresh) {
                _leaderboardUsers = rankedUsers;
              } else {
                _leaderboardUsers.addAll(rankedUsers);
              }

              _currentPage++;
              _hasMore = users.length >= 20;

              _logger.d('Loaded ${users.length} leaderboard users');
              return;
            },
          );
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            _setError('An unexpected error occurred');
            _logger.e(
              'Error loading leaderboard after $maxRetries retries',
              error: e,
            );
            return;
          }

          // Exponential backoff delay
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
          _logger.d('Retrying leaderboard load (attempt $retryCount)');
        }
      }
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  /// Load more leaderboard users
  Future<void> loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    // Prevent concurrent calls
    if (_isLoading) return;

    await loadLeaderboard(refresh: false);
  }

  /// Refresh leaderboard
  Future<void> refreshLeaderboard() async {
    await loadLeaderboard(refresh: true);
  }

  /// Change time filter
  Future<void> changeTimeFilter(String timeFilter) async {
    if (_selectedTimeFilter == timeFilter) return;

    await loadLeaderboard(timeFilter: timeFilter, refresh: true);
  }

  /// Change category
  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category) return;

    await loadLeaderboard(category: category, refresh: true);
  }

  /// Get user statistics
  Map<String, dynamic> getLeaderboardStats() {
    if (_leaderboardUsers.isEmpty) return {};

    final totalPoints = _leaderboardUsers.fold<int>(
      0,
      (sum, user) => sum + user.points,
    );

    final averagePoints = totalPoints / _leaderboardUsers.length;

    final topUserPoints = _leaderboardUsers.first.points;
    final lastUserPoints = _leaderboardUsers.last.points;

    final levels = _leaderboardUsers.map((user) => user.level).toList();
    final averageLevel = levels.reduce((a, b) => a + b) / levels.length;

    return {
      'totalUsers': _leaderboardUsers.length,
      'totalPoints': totalPoints,
      'averagePoints': averagePoints.round(),
      'topUserPoints': topUserPoints,
      'lastUserPoints': lastUserPoints,
      'averageLevel': averageLevel.toStringAsFixed(1),
      'currentUserRank': currentUserRank,
      'currentUser': currentUser,
    };
  }

  /// Get medal color for rank
  String getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return 'gold';
      case 2:
        return 'silver';
      case 3:
        return 'bronze';
      default:
        return 'none';
    }
  }

  /// Get rank badge icon
  String getRankBadgeIcon(int rank) {
    switch (rank) {
      case 1:
        return 'crown';
      case 2:
        return 'medal';
      case 3:
        return 'medal';
      default:
        return 'rank';
    }
  }

  /// Check if user is in top 3
  bool isTop3(int rank) {
    return rank <= 3;
  }

  /// Check if user is current user
  bool isCurrentUser(int userId) {
    final currentUserId = _authProvider.user?.id;
    return userId == currentUserId;
  }

  /// Get available time filters
  List<Map<String, String>> getAvailableTimeFilters() {
    return [
      {'key': 'all', 'label': 'All Time', 'description': 'All time rankings'},
      {
        'key': 'year',
        'label': 'This Year',
        'description': 'This year rankings',
      },
      {
        'key': 'month',
        'label': 'This Month',
        'description': 'This month rankings',
      },
      {
        'key': 'week',
        'label': 'This Week',
        'description': 'This week rankings',
      },
      {'key': 'today', 'label': 'Today', 'description': 'Today rankings'},
    ];
  }

  /// Get available categories
  List<Map<String, String>> getAvailableCategories() {
    return [
      {'key': 'points', 'label': 'Points', 'description': 'Total points'},
      {
        'key': 'questions',
        'label': 'Questions',
        'description': 'Most questions',
      },
      {'key': 'answers', 'label': 'Answers', 'description': 'Most answers'},
      {
        'key': 'best_answers',
        'label': 'Best Answers',
        'description': 'Most best answers',
      },
      {
        'key': 'upvotes',
        'label': 'Upvotes',
        'description': 'Most upvotes received',
      },
    ];
  }

  /// Get leaderboard title based on filters
  String getLeaderboardTitle() {
    final timeFilter = getAvailableTimeFilters().firstWhere(
      (filter) => filter['key'] == _selectedTimeFilter,
    );
    final category = getAvailableCategories().firstWhere(
      (cat) => cat['key'] == _selectedCategory,
    );

    return '${category['label']} - ${timeFilter['label']}';
  }

  /// Set searching state
  void _setSearching(bool searching) {
    if (_isSearching == searching) return;
    _isSearching = searching;
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Set loading more state
  void _setLoadingMore(bool loading) {
    if (_isLoadingMore == loading) return;
    _isLoadingMore = loading;
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    if (_errorMessage == error) return;
    _errorMessage = error;
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Unable to connect to server. Please check your internet connection and try again.';
      case ServerFailure:
        return failure.message.isNotEmpty
            ? failure.message
            : 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Session expired. Please login again.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'Leaderboard data not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Search users by name or username
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    try {
      _setSearching(true);
      _searchQuery = query.trim();

      _logger.d('Searching users with query: "$_searchQuery"');

      // Filter current leaderboard users based on search query
      final filteredUsers = _leaderboardUsers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(
          _searchQuery!.toLowerCase(),
        );
        return nameMatch;
      }).toList();

      _searchResults = filteredUsers;
      _logger.d('Found ${_searchResults.length} users matching search query');
    } catch (e) {
      _setError('Search failed. Please try again.');
      _logger.e('Error during search', error: e);
    } finally {
      _setSearching(false);
    }
  }

  /// Clear search results
  void clearSearch() {
    if (_searchResults.isEmpty && _searchQuery == null) return;

    _searchResults.clear();
    _searchQuery = null;
    _clearError();
    notifyListeners();

    _logger.d('Search cleared');
  }

  /// Reset provider state
  void reset() {
    _leaderboardUsers.clear();
    _searchResults.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _isSearching = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _selectedTimeFilter = 'all';
    _selectedCategory = 'points';
    _searchQuery = null;
    notifyListeners();
  }
}
