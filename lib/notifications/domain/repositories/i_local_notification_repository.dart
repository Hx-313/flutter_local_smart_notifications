// lib/services/notifications/domain/repositories/i_local_notification_repository.dart
// DOMAIN | Local instant notification repository interface

import '../entities/notification_payload.dart';
import '../entities/notification_result.dart';

abstract interface class ILocalNotificationRepository {
  Future<NotificationResult<void>> initialize();
  Future<NotificationResult<void>> show(NotificationPayload payload);
  Future<NotificationResult<void>> cancel(int id);
  Future<NotificationResult<void>> cancelAll();
}
