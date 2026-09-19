
// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/config/notification_channel_config.dart';
import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/reminder_notification.dart';
import '../../../domain/entities/routing_event.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_notification_logger.dart';
import '../../../domain/repositories/i_notification_storage.dart';
import '../../../domain/repositories/i_reminder_notification_repository.dart';

class ReminderNotificationRepositoryImpl
    implements IReminderNotificationRepository {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationConfig _config;
  final INotificationStorage _storage;
  final INotificationLogger _logger;
  final StreamController<RoutingEvent> _routingController;

  ReminderNotificationRepositoryImpl({
    required NotificationConfig config,
    required INotificationStorage storage,
    required INotificationLogger logger,
    required StreamController<RoutingEvent> routingController,
  }) : _config = config,
       _storage = storage,
       _logger = logger,
       _routingController = routingController;

  @override
  Future<NotificationResult<void>> initialize() async {
    _logger.info('Reminder repository initialized');
    return const NotificationSuccess(null);
  }

  @override
  Future<NotificationResult<void>> showInstant(
    ReminderNotification reminder,
  ) async {
    try {
      final channel = _config.getChannel(reminder.payload.channelId);
      if (channel == null) {
        return NotificationFailureResult(
          ChannelNotRegisteredFailure(reminder.payload.channelId),
        );
      }

      final details = _buildReminderDetails(reminder, channel);

      await _plugin.show(
        id: reminder.payload.id,
        title: reminder.payload.title,
        body: reminder.payload.body,
        notificationDetails: details,
        payload: jsonEncode(reminder.payload.data),
      );

      if (reminder.persistent) {
        await _storage.saveReminder(reminder);
      }

      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Show reminder failed', e, s);
      return NotificationFailureResult(
        UnknownFailure('Show reminder failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> schedule(
    ReminderNotification reminder,
  ) async {
    try {
      final channel = _config.getChannel(reminder.payload.channelId);
      if (channel == null) {
        return NotificationFailureResult(
          ChannelNotRegisteredFailure(reminder.payload.channelId),
        );
      }

      if (reminder.scheduledTime == null) {
        return showInstant(reminder);
      }

      final scheduledTz = tz.TZDateTime.from(reminder.scheduledTime!, tz.local);
      final details = _buildReminderDetails(reminder, channel);

      await _plugin.zonedSchedule(
        id: reminder.payload.id,
        title: reminder.payload.title,
        body: reminder.payload.body,
        scheduledDate: scheduledTz,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        payload: jsonEncode(reminder.payload.data),
      );

      await _storage.saveReminder(reminder);
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Schedule reminder failed', e, s);
      return NotificationFailureResult(
        SchedulingFailure('Schedule reminder failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
      await _storage.removeReminder(id);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('Cancel reminder failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> cancelAll() async {
    try {
      final reminders = await _storage.getAllReminders();
      if (reminders.isSuccess) {
        for (final r in reminders.valueOrNull!) {
          await _plugin.cancel(id: r.payload.id);
        }
      }
      await _storage.clearAllReminders();
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('CancelAll reminders failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> rescheduleAllPersisted() async {
    try {
      final result = await _storage.getAllReminders();
      if (result.isFailure) {
        return NotificationFailureResult(
          result.failureOrNull ?? const UnknownFailure('Storage error'),
        );
      }

      final now = DateTime.now();
      for (final reminder in result.valueOrNull!) {
        final dt = reminder.scheduledTime;
        if (dt != null && dt.isAfter(now)) {
          await schedule(reminder);
        } else {
          await _storage.removeReminder(reminder.payload.id);
        }
      }

      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('Reschedule failed', e, s),
      );
    }
  }

  NotificationDetails _buildReminderDetails(
    ReminderNotification reminder,
    NotificationChannelConfig channel,
  ) {
    final soundName = reminder.payload.soundName ?? channel.soundName;
    final hasSound =
        soundName != null && _config.soundAssets.containsKey(soundName);
    final androidSound = hasSound
        ? RawResourceAndroidNotificationSound(soundName)
        : null;

    final actions = reminder.actions
        .map(
          (a) => AndroidNotificationAction(
            a.id,
            a.title,
            cancelNotification: a.cancelNotification,
            showsUserInterface: a.openApp,
          ),
        )
        .toList();

    final android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: androidSound,
      enableVibration: true,
      vibrationPattern: channel.vibrationPattern != null
          ? Int64List.fromList(channel.vibrationPattern!)
          : Int64List.fromList([0, 1000, 500, 1000]),
      ongoing: reminder.persistent,
      autoCancel: !reminder.persistent,
      fullScreenIntent: reminder.fullScreenIntent,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      icon: _config.androidDefaultIcon,
      color: _config.androidDefaultColor,
      actions: actions,
      timeoutAfter: reminder.timeout.inMilliseconds,
    );

    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: hasSound ? soundName : null,
      interruptionLevel: InterruptionLevel.critical,
    );

    return NotificationDetails(android: android, iOS: ios);
  }
}
