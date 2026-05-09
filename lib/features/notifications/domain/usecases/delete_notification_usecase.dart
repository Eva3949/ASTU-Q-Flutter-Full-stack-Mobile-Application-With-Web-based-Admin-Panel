import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Delete Notification Use Case
/// Deletes a specific notification
class DeleteNotificationUseCase {
  final NotificationRepository _repository;

  DeleteNotificationUseCase(this._repository);

  /// Execute the use case
  /// [params] contains the notification ID
  /// Returns [Either] [Failure] or [void]
  Future<Either<Failure, void>> call(DeleteNotificationParams params) {
    return _repository.deleteNotification(params);
  }
}

/// Parameters for deleting notification
class DeleteNotificationParams {
  final int notificationId;

  DeleteNotificationParams({
    required this.notificationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
    };
  }
}
