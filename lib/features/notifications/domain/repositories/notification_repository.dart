import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification.dart';
import '../usecases/get_notifications_usecase.dart';
import '../usecases/mark_notification_read_usecase.dart';
import '../usecases/mark_all_notifications_read_usecase.dart';
import '../usecases/delete_notification_usecase.dart';

/// Notification Repository Interface
/// Defines the contract for notification data operations
abstract class NotificationRepository {
  /// Get notifications for the current user
  Future<Either<Failure, List<Notification>>> getNotifications(GetNotificationsParams params);
  
  /// Mark a notification as read
  Future<Either<Failure, void>> markNotificationAsRead(MarkNotificationReadParams params);
  
  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllNotificationsAsRead();
  
  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(DeleteNotificationParams params);
}
