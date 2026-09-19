// ignore_for_file: unused_field

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide RepeatInterval;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/config/notification_channel_config.dart';
import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/routing_event.dart';
import '../../../domain/entities/scheduled_notification.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_notification_logger.dart';
import '../../../domain/repositories/i_permission_repository.dart';
import '../../../domain/repositories/i_scheduled_notification_repository.dart';
import '../../routing/notification_response_codec.dart';

class ScheduledNotificationRepositoryImpl
    implements IScheduledNotificationRepository {
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationConfig _config;
  final INotificationLogger _logger;
  final IPermissionRepository _permissions;

  bool _timezoneInitialized = false;

  ScheduledNotificationRepositoryImpl({
    required NotificationConfig config,
    required INotificationLogger logger,
    required FlutterLocalNotificationsPlugin plugin,
    required IPermissionRepository permissions,
  }) : _plugin = plugin,
       _config = config,
       _logger = logger,
       _permissions = permissions;

  @override
  Future<NotificationResult<void>> initialize() async {
    try {
      await _initTimezoneIfNeeded();
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Failed to initialize timezone', e, s);
      return NotificationFailureResult(
        ProviderInitializationFailure('Timezone init failed', e, s),
      );
    }
  }

  Future<void> _initTimezoneIfNeeded() async {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    _timezoneInitialized = true;
    _logger.info('Timezone initialized: $timezone');
  }

  @override
  Future<NotificationResult<void>> schedule(
    ScheduledNotification notification,
  ) async {
    try {
      await _initTimezoneIfNeeded();

      final channel = _config.getChannel(notification.payload.channelId);
      if (channel == null) {
        return NotificationFailureResult(
          ChannelNotRegisteredFailure(notification.payload.channelId),
        );
      }

      if (notification.exactTiming) {
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
          (pending.any((item) => item.id == notification.payload.id) ? 1 : 0);
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

      final scheduledTz = _toTimezone(
        notification.scheduledTime,
        notification.semantics,
      );
      final details = _buildNotificationDetails(notification, channel);

      final matchComponents = _mapRepeatInterval(notification.repeatInterval);
      final androidMode = notification.exactTiming
          ? notification.allowWhileIdle
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.exact
          : notification.allowWhileIdle
          ? AndroidScheduleMode.inexactAllowWhileIdle
          : AndroidScheduleMode.inexact;

      await _plugin.zonedSchedule(
        id: notification.payload.id,
        title: notification.payload.title,
        body: notification.payload.body,
        scheduledDate: scheduledTz,
        notificationDetails: details,
        androidScheduleMode: androidMode,

        matchDateTimeComponents: matchComponents,
        payload: encodeNotificationResponsePayload(
          data: notification.payload.data,
          source: NotificationSource.scheduled,
        ),
      );

      _logger.info(
        'Scheduled notification: ${notification.payload.id} for $scheduledTz',
      );
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Failed to schedule notification', e, s);
      return NotificationFailureResult(
        SchedulingFailure('Schedule failed', e, s),
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
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(UnknownFailure('Cancel failed', e, s));
    }
  }

  @override
  Future<NotificationResult<void>> cancelAll() async {
    try {
      await _plugin.cancelAll();
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('CancelAll failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<List<int>>> getPendingIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return NotificationSuccess(pending.map((p) => p.id).toList());
    } catch (e, s) {
      return NotificationFailureResult(
        UnknownFailure('GetPending failed', e, s),
      );
    }
  }

  NotificationDetails _buildNotificationDetails(
    ScheduledNotification notification,
    NotificationChannelConfig channel,
  ) {
    final soundName = notification.payload.soundName ?? channel.soundName;
    final hasSound =
        soundName != null && _config.soundAssets.containsKey(soundName);
    final androidSound = hasSound
        ? RawResourceAndroidNotificationSound(soundName)
        : null;

    final android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: _mapImportance(channel.importance),
      priority: Priority.high,
      playSound: !notification.payload.silent && channel.playSound,
      sound: androidSound,
      enableVibration: channel.enableVibration,
      vibrationPattern: channel.vibrationPattern != null
          ? Int64List.fromList(channel.vibrationPattern!)
          : null,
      color: _config.androidDefaultColor,
      icon: _config.androidDefaultIcon,
    );

    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: channel.showBadge,
      presentSound: !notification.payload.silent && channel.playSound,
      sound: hasSound ? soundName : null,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  DateTimeComponents? _mapRepeatInterval(RepeatInterval interval) =>
      switch (interval) {
        RepeatInterval.none => null,
        RepeatInterval.daily => DateTimeComponents.time,
        RepeatInterval.weekly => DateTimeComponents.dayOfWeekAndTime,
        RepeatInterval.monthly => DateTimeComponents.dayOfMonthAndTime,
        RepeatInterval.yearly => DateTimeComponents.dateAndTime,
      };

  Importance _mapImportance(ChannelImportance importance) =>
      switch (importance) {
        ChannelImportance.none => Importance.none,
        ChannelImportance.min => Importance.min,
        ChannelImportance.low => Importance.low,
        ChannelImportance.defaultImportance => Importance.defaultImportance,
        ChannelImportance.high => Importance.high,
        ChannelImportance.max => Importance.max,
      };
}
