// lib/services/notifications/domain/entities/permission_status.dart
// DOMAIN | Sealed permission status types

/// Describes the app's current notification permission state.
sealed class NotificationPermissionStatus {
  /// Creates a permission status value.
  const NotificationPermissionStatus();

  /// Whether notifications are allowed, including provisional permission.
  bool get isGranted =>
      this is PermissionGranted || this is PermissionProvisional;

  /// Whether permission is denied, including permanently denied.
  bool get isDenied =>
      this is PermissionDenied || this is PermissionPermanentlyDenied;

  /// Whether the system may show a permission request for this state.
  bool get canRequest =>
      this is PermissionNotDetermined || this is PermissionDenied;
}

/// Permission has not yet been requested from the user.
class PermissionNotDetermined extends NotificationPermissionStatus {
  /// Creates the not-determined permission state.
  const PermissionNotDetermined();
}

/// Notification permission has been granted.
class PermissionGranted extends NotificationPermissionStatus {
  /// Creates the granted permission state.
  const PermissionGranted();
}

/// Notification permission was denied but may be requested again.
class PermissionDenied extends NotificationPermissionStatus {
  /// Creates the denied permission state.
  const PermissionDenied();
}

/// Notification permission was denied and cannot be requested again directly.
class PermissionPermanentlyDenied extends NotificationPermissionStatus {
  /// Creates the permanently denied permission state.
  const PermissionPermanentlyDenied();
}

/// The operating system restricts notification permission for this app.
class PermissionRestricted extends NotificationPermissionStatus {
  /// Creates the restricted permission state.
  const PermissionRestricted();
}

/// Notifications are allowed provisionally by the operating system.
class PermissionProvisional extends NotificationPermissionStatus {
  /// Creates the provisional permission state.
  const PermissionProvisional();
}
