// lib/services/notifications/domain/repositories/i_reminder_notification_repository.dart
// DOMAIN | High-priority reminder repository interface

import '../entities/reminder_notification.dart';
import '../entities/notification_result.dart';

abstract interface class IReminderNotificationRepository {
  Future<NotificationResult<void>> initialize();
  Future<NotificationResult<void>> showInstant(ReminderNotification reminder);
  Future<NotificationResult<void>> schedule(ReminderNotification reminder);
  Future<NotificationResult<void>> cancel(int id);
  Future<NotificationResult<void>> cancelAll();
  Future<NotificationResult<void>> rescheduleAllPersisted();
}
