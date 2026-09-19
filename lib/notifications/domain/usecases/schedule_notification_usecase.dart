// lib/services/notifications/domain/usecases/schedule_notification_usecase.dart
// DOMAIN | Schedule notification use case

import '../entities/scheduled_notification.dart';
import '../entities/notification_result.dart';
import '../failures/notification_failure.dart';
import '../repositories/i_scheduled_notification_repository.dart';

class ScheduleNotificationUseCase {
  final IScheduledNotificationRepository _repository;
  final Set<String> _registeredChannels;

  const ScheduleNotificationUseCase(this._repository, this._registeredChannels);

  Future<NotificationResult<void>> call(
    ScheduledNotification notification,
  ) async {
    if (!_registeredChannels.contains(notification.payload.channelId)) {
      return NotificationFailureResult(
        ChannelNotRegisteredFailure(notification.payload.channelId),
      );
    }
    if (notification.scheduledTime.isBefore(DateTime.now())) {
      return NotificationFailureResult(
        PastTimeFailure(notification.scheduledTime),
      );
    }
    return _repository.schedule(notification);
  }
}
