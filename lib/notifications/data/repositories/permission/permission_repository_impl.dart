import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

import '../../../core/config/notification_config.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/entities/permission_status.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_notification_logger.dart';
import '../../../domain/repositories/i_notification_storage.dart';
import '../../../domain/repositories/i_permission_repository.dart';

class PermissionRepositoryImpl implements IPermissionRepository {
  PermissionRepositoryImpl({
    required FlutterLocalNotificationsPlugin plugin,
    required NotificationConfig config,
    required INotificationLogger logger,
    required INotificationStorage storage,
    DeviceInfoPlugin? deviceInfo,
  }) : _plugin = plugin,
       _config = config,
       _logger = logger,
       _storage = storage,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationConfig _config;
  final INotificationLogger _logger;
  final INotificationStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<NotificationResult<NotificationPermissionStatus>> check() async {
    try {
      NotificationResult<NotificationPermissionStatus> result;
      if (Platform.isAndroid) {
        result = await _checkAndroid();
      } else if (Platform.isIOS || Platform.isMacOS) {
        result = await _checkApplePlatform();
      } else {
        result = const NotificationSuccess(PermissionGranted());
      }
      if (result.isFailure) return result;
      return await _applyPersistedDenialState(result.valueOrNull!);
    } catch (error, stackTrace) {
      _logger.error('Permission check failed', error, stackTrace);
      return NotificationFailureResult(
        UnknownFailure('Permission check failed', error, stackTrace),
      );
    }
  }

  @override
  Future<NotificationResult<NotificationPermissionStatus>> request() async {
    try {
      final saved = await _storage.savePermissionAsked(true);
      if (saved.isFailure) {
        return NotificationFailureResult(saved.failureOrNull!);
      }
      final recorded = await _storage.recordPermissionPromptShown();
      if (recorded.isFailure) {
        return NotificationFailureResult(recorded.failureOrNull!);
      }

      NotificationPermissionStatus status;
      if (Platform.isAndroid) {
        status = await _requestAndroid();
      } else if (Platform.isIOS || Platform.isMacOS) {
        status = await _requestApplePlatform();
      } else {
        status = const PermissionGranted();
      }

      if (!status.isGranted) return await _recordDenial(status);
      final reset = await _storage.resetDenialCount();
      if (reset.isFailure) {
        return NotificationFailureResult(reset.failureOrNull!);
      }
      return NotificationSuccess(status);
    } catch (error, stackTrace) {
      _logger.error('Permission request failed', error, stackTrace);
      return NotificationFailureResult(
        UnknownFailure('Permission request failed', error, stackTrace),
      );
    }
  }

  @override
  Future<NotificationResult<void>> openSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return const NotificationSuccess(null);
    } catch (error, stackTrace) {
      _logger.error('Open notification settings failed', error, stackTrace);
      return NotificationFailureResult(
        UnknownFailure('Open notification settings failed', error, stackTrace),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> canScheduleExactAlarms() async {
    try {
      if (!Platform.isAndroid || await _androidSdkVersion() < 31) {
        return const NotificationSuccess(true);
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final allowed = await android?.canScheduleExactNotifications() ?? false;
      return NotificationSuccess(allowed);
    } catch (error, stackTrace) {
      _logger.error('Exact alarm permission check failed', error, stackTrace);
      return NotificationFailureResult(
        UnknownFailure(
          'Exact alarm permission check failed',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> requestExactAlarmPermission() async {
    try {
      if (!Platform.isAndroid || await _androidSdkVersion() < 31) {
        return const NotificationSuccess(true);
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final request = android?.requestExactAlarmsPermission();
      final allowed =
          await request?.timeout(
            _config.permissionConfig.settingsReturnTimeout,
            onTimeout: () => false,
          ) ??
          false;
      return NotificationSuccess(allowed);
    } catch (error, stackTrace) {
      _logger.error('Exact alarm permission request failed', error, stackTrace);
      return const NotificationFailureResult(ExactAlarmPermissionFailure());
    }
  }

  Future<NotificationResult<NotificationPermissionStatus>>
  _checkAndroid() async {
    final sdk = await _androidSdkVersion();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsEnabled =
        await android?.areNotificationsEnabled() ?? false;

    if (sdk < 33) {
      return NotificationSuccess(
        notificationsEnabled
            ? const PermissionGranted()
            : const PermissionPermanentlyDenied(),
      );
    }

    final askedResult = await _storage.hasPermissionBeenAsked();
    if (askedResult.isFailure) {
      return NotificationFailureResult(askedResult.failureOrNull!);
    }

    final platformStatus =
        await permission_handler.Permission.notification.status;
    if (notificationsEnabled && platformStatus.isGranted) {
      return const NotificationSuccess(PermissionGranted());
    }
    if (!askedResult.valueOrNull! && platformStatus.isDenied) {
      return const NotificationSuccess(PermissionNotDetermined());
    }
    return NotificationSuccess(_mapStatus(platformStatus));
  }

  Future<NotificationResult<NotificationPermissionStatus>>
  _checkApplePlatform() async {
    final askedResult = await _storage.hasPermissionBeenAsked();
    if (askedResult.isFailure) {
      return NotificationFailureResult(askedResult.failureOrNull!);
    }

    final platformStatus =
        await permission_handler.Permission.notification.status;
    if (!askedResult.valueOrNull! && platformStatus.isDenied) {
      return const NotificationSuccess(PermissionNotDetermined());
    }
    return NotificationSuccess(_mapStatus(platformStatus));
  }

  Future<NotificationPermissionStatus> _requestAndroid() async {
    if (await _androidSdkVersion() < 33) {
      final result = await _checkAndroid();
      return result.valueOrNull ?? const PermissionPermanentlyDenied();
    }

    final status = await permission_handler.Permission.notification.request();
    return _mapStatus(status);
  }

  Future<NotificationPermissionStatus> _requestApplePlatform() async {
    bool granted;
    if (Platform.isIOS) {
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
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      granted =
          await macos?.requestPermissions(
            alert: _config.permissionConfig.requestAlert,
            badge: _config.permissionConfig.requestBadge,
            sound: _config.permissionConfig.requestSound,
            critical: _config.permissionConfig.requestCriticalAlert,
          ) ??
          false;
    }

    final status = await permission_handler.Permission.notification.status;
    if (granted && status.isDenied) return const PermissionGranted();
    return _mapStatus(status);
  }

  Future<NotificationResult<NotificationPermissionStatus>> _recordDenial(
    NotificationPermissionStatus status,
  ) async {
    final incremented = await _storage.incrementDenialCount();
    if (incremented.isFailure) {
      return NotificationFailureResult(incremented.failureOrNull!);
    }

    if (status is PermissionPermanentlyDenied ||
        status is PermissionRestricted) {
      return NotificationSuccess(status);
    }

    final countResult = await _storage.getDenialCount();
    if (countResult.isFailure) {
      return NotificationFailureResult(countResult.failureOrNull!);
    }
    if (countResult.valueOrNull! >=
        _config.permissionConfig.denialsBeforeSettings) {
      return const NotificationSuccess(PermissionPermanentlyDenied());
    }
    return NotificationSuccess(status);
  }

  Future<NotificationResult<NotificationPermissionStatus>>
  _applyPersistedDenialState(NotificationPermissionStatus status) async {
    if (status.isGranted) {
      final reset = await _storage.resetDenialCount();
      if (reset.isFailure) {
        return NotificationFailureResult(reset.failureOrNull!);
      }
      return NotificationSuccess(status);
    }
    if (status is PermissionPermanentlyDenied ||
        status is PermissionRestricted) {
      return NotificationSuccess(status);
    }

    final countResult = await _storage.getDenialCount();
    if (countResult.isFailure) {
      return NotificationFailureResult(countResult.failureOrNull!);
    }
    if (countResult.valueOrNull! >=
        _config.permissionConfig.denialsBeforeSettings) {
      return const NotificationSuccess(PermissionPermanentlyDenied());
    }
    return NotificationSuccess(status);
  }

  NotificationPermissionStatus _mapStatus(
    permission_handler.PermissionStatus status,
  ) {
    if (status.isGranted || status.isLimited) {
      return const PermissionGranted();
    }
    if (status.isProvisional) return const PermissionProvisional();
    if (status.isPermanentlyDenied) {
      return const PermissionPermanentlyDenied();
    }
    if (status.isRestricted) return const PermissionRestricted();
    return const PermissionDenied();
  }

  Future<int> _androidSdkVersion() async {
    final info = await _deviceInfo.androidInfo;
    return info.version.sdkInt;
  }
}
