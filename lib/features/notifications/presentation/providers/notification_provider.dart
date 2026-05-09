import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/notification.dart' as entity;
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/notifications/notification_service.dart';

/// Notification Provider
/// Manages notifications state and operations
@singleton
class NotificationProvider extends ChangeNotifier {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final Logger _logger;
  final LocalCacheService _cache;
  final NotificationService _notificationService;

  static const String _cacheKey = 'cache_notifications';
  Timer? _pollingTimer;
  bool _isPolling = false;

  NotificationProvider(
    this._getNotificationsUseCase,
    this._markNotificationReadUseCase,
    this._markAllNotificationsReadUseCase,
    this._deleteNotificationUseCase,
    this._logger,
    this._cache,
    this._notificationService,
  ) {
    // Start polling when provider is initialized
    startPolling();
  }

  // State variables
  List<entity.Notification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  String _selectedFilter = 'all';

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Start periodic polling for notifications
  void startPolling({int intervalSeconds = 30}) {
    if (_isPolling) return;
    _isPolling = true;
    _logger.d('Starting notification polling every $intervalSeconds seconds');
    _pollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      _pollNotifications();
    });
  }

  /// Stop periodic polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _logger.d('Stopped notification polling');
  }

  /// Internal poll method that doesn't trigger loading state if we already have data
  Future<void> _pollNotifications() async {
    try {
      _logger.d('Polling for new notifications...');
      final result = await _getNotificationsUseCase(
        GetNotificationsParams(page: 1, limit: 20),
      );

      result.fold((failure) => _logger.e('Polling failed: ${failure.message}'), (
        newNotifications,
      ) {
        if (newNotifications.isEmpty) return;

        // Check for actually new AND unread notifications (by ID and isRead status)
        final existingIds = _notifications.map((n) => n.id).toSet();
        final brandNewUnreadNotifications = newNotifications
            .where((n) => !existingIds.contains(n.id) && !n.isRead)
            .toList();

        if (brandNewUnreadNotifications.isNotEmpty) {
          _logger.i(
            'Found ${brandNewUnreadNotifications.length} new unread notifications',
          );

          // Trigger system notifications only for unread ones
          for (final notification in brandNewUnreadNotifications) {
            _notificationService.showNotification(
              id: notification.id,
              title: notification.title,
              body: notification.message,
              payload: notification.type,
            );
          }

          // Update local state: merge and sort
          final merged = [...brandNewUnreadNotifications, ..._notifications];
          // Remove duplicates just in case
          final seen = <int>{};
          _notifications = merged.where((n) => seen.add(n.id)).toList();

          // Sort by date
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _saveNotificationsToCache();
          _safeNotify();
        }
      });
    } catch (e) {
      _logger.e('Error during notification polling', error: e);
    }
  }

  // Safe notify helper
  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Getters
  List<entity.Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String get selectedFilter => _selectedFilter;
  int get notificationCount => _notifications.length;

  // Filtered notifications
  List<entity.Notification> get filteredNotifications {
    var filtered = List<entity.Notification>.from(_notifications);

    // Apply filter
    switch (_selectedFilter) {
      case 'unread':
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case 'read':
        filtered = filtered.where((n) => n.isRead).toList();
        break;
      case 'questions':
        filtered = filtered
            .where(
              (n) =>
                  n.type == 'question' ||
                  n.type == 'question_answered' ||
                  n.type == 'answer',
            )
            .toList();
        break;
      case 'answers':
        filtered = filtered
            .where(
              (n) =>
                  n.type == 'answer' ||
                  n.type == 'answer_upvoted' ||
                  n.type == 'vote',
            )
            .toList();
        break;
      case 'achievements':
        filtered = filtered
            .where((n) => n.type.startsWith('achievement'))
            .toList();
        break;
      case 'system':
        filtered = filtered.where((n) => n.type.startsWith('system')).toList();
        break;
      case 'all':
      default:
        // No filtering
        break;
    }

    // Sort by creation time (most recent first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  // Unread notifications count
  int get unreadNotificationsCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Get notifications by type
  Map<String, int> getNotificationsByType() {
    final Map<String, int> typeCounts = {};

    for (final notification in _notifications) {
      typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
    }

    return typeCounts;
  }

  /// Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        _setLoading(true);
        _currentPage = 1;
        _hasMore = true;
        _notifications = [];
      } else {
        _setLoadingMore(true);
      }

      _logger.d('Loading notifications - Page: $_currentPage');

      final result = await _getNotificationsUseCase(
        GetNotificationsParams(page: _currentPage, limit: 20),
      );

      result.fold(
        (failure) {
          _logger.e('Failed to load notifications: ${failure.message}');
          _tryLoadFromCache();
          if (_notifications.isEmpty) {
            _setError(_getErrorMessage(failure));
          }
        },
        (notifications) {
          if (refresh) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }

          _currentPage++;
          _hasMore = notifications.length >= 20;
          _saveNotificationsToCache();

          _logger.d('Loaded ${notifications.length} notifications');
        },
      );
    } catch (e) {
      _logger.e('Error loading notifications', error: e);
      _tryLoadFromCache();
      if (_notifications.isEmpty) {
        _setError('An unexpected error occurred');
      }
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  /// Load more notifications
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    await loadNotifications(refresh: false);
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      _logger.d('Marking notification $notificationId as read');

      final result = await _markNotificationReadUseCase(
        MarkNotificationReadParams(notificationId: notificationId),
      );

      return result.fold(
        (failure) {
          _logger.e('Failed to mark notification as read: ${failure.message}');
          return false;
        },
        (success) {
          // Update local state
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
            );
            _safeNotify();
          }

          _logger.d('Notification marked as read successfully');
          return true;
        },
      );
    } catch (e) {
      _logger.e('Error marking notification as read', error: e);
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      _logger.d('Marking all notifications as read');

      final result = await _markAllNotificationsReadUseCase();

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e(
            'Failed to mark all notifications as read: ${failure.message}',
          );
          return false;
        },
        (success) {
          // Update local state
          for (int i = 0; i < _notifications.length; i++) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
          _safeNotify();

          _logger.d('All notifications marked as read successfully');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error marking all notifications as read', error: e);
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      _logger.d('Deleting notification $notificationId');

      final result = await _deleteNotificationUseCase(
        DeleteNotificationParams(notificationId: notificationId),
      );

      return result.fold(
        (failure) {
          _setError(_getErrorMessage(failure));
          _logger.e('Failed to delete notification: ${failure.message}');
          return false;
        },
        (success) {
          // Remove from local state
          _notifications.removeWhere((n) => n.id == notificationId);
          _safeNotify();

          _logger.d('Notification deleted successfully');
          return true;
        },
      );
    } catch (e) {
      _setError('An unexpected error occurred');
      _logger.e('Error deleting notification', error: e);
      return false;
    }
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _safeNotify();
  }

  /// Get notification by ID
  entity.Notification? getNotificationById(int notificationId) {
    try {
      return _notifications.firstWhere((n) => n.id == notificationId);
    } catch (e) {
      return null;
    }
  }

  /// Get available filters
  List<Map<String, dynamic>> getAvailableFilters() {
    return [
      {
        'key': 'all',
        'label': 'All',
        'icon': Icons.notifications,
        'count': _notifications.length,
      },
      {
        'key': 'unread',
        'label': 'Unread',
        'icon': Icons.mark_email_unread,
        'count': unreadNotificationsCount,
      },
      {
        'key': 'read',
        'label': 'Read',
        'icon': Icons.mark_email_read,
        'count': _notifications.where((n) => n.isRead).length,
      },
      {
        'key': 'questions',
        'label': 'Questions',
        'icon': Icons.help_outline,
        'count': _notifications
            .where(
              (n) =>
                  n.type == 'question' ||
                  n.type == 'question_answered' ||
                  n.type == 'answer',
            )
            .length,
      },
      {
        'key': 'answers',
        'label': 'Answers',
        'icon': Icons.comment,
        'count': _notifications
            .where(
              (n) =>
                  n.type == 'answer' ||
                  n.type == 'answer_upvoted' ||
                  n.type == 'vote',
            )
            .length,
      },
      {
        'key': 'achievements',
        'label': 'Achievements',
        'icon': Icons.emoji_events,
        'count': _notifications
            .where((n) => n.type.startsWith('achievement'))
            .length,
      },
      {
        'key': 'system',
        'label': 'System',
        'icon': Icons.settings,
        'count': _notifications
            .where((n) => n.type.startsWith('system'))
            .length,
      },
    ];
  }

  /// Format timestamp
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (timestamp.year == now.year) {
      return '${timestamp.day}/${timestamp.month}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get notification icon
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'question':
        return Icons.help_outline;
      case 'question_answered':
        return Icons.question_answer;
      case 'answer':
        return Icons.comment;
      case 'answer_upvoted':
        return Icons.thumb_up;
      case 'answer_accepted':
        return Icons.check_circle;
      case 'achievement_level':
        return Icons.emoji_events;
      case 'achievement_points':
        return Icons.stars;
      case 'achievement_badge':
        return Icons.military_tech;
      case 'system_update':
        return Icons.system_update;
      case 'system_maintenance':
        return Icons.build;
      case 'system_announcement':
        return Icons.campaign;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color
  Color getNotificationColor(String type) {
    switch (type) {
      case 'question':
        return AppColors.infoColor;
      case 'question_answered':
        return AppColors.successColor;
      case 'answer':
        return AppColors.primaryColor;
      case 'answer_upvoted':
        return AppColors.successColor;
      case 'answer_accepted':
        return AppColors.successColor;
      case 'achievement_level':
      case 'achievement_points':
      case 'achievement_badge':
        return AppColors.warningColor;
      case 'system_update':
      case 'system_maintenance':
      case 'system_announcement':
        return AppColors.textSecondary;
      case 'follow':
        return AppColors.infoColor;
      case 'mention':
        return AppColors.primaryColor;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get navigation route for notification
  String? getNavigationRoute(entity.Notification notification) {
    switch (notification.type) {
      case 'question':
      case 'question_answered':
      case 'answer':
      case 'answer_upvoted':
      case 'answer_accepted':
      case 'mention':
      case 'system':
      case 'vote':
        return AppRoutes.questionDetail;
      case 'achievement_level':
      case 'achievement_points':
      case 'achievement_badge':
      case 'follow':
        return AppRoutes.profile;
      default:
        return null;
    }
  }

  /// Get navigation arguments for notification
  Map<String, dynamic>? getNavigationArguments(
    entity.Notification notification,
  ) {
    switch (notification.type) {
      case 'question':
      case 'question_answered':
      case 'answer':
      case 'answer_upvoted':
      case 'answer_accepted':
      case 'mention':
      case 'system':
      case 'vote':
        if (notification.relatedId != null) {
          return {RouteArguments.questionId: notification.relatedId};
        }
        break;
      case 'follow':
        if (notification.relatedId != null) {
          return {'userId': notification.relatedId};
        }
        break;
      default:
        return null;
    }
    return null;
  }

  /// Check if notification is actionable
  bool isActionable(entity.Notification notification) {
    return getNavigationRoute(notification) != null;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }

  /// Set loading more state
  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
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
        return 'Session expired. Please login again.';
      case TimeoutFailure:
        return 'Request timeout. Please try again.';
      case NotFoundFailure:
        return 'No notifications found.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Save notifications to local cache
  void _saveNotificationsToCache() {
    try {
      final data = _notifications.map((n) => n.toJson()).toList();
      _cache.saveList(_cacheKey, data);
      _logger.d('Saved ${_notifications.length} notifications to cache');
    } catch (e) {
      _logger.e('Failed to save notifications to cache', error: e);
    }
  }

  /// Try loading notifications from local cache
  void _tryLoadFromCache() {
    try {
      final cached = _cache.getList(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        _notifications = cached
            .map((json) => entity.Notification.fromJson(json))
            .toList();
        _logger.d('Loaded ${_notifications.length} notifications from cache');
        _safeNotify();
      }
    } catch (e) {
      _logger.e('Failed to load notifications from cache', error: e);
    }
  }

  /// Reset provider state
  void reset() {
    _notifications = [];
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    _selectedFilter = 'all';
    _safeNotify();
  }
}
