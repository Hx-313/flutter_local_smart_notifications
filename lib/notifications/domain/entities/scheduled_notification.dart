// lib/services/notifications/domain/entities/scheduled_notification.dart
// DOMAIN | Scheduled notification entity

import 'notification_payload.dart';

enum RepeatInterval { none, daily, weekly, monthly, yearly }

class ScheduledNotification {
  final NotificationPayload payload;
  final DateTime scheduledTime;
  final RepeatInterval repeatInterval;
  final bool allowWhileIdle;
  final bool exactTiming;

  const ScheduledNotification({
    required this.payload,
    required this.scheduledTime,
    this.repeatInterval = RepeatInterval.none,
    this.allowWhileIdle = true,
    this.exactTiming = false,
  });

  Map<String, dynamic> toMap() => {
    'payload': payload.toMap(),
    'scheduledTime': scheduledTime.toIso8601String(),
    'repeatInterval': repeatInterval.index,
    'allowWhileIdle': allowWhileIdle,
    'exactTiming': exactTiming,
  };

  factory ScheduledNotification.fromMap(Map<String, dynamic> map) =>
      ScheduledNotification(
        payload: NotificationPayload.fromMap(
          map['payload'] as Map<String, dynamic>,
        ),
        scheduledTime: DateTime.parse(map['scheduledTime'] as String),
        repeatInterval: RepeatInterval.values[map['repeatInterval'] as int],
        allowWhileIdle: map['allowWhileIdle'] as bool? ?? true,
        exactTiming: map['exactTiming'] as bool? ?? false,
      );
}
