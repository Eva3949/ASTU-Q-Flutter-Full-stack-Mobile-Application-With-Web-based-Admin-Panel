import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Mark Notification Read Use Case
/// Marks a specific notification as read
class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  /// Execute the use case
  /// [params] contains the notification ID
  /// Returns [Either] [Failure] or [void]
  Future<Either<Failure, void>> call(MarkNotificationReadParams params) {
    return _repository.markNotificationAsRead(params);
  }
}

/// Parameters for marking notification as read
class MarkNotificationReadParams {
  final int notificationId;

  MarkNotificationReadParams({
    required this.notificationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
    };
  }
}
