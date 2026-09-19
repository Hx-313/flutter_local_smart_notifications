// lib/services/notifications/domain/usecases/show_reminder_usecase.dart
// DOMAIN | Show instant reminder use case

import '../entities/reminder_notification.dart';
import '../entities/notification_result.dart';
import '../failures/notification_failure.dart';
import '../repositories/i_reminder_notification_repository.dart';

class ShowReminderUseCase {
  final IReminderNotificationRepository _repository;
  final Set<String> _registeredChannels;

  const ShowReminderUseCase(this._repository, this._registeredChannels);

  Future<NotificationResult<void>> call(ReminderNotification reminder) async {
    if (!_registeredChannels.contains(reminder.payload.channelId)) {
      return NotificationFailureResult(
        ChannelNotRegisteredFailure(reminder.payload.channelId),
      );
    }
    return _repository.showInstant(reminder);
  }
}
