// lib/services/notifications/domain/entities/reminder_notification.dart
// DOMAIN | High-priority exact reminder entity

import 'notification_payload.dart';
import 'notification_action.dart';

class ReminderNotification {
  final NotificationPayload payload;
  final DateTime? scheduledTime; // null = instant
  final Duration timeout;
  final bool loopSound;
  final bool persistent;
  final bool fullScreenIntent;
  final List<NotificationAction> actions;

  const ReminderNotification({
    required this.payload,
    this.scheduledTime,
    this.timeout = const Duration(minutes: 5),
    this.loopSound = true,
    this.persistent = true,
    this.fullScreenIntent = false,
    this.actions = const [],
  });

  bool get isInstant => scheduledTime == null;

  Map<String, dynamic> toMap() => {
    'payload': payload.toMap(),
    'scheduledTime': scheduledTime?.toIso8601String(),
    'timeout': timeout.inMilliseconds,
    'loopSound': loopSound,
    'persistent': persistent,
    'fullScreenIntent': fullScreenIntent,
    'actions': actions.map((a) => a.toMap()).toList(),
  };

  factory ReminderNotification.fromMap(Map<String, dynamic> map) =>
      ReminderNotification(
        payload: NotificationPayload.fromMap(
          map['payload'] as Map<String, dynamic>,
        ),
        scheduledTime: map['scheduledTime'] != null
            ? DateTime.parse(map['scheduledTime'] as String)
            : null,
        timeout: Duration(milliseconds: map['timeout'] as int),
        loopSound: map['loopSound'] as bool? ?? true,
        persistent: map['persistent'] as bool? ?? true,
        fullScreenIntent: map['fullScreenIntent'] as bool? ?? false,
        actions:
            (map['actions'] as List?)
                ?.map(
                  (a) => NotificationAction.fromMap(a as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}
