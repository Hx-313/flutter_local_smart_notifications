/// Configures permission requests and their optional explanatory dialog.
class PermissionConfig {
  /// Whether initialization should request notification permission.
  final bool autoRequestOnInit;

  /// Title shown in the permission explanation dialog.
  final String dialogTitle;

  /// Message shown in the permission explanation dialog.
  final String dialogMessage;

  /// Label of the dialog action that opens system settings.
  final String openSettingsLabel;

  /// Label of the dialog action that postpones opening settings.
  final String notNowLabel;

  /// Whether to request iOS critical alert permission.
  final bool requestCriticalAlert; // iOS

  /// Whether to request iOS provisional notification permission.
  final bool requestProvisional; // iOS

  /// Whether to request permission to play notification sounds.
  final bool requestSound;

  /// Whether to request permission to update the app badge.
  final bool requestBadge;

  /// Whether to request permission to show alerts.
  final bool requestAlert;

  /// Minimum interval between showing the permission explanation dialog.
  final Duration dialogCooldown;

  /// Number of denials before the service prompts the user to open settings.
  final int denialsBeforeSettings;

  /// Maximum time to wait for the app to resume after opening system settings.
  final Duration settingsReturnTimeout;

  /// Creates permission request and prompt settings.
  const PermissionConfig({
    this.autoRequestOnInit = false,
    this.dialogTitle = 'Enable Notifications',
    this.dialogMessage =
        'Notifications help you stay updated with important alerts and reminders.',
    this.openSettingsLabel = 'Open Settings',
    this.notNowLabel = 'Not Now',
    this.requestCriticalAlert = false,
    this.requestProvisional = false,
    this.requestSound = true,
    this.requestBadge = true,
    this.requestAlert = true,
    this.dialogCooldown = const Duration(days: 7),
    this.denialsBeforeSettings = 2,
    this.settingsReturnTimeout = const Duration(minutes: 2),
  });
}
