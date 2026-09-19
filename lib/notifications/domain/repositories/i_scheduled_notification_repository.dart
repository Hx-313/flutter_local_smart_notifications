// lib/services/notifications/domain/repositories/i_scheduled_notification_repository.dart
// DOMAIN | Scheduled notification repository interface

import '../entities/scheduled_notification.dart';
import '../entities/notification_result.dart';

abstract interface class IScheduledNotificationRepository {
  Future<NotificationResult<void>> initialize();
  Future<NotificationResult<void>> schedule(ScheduledNotification notification);
  Future<NotificationResult<void>> cancel(int id);
  Future<NotificationResult<void>> cancelAll();
  Future<NotificationResult<List<int>>> getPendingIds();
}
