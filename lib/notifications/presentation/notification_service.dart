import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_smart_notifications/notifications/domain/entities/notification_payload.dart';

import '../core/config/notification_config.dart';
import '../domain/entities/notification_result.dart';
import '../domain/entities/permission_status.dart';
import '../domain/entities/reminder_notification.dart';
import '../domain/entities/routing_event.dart';
import '../domain/entities/scheduled_notification.dart';
import '../domain/failures/notification_failure.dart';
import '../infrastructure/di/notification_service_factory.dart';
import 'dialogs/default_permission_dialog.dart';

/// Coordinates local notification permissions, display, and scheduling.
///
/// Create the active runtime with [create] or [initialize], then dispose it
/// before initializing the service with a different configuration.
class NotificationService with WidgetsBindingObserver {
  static NotificationService? _activeInstance;
  static NotificationConfig? _initializingConfig;
  static Future<NotificationResult<NotificationService>>? _initialization;
  static final NotificationService _uninitialized = NotificationService._();

  /// Active service, or an uninitialized instance whose operations return
  /// [NotInitializedFailure].
  static NotificationService get instance => _activeInstance ?? _uninitialized;

  NotificationServiceFactory? _factory;
  NotificationConfig? _config;
  bool _initialized = false;
  bool _disposed = false;
  NotificationPermissionStatus? _lastPermissionStatus;
  final StreamController<NotificationPermissionStatus>
  _permissionStatusController =
      StreamController<NotificationPermissionStatus>.broadcast();

  /// Whether this service has completed initialization and is not disposed.
  bool get isInitialized => _initialized;

  /// Stream of notification interactions routed by the active service.
  Stream<RoutingEvent> get onRoutingEvent =>
      _initialized ? _factory!.routingEvents.stream : const Stream.empty();

  /// Stream of permission states published by permission checks and requests.
  Stream<NotificationPermissionStatus> get onPermissionStatusChanged =>
      _initialized ? _permissionStatusController.stream : const Stream.empty();

  bool get _localEnabled =>
      _config?.isFeatureEnabled(NotificationFeature.localInstant) ?? false;
  bool get _scheduledEnabled =>
      _config?.isFeatureEnabled(NotificationFeature.localScheduled) ?? false;
  bool get _reminderEnabled =>
      _config?.isFeatureEnabled(NotificationFeature.localReminder) ?? false;

  NotificationService._();

  /// Creates and initializes the single active notification runtime.
  ///
  /// Repeated calls with the same configuration return the active service. A
  /// different configuration fails while another runtime is active.
  static Future<NotificationResult<NotificationService>> create(
    NotificationConfig config,
  ) {
    final active = _activeInstance;
    if (active != null) {
      if (identical(active._config, config)) {
        return Future.value(NotificationSuccess(active));
      }
      return Future.value(
        const NotificationFailureResult(
          NotificationLifecycleFailure(
            'A notification runtime is already active with another configuration',
          ),
        ),
      );
    }

    final pending = _initialization;
    if (pending != null) {
      if (identical(_initializingConfig, config)) return pending;
      return Future.value(
        const NotificationFailureResult(
          NotificationLifecycleFailure(
            'Notification initialization is already running with another configuration',
          ),
        ),
      );
    }

    _initializingConfig = config;
    final future = _create(config);
    _initialization = future;
    return future;
  }

  /// Initializes the service; equivalent to [create].
  static Future<NotificationResult<NotificationService>> initialize(
    NotificationConfig config,
  ) => create(config);

  static Future<NotificationResult<NotificationService>> _create(
    NotificationConfig config,
  ) async {
    final service = NotificationService._();
    service._config = config;
    service._factory = NotificationServiceFactory(config);

    try {
      final result = await service._factory!.initialize();
      if (result.isFailure) {
        await service._factory!.dispose();
        await service._permissionStatusController.close();
        return NotificationFailureResult(result.failureOrNull!);
      }
      service._initialized = true;
      WidgetsBinding.instance.addObserver(service);

      final initialPermission = await service.checkPermission();
      if (initialPermission.isFailure) {
        service._factory!.logger.warning(
          'Initial notification permission check failed: '
          '${initialPermission.failureOrNull}',
        );
      }

      if (config.permissionConfig.autoRequestOnInit) {
        final permission = await service.requestPermission();
        if (permission.isFailure) {
          service._factory!.logger.warning(
            'Automatic notification permission request failed: '
            '${permission.failureOrNull}',
          );
        }
      }
      _activeInstance = service;
      return NotificationSuccess(service);
    } catch (error, stackTrace) {
      if (service._initialized) {
        WidgetsBinding.instance.removeObserver(service);
        service._initialized = false;
      }
      await service._factory!.dispose();
      await service._permissionStatusController.close();
      return NotificationFailureResult(
        ProviderInitializationFailure(
          'Notification service initialization failed',
          error,
          stackTrace,
        ),
      );
    } finally {
      _initializingConfig = null;
      _initialization = null;
    }
  }

  /// Releases this runtime and its platform resources.
  ///
  /// Dispose the active service before creating one with a different
  /// configuration.
  Future<void> dispose() async {
    if (_disposed) return;
    final wasInitialized = _initialized;
    _disposed = true;
    _initialized = false;
    if (wasInitialized) WidgetsBinding.instance.removeObserver(this);
    await _factory?.dispose();
    await _permissionStatusController.close();
    if (identical(_activeInstance, this)) _activeInstance = null;
  }

  /// Reads the current notification permission state.
  Future<NotificationResult<NotificationPermissionStatus>>
  checkPermission() async {
    final failure = _precondition<NotificationPermissionStatus>();
    if (failure != null) return failure;
    if (!_hasAnyLocalFeature) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local features enabled)'),
      );
    }
    final result = await _factory!.permissionRepo.check();
    if (result.isSuccess) _publishPermissionStatus(result.valueOrNull!);
    return result;
  }

  /// Requests notification permission and returns the resulting state.
  ///
  /// When [context] is supplied, it can be used to show the configured
  /// explanation if permission must be changed in system settings. Set
  /// [includeExactAlarm] to also check and request Android exact-alarm access.
  Future<NotificationResult<NotificationPermissionStatus>> requestPermission({
    BuildContext? context,
    bool includeExactAlarm = false,
  }) async {
    final requestContext = context;
    final failure = _precondition<NotificationPermissionStatus>();
    if (failure != null) return failure;
    if (!_hasAnyLocalFeature) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local features enabled)'),
      );
    }

    var statusResult = await checkPermission();
    if (requestContext != null && !requestContext.mounted) {
      return _cancelledPermissionRequest();
    }
    if (statusResult.isFailure) return statusResult;

    var status = statusResult.valueOrNull!;
    if (!status.isGranted && status.canRequest) {
      final shouldRequest = await _shouldRequestNatively(status);
      if (requestContext != null && !requestContext.mounted) {
        return _cancelledPermissionRequest();
      }
      if (shouldRequest.isFailure) {
        return NotificationFailureResult(shouldRequest.failureOrNull!);
      }
      if (shouldRequest.valueOrNull!) {
        statusResult = await _factory!.permissionRepo.request();
        if (requestContext != null && !requestContext.mounted) {
          return _cancelledPermissionRequest();
        }
        if (statusResult.isFailure) return statusResult;
        status = statusResult.valueOrNull!;
        _publishPermissionStatus(status);
      }
    }

    if (!status.isGranted && !status.canRequest && requestContext != null) {
      final shouldShow = await _factory!.storage.shouldShowPermissionDialog(
        cooldown: _config!.permissionConfig.dialogCooldown,
      );
      if (!requestContext.mounted) return _cancelledPermissionRequest();
      if (shouldShow.isFailure) {
        return NotificationFailureResult(shouldShow.failureOrNull!);
      }

      if (shouldShow.valueOrNull!) {
        final dialog =
            _config!.permissionDialog ?? const DefaultPermissionDialog();
        final openSettings = await dialog.show(
          context: requestContext,
          title: _config!.permissionConfig.dialogTitle,
          message: _config!.permissionConfig.dialogMessage,
          openSettingsLabel: _config!.permissionConfig.openSettingsLabel,
          notNowLabel: _config!.permissionConfig.notNowLabel,
        );
        if (!requestContext.mounted) return _cancelledPermissionRequest();

        final dismissed = await _factory!.storage.recordPermissionPromptShown();
        if (!requestContext.mounted) return _cancelledPermissionRequest();
        if (dismissed.isFailure) {
          return NotificationFailureResult(dismissed.failureOrNull!);
        }

        if (openSettings) {
          final opened = await openNotificationSettings();
          if (!requestContext.mounted) {
            return _cancelledPermissionRequest();
          }
          if (opened.isFailure) {
            return NotificationFailureResult(opened.failureOrNull!);
          }
          await _waitForResume(_config!.permissionConfig.settingsReturnTimeout);
          if (!requestContext.mounted) {
            return _cancelledPermissionRequest();
          }
          statusResult = await checkPermission();
          if (!requestContext.mounted) {
            return _cancelledPermissionRequest();
          }
          if (statusResult.isFailure) return statusResult;
          status = statusResult.valueOrNull!;
        }
      }
    }

    if (!status.isGranted) return NotificationSuccess(status);

    if (includeExactAlarm) {
      final exact = await _factory!.permissionRepo.canScheduleExactAlarms();
      if (requestContext != null && !requestContext.mounted) {
        return _cancelledPermissionRequest();
      }
      if (exact.isFailure) {
        return NotificationFailureResult(exact.failureOrNull!);
      }
      if (!exact.valueOrNull!) {
        final request = await _factory!.permissionRepo
            .requestExactAlarmPermission();
        if (requestContext != null && !requestContext.mounted) {
          return _cancelledPermissionRequest();
        }
        if (request.isFailure || request.valueOrNull != true) {
          return const NotificationFailureResult(ExactAlarmPermissionFailure());
        }
        final confirmed = await _factory!.permissionRepo
            .canScheduleExactAlarms();
        if (requestContext != null && !requestContext.mounted) {
          return _cancelledPermissionRequest();
        }
        if (confirmed.isFailure || confirmed.valueOrNull != true) {
          return const NotificationFailureResult(ExactAlarmPermissionFailure());
        }
      }
    }

    return NotificationSuccess(status);
  }

  /// Opens this app's notification settings in the operating system.
  Future<NotificationResult<void>> openNotificationSettings() async {
    final failure = _precondition<void>();
    if (failure != null) return failure;
    if (!_hasAnyLocalFeature) {
      return const NotificationFailureResult(
        ProviderNotEnabledFailure('permission (no local features enabled)'),
      );
    }
    return _factory!.permissionRepo.openSettings();
  }

  /// Displays [payload] immediately.
  Future<NotificationResult<void>> showNotification(
    NotificationPayload payload,
  ) async {
    final failure = _precondition<void>(NotificationFeature.localInstant);
    if (failure != null) return failure;
    return _factory!.showInstantUseCase.call(payload);
  }

  /// Schedules [notification] for its configured time and recurrence.
  Future<NotificationResult<void>> scheduleNotification(
    ScheduledNotification notification,
  ) async {
    final failure = _precondition<void>(NotificationFeature.localScheduled);
    if (failure != null) return failure;
    return _factory!.scheduleUseCase.call(notification);
  }

  /// Cancels a scheduled notification by its identifier.
  Future<NotificationResult<void>> cancelScheduled(int id) async {
    final failure = _precondition<void>(NotificationFeature.localScheduled);
    if (failure != null) return failure;
    return _factory!.scheduledRepo.cancel(id);
  }

  /// Cancels all scheduled notifications.
  Future<NotificationResult<void>> cancelAllScheduled() async {
    final failure = _precondition<void>(NotificationFeature.localScheduled);
    if (failure != null) return failure;
    return _factory!.scheduledRepo.cancelAll();
  }

  /// Returns identifiers for notifications that are currently scheduled.
  Future<NotificationResult<List<int>>> getPendingScheduled() async {
    final failure = _precondition<List<int>>(
      NotificationFeature.localScheduled,
    );
    if (failure != null) return failure;
    return _factory!.scheduledRepo.getPendingIds();
  }

  /// Displays [reminder] immediately.
  Future<NotificationResult<void>> showReminder(
    ReminderNotification reminder,
  ) async {
    final failure = _precondition<void>(NotificationFeature.localReminder);
    if (failure != null) return failure;
    return _factory!.showReminderUseCase.call(reminder);
  }

  /// Schedules [reminder] according to its time and reminder options.
  Future<NotificationResult<void>> scheduleReminder(
    ReminderNotification reminder,
  ) async {
    final failure = _precondition<void>(NotificationFeature.localReminder);
    if (failure != null) return failure;
    return _factory!.scheduleReminderUseCase.call(reminder);
  }

  /// Cancels the reminder with identifier [id].
  Future<NotificationResult<void>> cancelReminder(int id) async {
    final failure = _precondition<void>(NotificationFeature.localReminder);
    if (failure != null) return failure;
    return _factory!.cancelReminderUseCase.call(id);
  }

  /// Cancels all active reminders.
  Future<NotificationResult<void>> cancelAllReminders() async {
    final failure = _precondition<void>(NotificationFeature.localReminder);
    if (failure != null) return failure;
    return _factory!.reminderRepo.cancelAll();
  }

  /// Cancels a local or scheduled notification with identifier [id].
  Future<NotificationResult<void>> cancelNotification(int id) async {
    final failure = _precondition<void>();
    if (failure != null) return failure;
    if (_localEnabled && _scheduledEnabled) {
      return _factory!.cancelUseCase.call(id);
    }
    if (_localEnabled) return _factory!.localRepo.cancel(id);
    if (_scheduledEnabled) return _factory!.scheduledRepo.cancel(id);
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('cancelNotification'),
    );
  }

  /// Cancels all notifications managed by the enabled local features.
  Future<NotificationResult<void>> cancelAll() async {
    final failure = _precondition<void>();
    if (failure != null) return failure;
    if (_localEnabled) {
      final result = await _factory!.localRepo.cancelAll();
      if (result.isFailure) return result;
    }
    if (_scheduledEnabled) {
      final result = await _factory!.scheduledRepo.cancelAll();
      if (result.isFailure) return result;
    }
    if (_reminderEnabled) {
      final result = await _factory!.reminderRepo.cancelAll();
      if (result.isFailure) return result;
    }
    return const NotificationSuccess(null);
  }

  bool get _hasAnyLocalFeature =>
      _localEnabled || _scheduledEnabled || _reminderEnabled;

  NotificationFailureResult<T>? _precondition<T>([
    NotificationFeature? feature,
  ]) {
    if (!_initialized || _disposed) {
      return const NotificationFailureResult(NotInitializedFailure());
    }
    if (feature != null && !_config!.enabledProviders.contains(feature)) {
      return NotificationFailureResult(ProviderNotEnabledFailure(feature.name));
    }
    return null;
  }

  NotificationFailureResult<NotificationPermissionStatus>
  _cancelledPermissionRequest() =>
      const NotificationFailureResult(PermissionRequestCancelledFailure());

  Future<NotificationResult<bool>> _shouldRequestNatively(
    NotificationPermissionStatus status,
  ) async {
    if (status is PermissionNotDetermined) {
      return const NotificationSuccess(true);
    }

    final denialCount = await _factory!.storage.getDenialCount();
    if (denialCount.isFailure) {
      return NotificationFailureResult(denialCount.failureOrNull!);
    }
    if (denialCount.valueOrNull == 0) {
      return const NotificationSuccess(true);
    }
    return _factory!.storage.shouldShowPermissionDialog(
      cooldown: _config!.permissionConfig.dialogCooldown,
    );
  }

  void _publishPermissionStatus(NotificationPermissionStatus status) {
    if (_lastPermissionStatus.runtimeType == status.runtimeType) return;
    _lastPermissionStatus = status;
    if (!_permissionStatusController.isClosed) {
      _permissionStatusController.add(status);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_initialized || _disposed) {
      return;
    }
    unawaited(_refreshPermissionStatus());
  }

  Future<void> _refreshPermissionStatus() async {
    final result = await checkPermission();
    if (result.isFailure) {
      _factory?.logger.warning(
        'Notification permission refresh failed: ${result.failureOrNull}',
      );
    }
  }

  Future<void> _waitForResume(Duration timeout) async {
    final observer = _AppResumeObserver();
    WidgetsBinding.instance.addObserver(observer);
    try {
      await observer.resumed.timeout(timeout, onTimeout: () {});
    } finally {
      WidgetsBinding.instance.removeObserver(observer);
    }
  }
}

class _AppResumeObserver with WidgetsBindingObserver {
  final Completer<void> _completer = Completer<void>();
  Future<void> get resumed => _completer.future;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_completer.isCompleted) {
      _completer.complete();
    }
  }
}
