// lib/services/notifications/domain/usecases/get_pending_scheduled_usecase.dart
// DOMAIN | Get pending scheduled notification IDs use case

import '../entities/notification_result.dart';
import '../repositories/i_scheduled_notification_repository.dart';

class GetPendingScheduledUseCase {
  final IScheduledNotificationRepository _repository;

  const GetPendingScheduledUseCase(this._repository);

  Future<NotificationResult<List<int>>> call() => _repository.getPendingIds();
}
