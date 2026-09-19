// lib/services/notifications/domain/repositories/i_permission_repository.dart
// DOMAIN | Permission repository interface

import '../entities/permission_status.dart';
import '../entities/notification_result.dart';

abstract interface class IPermissionRepository {
  Future<NotificationResult<NotificationPermissionStatus>> check();
  Future<NotificationResult<NotificationPermissionStatus>> request();
  Future<NotificationResult<void>> openSettings();
  Future<NotificationResult<bool>> canScheduleExactAlarms();
  Future<NotificationResult<bool>> requestExactAlarmPermission();
}
