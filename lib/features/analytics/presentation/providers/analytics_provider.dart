import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/analytics_data.dart';
import '../../domain/usecases/get_analytics_overview_usecase.dart';
import '../../domain/usecases/get_daily_activity_usecase.dart';
import '../../domain/usecases/get_subject_distribution_usecase.dart';
import '../../domain/usecases/get_user_growth_usecase.dart';
import '../../domain/usecases/get_response_time_analytics_usecase.dart';
import '../../domain/usecases/get_top_users_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/types/either.dart';

/// Analytics Provider
/// Manages analytics data state and operations
@singleton
class AnalyticsProvider extends ChangeNotifier {
  final GetAnalyticsOverviewUseCase _getAnalyticsOverviewUseCase;
  final GetDailyActivityUseCase _getDailyActivityUseCase;
  final GetSubjectDistributionUseCase _getSubjectDistributionUseCase;
  final GetUserGrowthUseCase _getUserGrowthUseCase;
  final GetResponseTimeAnalyticsUseCase _getResponseTimeAnalyticsUseCase;
  final GetTopUsersUseCase _getTopUsersUseCase;
  final Logger _logger;

  AnalyticsProvider(
    this._getAnalyticsOverviewUseCase,
    this._getDailyActivityUseCase,
    this._getSubjectDistributionUseCase,
    this._getUserGrowthUseCase,
    this._getResponseTimeAnalyticsUseCase,
    this._getTopUsersUseCase,
    this._logger,
  );

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  DateTimeRange? _dateRange;

  // Analytics data
  AnalyticsOverview? _overview;
  List<DailyActivityData> _dailyActivity = [];
  List<SubjectDistributionData> _subjectDistribution = [];
  List<UserGrowthData> _userGrowth = [];
  List<ResponseTimeData> _responseTimeAnalytics = [];
  List<TopUserData> _topUsers = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTimeRange? get dateRange => _dateRange;
  AnalyticsOverview? get overview => _overview;
  List<DailyActivityData> get dailyActivity => _dailyActivity;
  List<SubjectDistributionData> get subjectDistribution => _subjectDistribution;
  List<UserGrowthData> get userGrowth => _userGrowth;
  List<ResponseTimeData> get responseTimeAnalytics => _responseTimeAnalytics;
  List<TopUserData> get topUsers => _topUsers;

  // Computed properties
  int get totalQuestions => _overview?.totalQuestions ?? 0;
  int get totalAnswers => _overview?.totalAnswers ?? 0;
  int get totalUsers => _overview?.totalUsers ?? 0;
  double get averageResponseTime => _overview?.averageResponseTime ?? 0.0;
  int get todayActivity => _overview?.todayActivity ?? 0;

  // Chart data getters
  List<FlSpot> get dailyActivitySpots {
    return _dailyActivity
        .map(
          (data) => FlSpot(
            data.date.millisecondsSinceEpoch.toDouble(),
            data.questionsCount.toDouble(),
          ),
        )
        .toList();
  }

  List<PieChartSectionData> get subjectDistributionSections {
    return _subjectDistribution
        .map(
          (data) => PieChartSectionData(
            color: getSubjectColor(data.subject),
            value: data.count.toDouble(),
            title: '${data.subject}\n${data.count}',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        )
        .toList();
  }

  List<FlSpot> get userGrowthSpots {
    return _userGrowth
        .map(
          (data) => FlSpot(
            data.date.millisecondsSinceEpoch.toDouble(),
            data.userCount.toDouble(),
          ),
        )
        .toList();
  }

  List<BarChartGroupData> get responseTimeBars {
    return _responseTimeAnalytics
        .map(
          (data) => BarChartGroupData(
            x: data.hour,
            barRods: [
              BarChartRodData(
                toY: data.averageTime.toDouble(),
                color: AppColors.primaryColor,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  /// Initialize analytics with default date range
  void initializeAnalytics() {
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    loadAnalyticsData();
  }

  /// Set date range and reload data
  void setDateRange(DateTimeRange newRange) {
    _dateRange = newRange;
    loadAnalyticsData();
  }

  /// Load all analytics data
  Future<void> loadAnalyticsData() async {
    if (_dateRange == null) {
      initializeAnalytics();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _logger.d('Loading analytics data for range: $_dateRange');

      // Load all data in parallel
      final results = await Future.wait<Either<Failure, dynamic>>([
        _getAnalyticsOverviewUseCase(
          GetAnalyticsOverviewParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          ),
        ),
        _getDailyActivityUseCase(
          GetDailyActivityParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          ),
        ),
        _getSubjectDistributionUseCase(
          GetSubjectDistributionParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          ),
        ),
        _getUserGrowthUseCase(
          GetUserGrowthParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          ),
        ),
        _getResponseTimeAnalyticsUseCase(
          GetResponseTimeAnalyticsParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
          ),
        ),
        _getTopUsersUseCase(
          GetTopUsersParams(
            startDate: _dateRange!.start,
            endDate: _dateRange!.end,
            limit: 10,
          ),
        ),
      ]);

      // Process results
      _overview = results[0].fold((failure) => null, (data) => data);
      _dailyActivity = results[1].fold((failure) => [], (data) => data);
      _subjectDistribution = results[2].fold((failure) => [], (data) => data);
      _userGrowth = results[3].fold((failure) => [], (data) => data);
      _responseTimeAnalytics = results[4].fold((failure) => [], (data) => data);
      _topUsers = results[5].fold((failure) => [], (data) => data);

      // Check for errors
      for (int i = 0; i < results.length; i++) {
        results[i].fold((failure) {
          _logger.e(
            'Failed to load analytics data ${i + 1}: ${failure.message}',
          );
          if (_errorMessage == null) {
            _setError('Some analytics data could not be loaded');
          }
        }, (data) => null);
      }

      _logger.d('Analytics data loaded successfully');
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error loading analytics data', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh analytics data
  Future<void> refreshAnalytics() async {
    await loadAnalyticsData();
  }

  /// Get daily activity for specific date range
  Future<List<DailyActivityData>> getDailyActivityForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _getDailyActivityUseCase(
        GetDailyActivityParams(startDate: startDate, endDate: endDate),
      );

      return result.fold((failure) => [], (data) => data);
    } catch (e) {
      _logger.e('Error getting daily activity', error: e);
      return [];
    }
  }

  /// Get subject distribution for pie chart
  Map<String, double> getSubjectDistributionPercentages() {
    if (_subjectDistribution.isEmpty) return {};

    final total = _subjectDistribution.fold<int>(
      0,
      (sum, data) => sum + data.count,
    );

    return Map.fromEntries(
      _subjectDistribution.map(
        (data) => MapEntry(
          data.subject,
          total > 0 ? (data.count / total) * 100 : 0.0,
        ),
      ),
    );
  }

  /// Get growth percentage
  double getUserGrowthPercentage() {
    if (_userGrowth.length < 2) return 0.0;

    final first = _userGrowth.first.userCount;
    final last = _userGrowth.last.userCount;

    if (first == 0) return 0.0;

    return ((last - first) / first) * 100;
  }

  /// Get average response time in hours
  double getAverageResponseTimeInHours() {
    if (_responseTimeAnalytics.isEmpty) return 0.0;

    final total = _responseTimeAnalytics.fold<double>(
      0.0,
      (sum, data) => sum + data.averageTime,
    );

    return total / _responseTimeAnalytics.length;
  }

  /// Get most active hour
  int getMostActiveHour() {
    if (_responseTimeAnalytics.isEmpty) return 0;

    final sorted = List<ResponseTimeData>.from(_responseTimeAnalytics)
      ..sort((a, b) => b.averageTime.compareTo(a.averageTime));

    return sorted.first.hour;
  }

  /// Get top subject
  String getTopSubject() {
    if (_subjectDistribution.isEmpty) return 'None';

    final sorted = List<SubjectDistributionData>.from(_subjectDistribution)
      ..sort((a, b) => b.count.compareTo(a.count));

    return sorted.first.subject;
  }

  /// Format date for charts
  String formatDateForChart(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Format large numbers
  String formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Format percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format response time
  String formatResponseTime(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      final days = (hours / 24).round();
      return '${days}d';
    }
  }

  /// Get subject color for charts
  Color getSubjectColor(String subject) {
    final colors = [
      AppColors.primaryColor,
      AppColors.successColor,
      AppColors.warningColor,
      AppColors.errorColor,
      AppColors.infoColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    final index = subject.hashCode % colors.length;
    return colors[index];
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
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
      case NetworkFailure:
        return 'No internet connection. Please check your network and try again.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return failure.message;
      case UnauthorizedFailure:
        return 'Session expired. Please login again.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'Analytics data not found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Reset provider state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _dateRange = null;
    _overview = null;
    _dailyActivity.clear();
    _subjectDistribution.clear();
    _userGrowth.clear();
    _responseTimeAnalytics.clear();
    _topUsers.clear();
    notifyListeners();
  }
}
