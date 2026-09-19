// lib/services/notifications/domain/repositories/i_fcm_repository.dart
// DOMAIN | FCM repository interface

import '../entities/notification_result.dart';
import '../entities/notification_payload.dart';

abstract interface class IFcmRepository {
  Future<NotificationResult<void>> initialize();
  Future<NotificationResult<String>> getToken();
  Stream<String> get onTokenRefresh;
  Future<NotificationResult<void>> subscribeToTopic(String topic);
  Future<NotificationResult<void>> unsubscribeFromTopic(String topic);
  Stream<NotificationPayload> get onForegroundMessage;
  Stream<NotificationPayload> get onBackgroundMessageTap;
  Future<NotificationResult<NotificationPayload?>> getInitialMessage();
  Future<NotificationResult<void>> dispose();
}
