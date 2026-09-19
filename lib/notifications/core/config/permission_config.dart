

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
  });
}
