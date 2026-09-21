/// Sets reminder limits and scheduling behavior.
class ReminderConfig {
  /// Maximum number of active reminders maintained by the service.
  final int maxActiveReminders;

  /// Timeout value configured as the default for reminders.
  final Duration defaultTimeout;

  /// Interval configured for reminder retry attempts.
  final Duration retryInterval;

  /// Whether reminders should be restored after a device reboot.
  final bool persistAcrossReboot;

  /// Whether scheduled reminders request exact alarm delivery by default.
  final bool useExactAlarm;

  /// Maximum number of pending notifications allowed by the service.
  final int maxPendingNotifications;

  /// Number of iOS pending-notification slots reserved for other use.
  final int iosReservedSlots;

  /// Creates reminder limits and scheduling defaults.
  const ReminderConfig({
    this.maxActiveReminders = 50,
    this.defaultTimeout = const Duration(minutes: 5),
    this.retryInterval = const Duration(seconds: 30),
    this.persistAcrossReboot = true,
    this.useExactAlarm = false,
    this.maxPendingNotifications = 60,
    this.iosReservedSlots = 4,
  });
}
