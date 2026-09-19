

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsPlugin {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  void Function(String? payload)? _onTap;

  bool _timezoneInitialized = false;

  Future<void> initialize({
    required String androidDefaultIcon,
    required void Function(String? payload) onTap,
  }) async {
    _onTap = onTap;

    // Timezone init (safe to call multiple times; guarded)
    await _initTimezoneIfNeeded();

    final androidSettings = AndroidInitializationSettings(androidDefaultIcon);
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );
  }

  void _handleResponse(NotificationResponse response) {
    _onTap?.call(response.payload);
  }

  @pragma('vm:entry-point')
  static void _backgroundHandler(NotificationResponse response) {
    // Intentionally empty: background isolate entrypoint.
    // Consumer routing is handled via the main isolate streams.
  }

  Future<void> _initTimezoneIfNeeded() async {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();

    // flutter_timezone returns e.g. "Asia/Kolkata"
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz.identifier));

    _timezoneInitialized = true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    String? payload,
    String? sound, // raw resource name without extension for Android
    bool playSound = true,
    bool enableVibration = true,
    Int64List? vibrationPattern,
    int importance = 4,
  }) async {
    final androidSound = sound != null
        ? RawResourceAndroidNotificationSound(sound)
        : null;

    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: _mapImportance(importance),
      priority: Priority.high,
      playSound: playSound,
      sound: androidSound,
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required DateTime scheduledTime,
    String? payload,
    String? sound,
    bool exactTiming = false,
    int? repeatIntervalIndex, // 1 daily, 2 weekly, 3 monthly
  }) async {
    await _initTimezoneIfNeeded();

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    DateTimeComponents? matchComponents;
    if (repeatIntervalIndex != null) {
      matchComponents = switch (repeatIntervalIndex) {
        1 => DateTimeComponents.time,
        2 => DateTimeComponents.dayOfWeekAndTime,
        3 => DateTimeComponents.dayOfMonthAndTime,
        _ => null,
      };
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: exactTiming
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,

      matchDateTimeComponents: matchComponents,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id: id);

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<List<int>> getPendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((p) => p.id).toList();
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }
    // iOS: cannot reliably check without requesting. Return true to avoid false negatives.
    return true;
  }

  Future<bool> requestPermission({
    required bool alert,
    required bool badge,
    required bool sound,
    bool provisional = false,
    bool critical = false,
  }) async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: alert,
            badge: badge,
            sound: sound,
            provisional: provisional,
            critical: critical,
          ) ??
          false;
    }
    return true;
  }

  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  Future<void> createChannel({
    required String id,
    required String name,
    required String description,
    required int importance,
    String? sound,
    bool playSound = true,
    bool enableVibration = true,
    Int64List? vibrationPattern,
    bool showBadge = true,
    bool enableLights = true,
    int? ledColorArgb,
  }) async {
    if (!Platform.isAndroid) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final channel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: _mapImportance(importance),
      playSound: playSound,
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
      showBadge: showBadge,
      enableLights: enableLights,
      ledColor: ledColorArgb != null ? Color(ledColorArgb) : null,
    );

    await android.createNotificationChannel(channel);
  }

  Importance _mapImportance(int value) => switch (value) {
    0 => Importance.none,
    1 => Importance.min,
    2 => Importance.low,
    3 => Importance.defaultImportance,
    4 => Importance.high,
    5 => Importance.max,
    _ => Importance.high,
  };
}
