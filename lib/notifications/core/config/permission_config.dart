class PermissionConfig {
  final bool autoRequestOnInit;
  final String dialogTitle;
  final String dialogMessage;
  final String openSettingsLabel;
  final String notNowLabel;
  final bool requestCriticalAlert; // iOS
  final bool requestProvisional; // iOS
  final bool requestSound;
  final bool requestBadge;
  final bool requestAlert;
  final Duration dialogCooldown;
  final int denialsBeforeSettings;
  final Duration settingsReturnTimeout;

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
