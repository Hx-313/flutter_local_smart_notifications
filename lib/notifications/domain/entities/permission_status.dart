// lib/services/notifications/domain/entities/permission_status.dart
// DOMAIN | Sealed permission status types

sealed class NotificationPermissionStatus {
  const NotificationPermissionStatus();

  bool get isGranted =>
      this is PermissionGranted || this is PermissionProvisional;
  bool get isDenied =>
      this is PermissionDenied || this is PermissionPermanentlyDenied;
  bool get canRequest =>
      this is PermissionNotDetermined || this is PermissionDenied;
}

class PermissionNotDetermined extends NotificationPermissionStatus {
  const PermissionNotDetermined();
}

class PermissionGranted extends NotificationPermissionStatus {
  const PermissionGranted();
}

class PermissionDenied extends NotificationPermissionStatus {
  const PermissionDenied();
}

class PermissionPermanentlyDenied extends NotificationPermissionStatus {
  const PermissionPermanentlyDenied();
}

class PermissionRestricted extends NotificationPermissionStatus {
  const PermissionRestricted();
}

class PermissionProvisional extends NotificationPermissionStatus {
  const PermissionProvisional();
}
