// lib/services/notifications/domain/entities/scheduled_notification.dart
// DOMAIN | Scheduled notification entity

import 'notification_payload.dart';

/// Recurrence interval for a scheduled notification.
enum RepeatInterval {
  /// Schedules the notification once.
  none,

  /// Repeats the notification every day.
  daily,

  /// Repeats the notification every week.
  weekly,

  /// Repeats the notification every month.
  monthly,

  /// Repeats the notification every year.
  yearly,
}

/// Defines how a scheduled time behaves when the device timezone changes.
enum NotificationScheduleSemantics {
  /// Preserves the same absolute moment in time.
  absoluteInstant,

  /// Preserves the same local clock time in the new timezone.
  localWallClock,
}

/// Describes a notification scheduled for a future time.
class ScheduledNotification {
  /// Content and display options shown at the scheduled time.
  final NotificationPayload payload;

  /// Date and time when the notification is scheduled to appear.
  final DateTime scheduledTime;

  /// Recurrence interval, or [RepeatInterval.none] for a one-time schedule.
  final RepeatInterval repeatInterval;

  /// Whether delivery may occur while the device is idle.
  final bool allowWhileIdle;

  /// Whether scheduling requires exact alarm delivery.
  ///
  /// If exact delivery is unavailable, scheduling returns an
  /// `ExactAlarmPermissionFailure`.
  final bool exactTiming;

  /// How [scheduledTime] behaves when the device's timezone changes.
  final NotificationScheduleSemantics semantics;

  /// Creates a scheduled notification.
  const ScheduledNotification({
    required this.payload,
    required this.scheduledTime,
    this.repeatInterval = RepeatInterval.none,
    this.allowWhileIdle = true,
    this.exactTiming = false,
    this.semantics = NotificationScheduleSemantics.absoluteInstant,
  });

  /// Serializes this schedule to a map accepted by [fromMap].
  Map<String, dynamic> toMap() => {
    'payload': payload.toMap(),
    'scheduledTime': scheduledTime.toIso8601String(),
    'repeatInterval': repeatInterval.index,
    'allowWhileIdle': allowWhileIdle,
    'exactTiming': exactTiming,
    'semantics': semantics.name,
  };

  /// Creates a scheduled notification from its serialized [map].
  factory ScheduledNotification.fromMap(Map<String, dynamic> map) =>
      ScheduledNotification(
        payload: NotificationPayload.fromMap(
          map['payload'] as Map<String, dynamic>,
        ),
        scheduledTime: DateTime.parse(map['scheduledTime'] as String),
        repeatInterval: RepeatInterval.values[map['repeatInterval'] as int],
        allowWhileIdle: map['allowWhileIdle'] as bool? ?? true,
        exactTiming: map['exactTiming'] as bool? ?? false,
        semantics: NotificationScheduleSemantics.values.firstWhere(
          (value) => value.name == map['semantics'],
          orElse: () => NotificationScheduleSemantics.absoluteInstant,
        ),
      );
}
