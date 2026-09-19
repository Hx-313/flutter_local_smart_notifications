// lib/services/notifications/presentation/notification_service.dart
// PRESENTATION | Public API facade - the ONLY surface the consumer touches

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/notification_config.dart';
import '../domain/entities/notification_payload.dart';
import '../domain/entities/notification_result.dart';
import '../domain/entities/permission_status.dart';
import '../domain/entities/reminder_notification.dart';
import '../domain/entities/routing_event.dart';
import '../domain/entities/scheduled_notification.dart';
import '../domain/failures/notification_failure.dart';
import '../infrastructure/di/notification_service_factory.dart';
import 'dialogs/default_permission_dialog.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ?? (throw StateError('NotificationService not initialized'));

  NotificationServiceFactory? _factory;
  NotificationConfig? _config;

  bool _initialized = false;
  bool _streamsWired = false;

  // Streams
  final StreamController<NotificationPayload> _receivedController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<NotificationPayload> _tappedController =
      StreamController<NotificationPayload>.broadcast();
  final StreamController<Map<String, dynamic>> _silentPushController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<NotificationPayload> get onNotificationReceived =>
      _receivedController.stream;
  Stream<NotificationPayload> get onNotificationTapped =>
      _tappedController.stream;
  Stream<Map<String, dynamic>> get onSilentPush => _silentPushController.stream;

  Stream<RoutingEvent> get onRoutingEvent {
    _ensureInitialized();
    return _factory!.routingController.stream;
  }

  Stream<String> get onFCMTokenRefresh {
    _ensureInitialized();
    return _fcmEnabled
        ? _factory!.refreshFcmTokenUseCase.call()
        : const Stream.empty();
  }

  bool get _localEnabled =>
      _config?.isProviderEnabled(NotificationProvider.localInstant) ?? false;
  bool get _scheduledEnabled =>
      _config?.isProviderEnabled(NotificationProvider.localScheduled) ?? false;
  bool get _reminderEnabled =>
      _config?.isProviderEnabled(NotificationProvider.localReminder) ?? false;
  bool get _fcmEnabled =>
      _config?.isProviderEnabled(NotificationProvider.fcm) ?? false;
  bool get _oneSignalEnabled =>
      _config?.isProviderEnabled(NotificationProvider.oneSignal) ?? false;

  NotificationService._();

  static Future<NotificationService> initialize(
    NotificationConfig config,
  ) async {
    if (_instance != null && _instance!._initialized) {
      _instance!._factory?.logger.warning(
        'NotificationService already initialized',
      );
      return _instance!;
    }

    _instance = NotificationService._();
    _instance!._config = config;
    _instance!._factory = NotificationServiceFactory(config);

    await _instance!._factory!.initialize();
    _instance!._wireStreams();

    _instance!._initialized = true;
    _instance!._factory!.logger.info('NotificationService initialized');

    if (config.permissionConfig.autoRequestOnInit) {
      await _instance!.requestPermission();
    }

    return _instance!;
  }

  void _wireStreams() {
    if (_streamsWired) return;

    if (_fcmEnabled) {
      _factory!.fcmRepo.onForegroundMessage.listen(_receivedController.add);
      _factory!.fcmRepo.onBackgroundMessageTap.listen(_tappedController.add);
    }

    if (_oneSignalEnabled) {
      _factory!.oneSignalRepo.onNotificationReceived.listen(
        _receivedController.add,
      );
      _factory!.oneSignalRepo.onNotificationTapped.listen(
        _tappedController.add,
      );
    }

    _streamsWired = true;
  }

  Future<void> dispose() async {
    await _factory?.dispose();
    await _receivedController.close();
    await _tappedController.close();
    await _silentPushController.close();

    _initialized = false;
    _streamsWired = false;
    _instance = null;
  }

  // Permissions
  Future<NotificationResult<PermissionStatus>> checkPermission() async {
    _ensureInitialized();
    if (!_hasAnyLocalProvider) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local providers enabled)'),
      );
    }
    return _factory!.checkPermissionUseCase.call();
  }

  Future<NotificationResult<PermissionStatus>> requestPermission({
    BuildContext? context,
  }) async {
    _ensureInitialized();

    if (!_hasAnyLocalProvider) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local providers enabled)'),
      );
    }

    final beforeResult = await _factory!.checkPermissionUseCase.call();
    if (beforeResult.isFailure) return beforeResult;

    final before = beforeResult.valueOrNull!;
    if (before.isGranted) return beforeResult;

    // First try native permission request.
    final requestResult = await _factory!.requestPermissionUseCase.call();
    if (requestResult.isFailure) return requestResult;

    final afterResult = await _factory!.checkPermissionUseCase.call();
    if (afterResult.isFailure) return afterResult;

    final after = afterResult.valueOrNull!;
    if (after.isGranted) return afterResult;

    // Only now show UI that opens settings.
    // Use your own domain fields here if you have permanentlyDenied/settingsRequired.
    if (context != null) {
      final dialog =
          _config!.permissionDialog ?? const DefaultPermissionDialog();

      final openSettings = await dialog.show(
        context: context,
        title: _config!.permissionConfig.dialogTitle,
        message: _config!.permissionConfig.dialogMessage,
        openSettingsLabel: _config!.permissionConfig.openSettingsLabel,
        notNowLabel: _config!.permissionConfig.notNowLabel,
      );

      if (openSettings) {
        await openNotificationSettings();
      }
    }

    return afterResult;
  }

  Future<NotificationResult<void>> openNotificationSettings() async {
    _ensureInitialized();
    if (!_hasAnyLocalProvider) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local providers enabled)'),
      );
    }
    return _factory!.openSettingsUseCase.call();
  }

  // Local instant
  Future<NotificationResult<void>> showNotification(
    NotificationPayload payload,
  ) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localInstant);
    return _factory!.showInstantUseCase.call(payload);
  }

  // Scheduled
  Future<NotificationResult<void>> scheduleNotification(
    ScheduledNotification notification,
  ) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localScheduled);
    return _factory!.scheduleUseCase.call(notification);
  }

  Future<NotificationResult<void>> cancelScheduled(int id) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localScheduled);
    return _factory!.scheduledRepo.cancel(id);
  }

  Future<NotificationResult<void>> cancelAllScheduled() async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localScheduled);
    return _factory!.cancelAllScheduledUseCase.call();
  }

  Future<NotificationResult<List<int>>> getPendingScheduled() async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localScheduled);
    return _factory!.getPendingUseCase.call();
  }

  // Reminders
  Future<NotificationResult<void>> showReminder(
    ReminderNotification reminder,
  ) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localReminder);
    return _factory!.showReminderUseCase.call(reminder);
  }

  Future<NotificationResult<void>> scheduleReminder(
    ReminderNotification reminder,
  ) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localReminder);
    return _factory!.scheduleReminderUseCase.call(reminder);
  }

  Future<NotificationResult<void>> cancelReminder(int id) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localReminder);
    return _factory!.cancelReminderUseCase.call(id);
  }

  Future<NotificationResult<void>> cancelAllReminders() async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.localReminder);
    return _factory!.reminderRepo.cancelAll();
  }

  // FCM
  Future<NotificationResult<String>> getFCMToken() async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.fcm);
    return _factory!.getFcmTokenUseCase.call();
  }

  Future<NotificationResult<void>> subscribeToTopic(String topic) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.fcm);
    return _factory!.subscribeToTopicUseCase.call(topic);
  }

  Future<NotificationResult<void>> unsubscribeFromTopic(String topic) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.fcm);
    return _factory!.unsubscribeFromTopicUseCase.call(topic);
  }

  // OneSignal
  Future<NotificationResult<void>> setOneSignalExternalUserId(
    String userId,
  ) async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.oneSignal);
    return _factory!.oneSignalSubscriptionUseCase.setExternalUserId(userId);
  }

  Future<NotificationResult<void>> removeOneSignalExternalUserId() async {
    _ensureInitialized();
    _ensureProvider(NotificationProvider.oneSignal);
    return _factory!.oneSignalSubscriptionUseCase.removeExternalUserId();
  }

  // Management
  Future<NotificationResult<void>> cancelNotification(int id) async {
    _ensureInitialized();

    // Cancel can be supported if either localInstant or localScheduled is enabled
    if (_localEnabled && _scheduledEnabled) {
      return _factory!.cancelUseCase.call(id);
    }
    if (_localEnabled) return _factory!.localRepo.cancel(id);
    if (_scheduledEnabled) return _factory!.scheduledRepo.cancel(id);

    return const NotificationFailureResult(
      ProviderNotEnabledFailure('cancelNotification'),
    );
  }

  Future<NotificationResult<void>> cancelAll() async {
    _ensureInitialized();
    if (_localEnabled) await _factory!.localRepo.cancelAll();
    if (_scheduledEnabled) await _factory!.scheduledRepo.cancelAll();
    if (_reminderEnabled) await _factory!.reminderRepo.cancelAll();
    return const NotificationSuccess(null);
  }

  // Helpers
  bool get _hasAnyLocalProvider =>
      _localEnabled || _scheduledEnabled || _reminderEnabled;

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'NotificationService not initialized. Call NotificationService.initialize() first.',
      );
    }
  }

  void _ensureProvider(NotificationProvider provider) {
    if (!_config!.isProviderEnabled(provider)) {
      throw StateError('Provider ${provider.name} not enabled in config');
    }
  }
}
