

class ReminderConfig {
  final int maxActiveReminders;
  final Duration defaultTimeout;
  final Duration retryInterval;
  final bool persistAcrossReboot;
  final bool useExactAlarm;

  const ReminderConfig({
    this.maxActiveReminders = 50,
    this.defaultTimeout = const Duration(minutes: 5),
    this.retryInterval = const Duration(seconds: 30),
    this.persistAcrossReboot = true,
    this.useExactAlarm = true,
  });
}
