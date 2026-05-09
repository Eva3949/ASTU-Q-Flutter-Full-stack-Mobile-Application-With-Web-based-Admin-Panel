import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/types/either.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final DioClient _dioClient;
  final Logger _logger;
  final SecureStorage _secureStorage;
  static const String _baseUrl = 'https://evadevstudio.com/sami';

  NotificationRepositoryImpl(
    this._dioClient,
    this._logger,
    this._secureStorage,
  );

  @override
  Future<Either<Failure, List<Notification>>> getNotifications(
    GetNotificationsParams params,
  ) async {
    try {
      final userId = await _secureStorage.getUserId();
      final response = await _dioClient.get(
        '$_baseUrl/get_notifications.php',
        queryParameters: {
          'user_id': userId,
          'page': params.page,
          'limit': params.limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dynamic rawData = response.data['data'];
        final List<dynamic> data =
            (rawData is Map && rawData.containsKey('notifications'))
            ? rawData['notifications']
            : (rawData is List ? rawData : []);

        final notifications = data
            .map((item) {
              try {
                return Notification.fromJson(item);
              } catch (e) {
                _logger.e('Error parsing single notification: $item', error: e);
                return null;
              }
            })
            .where((n) => n != null)
            .cast<Notification>()
            .toList();
        return Either.right(notifications);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to fetch notifications',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error fetching notifications', error: e);
      return Either.left(ServerFailure('Failed to fetch notifications'));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(
    MarkNotificationReadParams params,
  ) async {
    try {
      final userId = await _secureStorage.getUserId();
      final response = await _dioClient.post(
        '$_baseUrl/mark_notification_read.php',
        data: {'notification_id': params.notificationId, 'user_id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Either.right(null);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to mark notification as read',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error marking notification as read', error: e);
      return Either.left(ServerFailure('Failed to mark notification as read'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead() async {
    try {
      final userId = await _secureStorage.getUserId();
      final response = await _dioClient.post(
        '$_baseUrl/mark_all_notifications_read.php',
        data: {'user_id': userId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Either.right(null);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ??
                'Failed to mark all notifications as read',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error marking all notifications as read', error: e);
      return Either.left(
        ServerFailure('Failed to mark all notifications as read'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    DeleteNotificationParams params,
  ) async {
    try {
      final userId = await _secureStorage.getUserId();
      final response = await _dioClient.get(
        '$_baseUrl/delete_notification.php',
        queryParameters: {
          'notification_id': params.notificationId,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return Either.right(null);
      } else {
        return Either.left(
          ServerFailure(
            response.data['message'] ?? 'Failed to delete notification',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error deleting notification', error: e);
      return Either.left(ServerFailure('Failed to delete notification'));
    }
  }
}
