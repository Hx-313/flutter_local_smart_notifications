// lib/services/notifications/domain/repositories/i_one_signal_repository.dart
// DOMAIN | OneSignal repository interface

import '../entities/notification_result.dart';
import '../entities/notification_payload.dart';

abstract interface class IOneSignalRepository {
  Future<NotificationResult<void>> initialize();
  Future<NotificationResult<void>> setExternalUserId(String userId);
  Future<NotificationResult<void>> removeExternalUserId();
  Future<NotificationResult<String?>> getPlayerId();
  Stream<NotificationPayload> get onNotificationReceived;
  Stream<NotificationPayload> get onNotificationTapped;
  Future<NotificationResult<void>> dispose();
}
