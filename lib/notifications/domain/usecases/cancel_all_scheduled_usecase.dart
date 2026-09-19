// lib/services/notifications/domain/usecases/cancel_all_scheduled_usecase.dart
// DOMAIN | Cancel all scheduled notifications use case

import '../entities/notification_result.dart';
import '../repositories/i_scheduled_notification_repository.dart';

class CancelAllScheduledUseCase {
  final IScheduledNotificationRepository _repository;

  const CancelAllScheduledUseCase(this._repository);

  Future<NotificationResult<void>> call() => _repository.cancelAll();
}
