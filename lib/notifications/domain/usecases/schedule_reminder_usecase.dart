// lib/services/notifications/domain/usecases/schedule_reminder_usecase.dart
// DOMAIN | Schedule reminder use case

import '../entities/reminder_notification.dart';
import '../entities/notification_result.dart';
import '../failures/notification_failure.dart';
import '../repositories/i_reminder_notification_repository.dart';
import '../repositories/i_notification_storage.dart';

class ScheduleReminderUseCase {
  final IReminderNotificationRepository _repository;
  final INotificationStorage _storage;
  final Set<String> _registeredChannels;
  final int _maxActive;

  const ScheduleReminderUseCase(
    this._repository,
    this._storage,
    this._registeredChannels,
    this._maxActive,
  );

  Future<NotificationResult<void>> call(ReminderNotification reminder) async {
    if (!_registeredChannels.contains(reminder.payload.channelId)) {
      return NotificationFailureResult(
        ChannelNotRegisteredFailure(reminder.payload.channelId),
      );
    }

    if (reminder.scheduledTime != null &&
        reminder.scheduledTime!.isBefore(DateTime.now())) {
      return NotificationFailureResult(
        PastTimeFailure(reminder.scheduledTime!),
      );
    }

    final allReminders = await _storage.getAllReminders();
    if (allReminders.isFailure) {
      return NotificationFailureResult(allReminders.failureOrNull!);
    }

    final reminders = allReminders.valueOrNull!;
    final replacesExisting = reminders.any(
      (existing) => existing.payload.id == reminder.payload.id,
    );
    if (!replacesExisting && reminders.length >= _maxActive) {
      return NotificationFailureResult(
        ReminderLimitExceededFailure(_maxActive),
      );
    }

    return _repository.schedule(reminder);
  }
}
