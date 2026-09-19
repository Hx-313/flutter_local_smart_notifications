// lib/services/notifications/domain/entities/permission_status.dart
// DOMAIN | Sealed permission status types

sealed class PermissionStatus {
  const PermissionStatus();

  bool get isGranted => this is PermissionGranted;
  bool get isDenied =>
      this is PermissionDenied || this is PermissionPermanentlyDenied;
  bool get canRequest =>
      this is PermissionNotDetermined || this is PermissionDenied;
}

class PermissionNotDetermined extends PermissionStatus {
  const PermissionNotDetermined();
}

class PermissionGranted extends PermissionStatus {
  const PermissionGranted();
}

class PermissionDenied extends PermissionStatus {
  const PermissionDenied();
}

class PermissionPermanentlyDenied extends PermissionStatus {
  const PermissionPermanentlyDenied();
}

class PermissionRestricted extends PermissionStatus {
  const PermissionRestricted();
}

class PermissionProvisional extends PermissionStatus {
  const PermissionProvisional();
}

class NotificationPermissionState {
  final bool canShowNotifications; // POST_NOTIFICATIONS / iOS general
  final bool canScheduleExact; // SCHEDULE_EXACT_ALARM (Android 12+)
  final bool needsExactAlarmSetting; // Must open system settings (Android 12+)
  final bool isPermanentlyDenied; // User said "don't ask again"

  const NotificationPermissionState({
    required this.canShowNotifications,
    required this.canScheduleExact,
    required this.needsExactAlarmSetting,
    required this.isPermanentlyDenied,
  });

  /// Fully ready — no banners needed
  bool get isFullyGranted => canShowNotifications && canScheduleExact;

  /// Needs runtime prompt (Android 13+ or iOS)
  bool get needsNotificationPrompt =>
      !canShowNotifications && !isPermanentlyDenied;

  /// Needs settings redirect (permanently denied or exact alarm)
  bool get needsSettingsRedirect =>
      isPermanentlyDenied || needsExactAlarmSetting;
}
