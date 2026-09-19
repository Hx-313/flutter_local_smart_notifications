// lib/services/notifications/domain/usecases/cancel_notification_usecase.dart
// DOMAIN | Cancel single notification use case

import '../entities/notification_result.dart';
import '../repositories/i_local_notification_repository.dart';
import '../repositories/i_scheduled_notification_repository.dart';

class CancelNotificationUseCase {
  final ILocalNotificationRepository _localRepository;
  final IScheduledNotificationRepository _scheduledRepository;

  const CancelNotificationUseCase(
    this._localRepository,
    this._scheduledRepository,
  );

  Future<NotificationResult<void>> call(int id) async {
    final localResult = await _localRepository.cancel(id);
    final scheduledResult = await _scheduledRepository.cancel(id);

    if (localResult.isSuccess || scheduledResult.isSuccess) {
      return const NotificationSuccess(null);
    }
    return localResult;
  }
}
