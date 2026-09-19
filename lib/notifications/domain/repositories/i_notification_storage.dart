// lib/services/notifications/domain/repositories/i_notification_storage.dart
// DOMAIN | Storage interface for tokens, reminders, pending notifications

import '../entities/reminder_notification.dart';
import '../entities/notification_result.dart';

abstract interface class INotificationStorage {
  // FCM Token
  Future<NotificationResult<void>> saveFcmToken(String token);
  Future<NotificationResult<String?>> getFcmToken();
  Future<NotificationResult<void>> clearFcmToken();

  // Pending Reminders (for reboot survival)
  Future<NotificationResult<void>> saveReminder(ReminderNotification reminder);
  Future<NotificationResult<ReminderNotification?>> getReminder(int id);
  Future<NotificationResult<List<ReminderNotification>>> getAllReminders();
  Future<NotificationResult<void>> removeReminder(int id);
  Future<NotificationResult<void>> clearAllReminders();

  // Permission tracking
  Future<NotificationResult<void>> savePermissionAsked(bool asked);
  Future<NotificationResult<bool>> hasPermissionBeenAsked();
  Future<NotificationResult<void>> incrementDenialCount();
  Future<NotificationResult<int>> getDenialCount();
}
