
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/config/notification_channel_config.dart';
import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_payload.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/routing_event.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_local_notification_repository.dart';
import '../../../domain/repositories/i_notification_logger.dart';

class LocalNotificationRepositoryImpl implements ILocalNotificationRepository {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationConfig _config;
  final INotificationLogger _logger;
  final StreamController<RoutingEvent> _routingController;

  LocalNotificationRepositoryImpl({
    required NotificationConfig config,
    required INotificationLogger logger,
    required StreamController<RoutingEvent> routingController,
  }) : _config = config,
       _logger = logger,
       _routingController = routingController;

  @override
  Future<NotificationResult<void>> initialize() async {
    try {
      final androidSettings = AndroidInitializationSettings(
        _config.androidDefaultIcon,
      );
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
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
      );

      await _createChannels();
      _logger.info('LocalNotificationRepository initialized');
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('LocalNotificationRepository init failed', e, s);
      return NotificationFailureResult(
        ProviderInitializationFailure('Local notification init failed', e, s),
      );
    }
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _routingController.add(
        RoutingEvent.fromPayloadData(
          data: data,
          source: NotificationSource.local,
          interaction:
              response.notificationResponseType ==
                  NotificationResponseType.selectedNotificationAction
              ? NotificationInteraction.action
              : NotificationInteraction.tap,
          actionId: response.actionId,
        ),
      );
    } catch (_) {
      // ignore malformed payload
    }
  }

  @pragma('vm:entry-point')
  static void _backgroundHandler(NotificationResponse response) {
    // Background isolate entrypoint (must be top-level / static).
  }

  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    for (final ch in _config.channels) {
      final importance = switch (ch.importance) {
        ChannelImportance.none => Importance.none,
        ChannelImportance.min => Importance.min,
        ChannelImportance.low => Importance.low,
        ChannelImportance.defaultImportance => Importance.defaultImportance,
        ChannelImportance.high => Importance.high,
        ChannelImportance.max => Importance.max,
      };

      final hasSound =
          ch.soundName != null && _config.soundAssets.containsKey(ch.soundName);
      final sound = hasSound
          ? RawResourceAndroidNotificationSound(ch.soundName!)
          : null;

      await android.createNotificationChannel(
        AndroidNotificationChannel(
          ch.id,
          ch.name,
          description: ch.description,
          importance: importance,
          playSound: ch.playSound,
          sound: sound,
          enableVibration: ch.enableVibration,
          showBadge: ch.showBadge,
          enableLights: ch.enableLights,
          ledColor: ch.ledColor,
          vibrationPattern: ch.vibrationPattern != null
              ? Int64List.fromList(ch.vibrationPattern!)
              : null,
        ),
      );
    }
  }

  @override
  Future<NotificationResult<void>> show(NotificationPayload payload) async {
    try {
      final channel = _config.getChannel(payload.channelId);
      if (channel == null) {
        return NotificationFailureResult(
          ChannelNotRegisteredFailure(payload.channelId),
        );
      }

      final soundName = payload.soundName ?? channel.soundName;
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
        playSound: !payload.silent && channel.playSound,
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
        presentSound: !payload.silent && channel.playSound,
        sound: hasSound
            ? soundName
            : null, // iOS uses filename; consumer must add it correctly
      );

      await _plugin.show(
        id: payload.id,
        title: payload.title,
        body: payload.body,
        notificationDetails: NotificationDetails(android: android, iOS: ios),
        payload: jsonEncode(payload.data),
      );

      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Show notification failed', e, s);
      return NotificationFailureResult(UnknownFailure('Show failed', e, s));
    }
  }

  Importance _mapImportance(ChannelImportance importance) =>
      switch (importance) {
        ChannelImportance.none => Importance.none,
        ChannelImportance.min => Importance.min,
        ChannelImportance.low => Importance.low,
        ChannelImportance.defaultImportance => Importance.defaultImportance,
        ChannelImportance.high => Importance.high,
        ChannelImportance.max => Importance.max,
      };

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
}
