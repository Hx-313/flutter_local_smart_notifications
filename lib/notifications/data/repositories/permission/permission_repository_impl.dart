
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/permission_status.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_notification_logger.dart';
import '../../../domain/repositories/i_notification_storage.dart';
import '../../../domain/repositories/i_permission_repository.dart';

class PermissionRepositoryImpl implements IPermissionRepository {
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationConfig _config;
  final INotificationLogger _logger;
  final INotificationStorage _storage;

  PermissionRepositoryImpl({
    required FlutterLocalNotificationsPlugin plugin,
    required NotificationConfig config,
    required INotificationLogger logger,
    required INotificationStorage storage,
  }) : _plugin = plugin,
       _config = config,
       _logger = logger,
       _storage = storage;

  @override
  Future<NotificationResult<PermissionStatus>> check() async {
    try {
      final askedResult = await _storage.hasPermissionBeenAsked();
      final denialCountResult = await _storage.getDenialCount();

      final asked = askedResult.isSuccess ? askedResult.valueOrNull! : false;
      final denialCount = denialCountResult.isSuccess
          ? denialCountResult.valueOrNull!
          : 0;

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final enabled = await android?.areNotificationsEnabled() ?? false;

        if (enabled) return const NotificationSuccess(PermissionGranted());
        if (!asked) return const NotificationSuccess(PermissionNotDetermined());

        // Approximation: after multiple denials, treat as permanently denied.
        if (denialCount >= 2) {
          return const NotificationSuccess(PermissionPermanentlyDenied());
        }
        return const NotificationSuccess(PermissionDenied());
      }

      if (Platform.isIOS) {
        // iOS: no reliable "pure check" in flutter_local_notifications.
        // We use persisted asked/denialCount to return correct UX states.
        if (!asked) return const NotificationSuccess(PermissionNotDetermined());

        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        // Best-effort probe: requestPermissions with all false should not prompt.
        final granted =
            await ios?.requestPermissions(
              alert: false,
              badge: false,
              sound: false,
              provisional: false,
              critical: false,
            ) ??
            false;

        if (granted) return const NotificationSuccess(PermissionGranted());

        if (denialCount >= 2) {
          return const NotificationSuccess(PermissionPermanentlyDenied());
        }
        return const NotificationSuccess(PermissionDenied());
      }

      return const NotificationSuccess(PermissionGranted());
    } catch (e, s) {
      _logger.error('Permission check failed', e, s);
      return NotificationFailureResult(
        UnknownFailure('Permission check failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<PermissionStatus>> request() async {
    try {
      await _storage.savePermissionAsked(true);

      bool granted = false;

      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        granted = await android?.requestNotificationsPermission() ?? false;
      } else if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        granted =
            await ios?.requestPermissions(
              alert: _config.permissionConfig.requestAlert,
              badge: _config.permissionConfig.requestBadge,
              sound: _config.permissionConfig.requestSound,
              provisional: _config.permissionConfig.requestProvisional,
              critical: _config.permissionConfig.requestCriticalAlert,
            ) ??
            false;
      } else {
        granted = true;
      }

      if (!granted) {
        await _storage.incrementDenialCount();
        final denialCountResult = await _storage.getDenialCount();
        final denialCount = denialCountResult.isSuccess
            ? denialCountResult.valueOrNull!
            : 0;

        if (denialCount >= 2) {
          return const NotificationSuccess(PermissionPermanentlyDenied());
        }
        return const NotificationSuccess(PermissionDenied());
      }

      return const NotificationSuccess(PermissionGranted());
    } catch (e, s) {
      _logger.error('Permission request failed', e, s);
      return NotificationFailureResult(
        UnknownFailure('Permission request failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> openSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return const NotificationSuccess(null);
    } catch (e, s) {
      _logger.error('Open settings failed', e, s);
      return NotificationFailureResult(
        UnknownFailure('Open settings failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> canScheduleExactAlarms() async {
    try {
      if (!Platform.isAndroid) return const NotificationSuccess(true);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final can = await android?.canScheduleExactNotifications() ?? false;
      return NotificationSuccess(can);
    } catch (e, s) {
      _logger.error('canScheduleExactAlarms failed', e, s);
      return NotificationFailureResult(
        UnknownFailure('canScheduleExactAlarms failed', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> requestExactAlarmPermission() async {
    try {
      if (!Platform.isAndroid) return const NotificationSuccess(true);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestExactAlarmsPermission() ?? false;
      return NotificationSuccess(granted);
    } catch (e, s) {
      _logger.error('requestExactAlarmPermission failed', e, s);
      return const NotificationFailureResult(ExactAlarmPermissionFailure());
    }
  }
}
