import '../../../../core/types/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

/// Get Notifications Use Case
/// Retrieves a list of notifications for the current user
class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  /// Execute the use case
  /// [params] contains pagination and filtering parameters
  /// Returns [Either] [Failure] or [List<Notification>]
  Future<Either<Failure, List<Notification>>> call(GetNotificationsParams params) {
    return _repository.getNotifications(params);
  }
}

/// Parameters for getting notifications
class GetNotificationsParams {
  final int page;
  final int limit;
  final String? type;
  final bool? isRead;

  GetNotificationsParams({
    required this.page,
    required this.limit,
    this.type,
    this.isRead,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (isRead != null) 'is_read': isRead,
    };
  }
}
