import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Mark All Notifications Read Use Case
/// Marks all notifications for the current user as read
class MarkAllNotificationsReadUseCase {
  final NotificationRepository _repository;

  MarkAllNotificationsReadUseCase(this._repository);

  /// Execute the use case
  /// Returns [Either] [Failure] or [void]
  Future<Either<Failure, void>> call() {
    return _repository.markAllNotificationsAsRead();
  }
}
