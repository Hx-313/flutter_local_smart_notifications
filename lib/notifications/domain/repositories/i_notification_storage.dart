// lib/services/notifications/domain/repositories/i_notification_storage.dart
// DOMAIN | Storage interface for tokens, reminders, pending notifications

import '../entities/reminder_notification.dart';
import '../entities/notification_result.dart';
import '../entities/routing_event.dart';

abstract interface class INotificationStorage {
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
  Future<NotificationResult<void>> resetDenialCount();
  Future<NotificationResult<int>> getDenialCount();
  Future<NotificationResult<bool>> shouldShowPermissionDialog({
    required Duration cooldown,
  });
  Future<NotificationResult<void>> recordPermissionPromptShown();
  Future<NotificationResult<void>> savePendingRoutingEvent(RoutingEvent event);
  Future<NotificationResult<List<RoutingEvent>>> consumePendingRoutingEvents();
  Future<NotificationResult<String?>> getLastKnownTimezone();
  Future<NotificationResult<void>> saveLastKnownTimezone(String timezone);
}
