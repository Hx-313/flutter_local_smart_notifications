import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/reminder_notification.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_reminder_notification_repository.dart';

class ReminderNotificationRepositoryImpl
    implements IReminderNotificationRepository {
  ReminderNotificationRepositoryImpl({
    required dynamic config,
    required dynamic storage,
    required dynamic logger,
    required dynamic plugin,
    required dynamic permissions,
  });

  @override
  Future<NotificationResult<void>> initialize() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }

  @override
  Future<NotificationResult<void>> showInstant(
    ReminderNotification reminder,
  ) async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }

  @override
  Future<NotificationResult<void>> schedule(
    ReminderNotification reminder,
  ) async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }

  @override
  Future<NotificationResult<void>> cancel(int id) async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }

  @override
  Future<NotificationResult<void>> cancelAll() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }

  @override
  Future<NotificationResult<void>> rescheduleAllPersisted() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localReminder'),
    );
  }
}
