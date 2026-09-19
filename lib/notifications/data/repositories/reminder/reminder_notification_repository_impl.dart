// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_smart_notifications/notifications/domain/entities/scheduled_notification.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/config/notification_channel_config.dart';
import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/reminder_notification.dart';
import '../../../domain/entities/routing_event.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_notification_logger.dart';
import '../../../domain/repositories/i_notification_storage.dart';
import '../../../domain/repositories/i_permission_repository.dart';
import '../../../domain/repositories/i_reminder_notification_repository.dart';
import '../../routing/notification_response_codec.dart';

class ReminderNotificationRepositoryImpl
    implements IReminderNotificationRepository {
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationConfig _config;
  final INotificationStorage _storage;
  final INotificationLogger _logger;
  final IPermissionRepository _permissions;

  ReminderNotificationRepositoryImpl({
    required NotificationConfig config,
    required INotificationStorage storage,
    required INotificationLogger logger,
    required FlutterLocalNotificationsPlugin plugin,
    required IPermissionRepository permissions,
  }) : _plugin = plugin,
       _config = config,
       _storage = storage,
       _logger = logger,
       _permissions = permissions;

  @override
  Future<NotificationResult<void>> initialize() async {
    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));

      final previousTimezone = await _storage.getLastKnownTimezone();
      if (previousTimezone.isFailure) {
        return NotificationFailureResult(previousTimezone.failureOrNull!);
      }
      final savedTimezone = await _storage.saveLastKnownTimezone(
        timezone.identifier,
      );
      if (savedTimezone.isFailure) return savedTimezone;

      final changed =
          previousTimezone.valueOrNull != null &&
          previousTimezone.valueOrNull != timezone.identifier;
      if (changed) {
        final rescheduled = await _reschedulePersisted(wallClockOnly: true);
        if (rescheduled.isFailure) return rescheduled;
      }

      _logger.info('Reminder repository initialized: ${timezone.identifier}');
      return const NotificationSuccess(null);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to initialize reminder timezone',
        error,
        stackTrace,
      );
      return NotificationFailureResult(
        ProviderInitializationFailure(
          'Reminder timezone initialization failed',
          error,
          stackTrace,
        ),
      );
    }
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
        payload: encodeNotificationResponsePayload(
          data: reminder.payload.data,
          source: NotificationSource.reminder,
        ),
      );

      if (reminder.persistent) {
        final saved = await _storage.saveReminder(reminder);
        if (saved.isFailure) return saved;
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
        return await showInstant(reminder);
      }

      final scheduledTz = _toTimezone(
        reminder.scheduledTime!,
        reminder.semantics,
      );
      final details = _buildReminderDetails(reminder, channel);

      final exactTiming =
          reminder.exactTiming || _config.reminderConfig.useExactAlarm;
      if (exactTiming) {
        final exactAlarm = await _permissions.canScheduleExactAlarms();
        if (exactAlarm.isFailure) {
          return NotificationFailureResult(exactAlarm.failureOrNull!);
        }
        if (!exactAlarm.valueOrNull!) {
          return const NotificationFailureResult(ExactAlarmPermissionFailure());
        }
      }

      final pending = await _plugin.pendingNotificationRequests();
      final platformName = defaultTargetPlatform.name;
      final platformLimit = defaultTargetPlatform == TargetPlatform.iOS
          ? 64 - _config.reminderConfig.iosReservedSlots
          : _config.reminderConfig.maxPendingNotifications;
      final effectiveLimit =
          platformLimit < _config.reminderConfig.maxPendingNotifications
          ? platformLimit
          : _config.reminderConfig.maxPendingNotifications;
      final currentCount =
          pending.length -
          (pending.any((item) => item.id == reminder.payload.id) ? 1 : 0);
      if (currentCount >= effectiveLimit) {
        return NotificationFailureResult(
          PlatformLimitExceededFailure(
            platform: platformName,
            effectiveCap: effectiveLimit,
            currentCount: currentCount,
            requestedCount: 1,
            remainingCapacity: (effectiveLimit - currentCount).clamp(
              0,
              effectiveLimit,
            ),
          ),
        );
      }

      await _plugin.zonedSchedule(
        id: reminder.payload.id,
        title: reminder.payload.title,
        body: reminder.payload.body,
        scheduledDate: scheduledTz,
        notificationDetails: details,
        androidScheduleMode: exactTiming
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,

        payload: encodeNotificationResponsePayload(
          data: reminder.payload.data,
          source: NotificationSource.reminder,
        ),
      );

      final saved = await _storage.saveReminder(reminder);
      if (saved.isFailure) return saved;
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Schedule reminder failed', e, s);
      return NotificationFailureResult(
        SchedulingFailure('Schedule reminder failed', e, s),
      );
    }
  }

  tz.TZDateTime _toTimezone(
    DateTime value,
    NotificationScheduleSemantics semantics,
  ) {
    if (semantics == NotificationScheduleSemantics.absoluteInstant) {
      return tz.TZDateTime.from(value, tz.local);
    }
    return tz.TZDateTime(
      tz.local,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  @override
  Future<NotificationResult<void>> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
      final removed = await _storage.removeReminder(id);
      if (removed.isFailure) return removed;
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
      if (reminders.isFailure) {
        return NotificationFailureResult(reminders.failureOrNull!);
      }
      for (final r in reminders.valueOrNull!) {
        await _plugin.cancel(id: r.payload.id);
      }
      final cleared = await _storage.clearAllReminders();
      if (cleared.isFailure) return cleared;
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('CancelAll reminders failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> rescheduleAllPersisted() =>
      _reschedulePersisted();

  Future<NotificationResult<void>> _reschedulePersisted({
    bool wallClockOnly = false,
  }) async {
    try {
      final result = await _storage.getAllReminders();
      if (result.isFailure) {
        return NotificationFailureResult(
          result.failureOrNull ?? const UnknownFailure('Storage error'),
        );
      }

      for (final reminder in result.valueOrNull!) {
        if (wallClockOnly &&
            reminder.semantics !=
                NotificationScheduleSemantics.localWallClock) {
          continue;
        }

        final dt = reminder.scheduledTime;
        final isFuture =
            dt != null &&
            (reminder.semantics == NotificationScheduleSemantics.localWallClock
                ? _toTimezone(
                    dt,
                    reminder.semantics,
                  ).isAfter(tz.TZDateTime.now(tz.local))
                : dt.isAfter(DateTime.now()));
        if (isFuture) {
          final scheduled = await schedule(reminder);
          if (scheduled.isFailure) return scheduled;
        } else {
          final removed = await _storage.removeReminder(reminder.payload.id);
          if (removed.isFailure) return removed;
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
