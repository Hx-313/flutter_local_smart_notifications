// lib/services/notifications/domain/entities/reminder_notification.dart
// DOMAIN | High-priority exact reminder entity

import 'notification_payload.dart';
import 'notification_action.dart';
import 'scheduled_notification.dart';

/// Describes an immediate or scheduled reminder notification.
class ReminderNotification {
  /// Content and display options shown for the reminder.
  final NotificationPayload payload;

  /// Time to show the reminder, or `null` to show it immediately.
  final DateTime? scheduledTime; // null = instant

  /// Duration before the reminder times out.
  final Duration timeout;

  /// Whether this reminder requests looping sound.
  final bool loopSound;

  /// Whether the reminder remains visible until the user dismisses it.
  final bool persistent;

  /// Whether the reminder requests a full-screen intent on supported Android
  /// devices.
  final bool fullScreenIntent;

  /// Whether scheduled display requires exact alarm delivery.
  final bool exactTiming;

  /// Actions offered alongside the reminder.
  final List<NotificationAction> actions;

  /// How [scheduledTime] behaves when the device's timezone changes.
  final NotificationScheduleSemantics semantics;

  /// Creates an immediate or scheduled reminder.
  const ReminderNotification({
    required this.payload,
    this.scheduledTime,
    this.timeout = const Duration(minutes: 5),
    this.loopSound = true,
    this.persistent = true,
    this.fullScreenIntent = false,
    this.exactTiming = false,
    this.actions = const [],
    this.semantics = NotificationScheduleSemantics.absoluteInstant,
  });

  /// Whether this reminder has no scheduled time and should show immediately.
  bool get isInstant => scheduledTime == null;

  /// Serializes this reminder to a map accepted by [fromMap].
  Map<String, dynamic> toMap() => {
    'payload': payload.toMap(),
    'scheduledTime': scheduledTime?.toIso8601String(),
    'timeout': timeout.inMilliseconds,
    'loopSound': loopSound,
    'persistent': persistent,
    'fullScreenIntent': fullScreenIntent,
    'exactTiming': exactTiming,
    'actions': actions.map((a) => a.toMap()).toList(),
    'semantics': semantics.name,
  };

  /// Creates a reminder from its serialized [map].
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
        exactTiming: map['exactTiming'] as bool? ?? false,
        actions:
            (map['actions'] as List?)
                ?.map(
                  (a) => NotificationAction.fromMap(a as Map<String, dynamic>),
                )
                .toList() ??
            [],
        semantics: NotificationScheduleSemantics.values.firstWhere(
          (value) => value.name == map['semantics'],
          orElse: () => NotificationScheduleSemantics.absoluteInstant,
        ),
      );
}
