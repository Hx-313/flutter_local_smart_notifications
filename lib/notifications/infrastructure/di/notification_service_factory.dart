import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/config/notification_config.dart';
import '../../core/logger/notification_logger.dart';
import '../../data/repositories/local/local_notification_repository_impl.dart'
    as local_repo;
import '../../data/repositories/permission/permission_repository.dart'
    as permission_repo;
import '../../data/repositories/reminder/reminder_notification_repository_impl.dart'
    as reminder_repo;
import '../../data/repositories/scheduled/scheduled_notification_repository_impl.dart'
    as scheduled_repo;
import '../../data/routing/routing_event_bus.dart';
import '../../data/storage/notification_storage_impl.dart';
import '../../domain/entities/notification_result.dart';
import '../../domain/failures/notification_failure.dart';
import '../../domain/repositories/i_local_notification_repository.dart';
import '../../domain/repositories/i_notification_logger.dart';
import '../../domain/repositories/i_notification_storage.dart';
import '../../domain/repositories/i_permission_repository.dart';
import '../../domain/repositories/i_reminder_notification_repository.dart';
import '../../domain/repositories/i_scheduled_notification_repository.dart';
import '../../domain/usecases/cancel_notification_usecase.dart';
import '../../domain/usecases/cancel_reminder_usecase.dart';
import '../../domain/usecases/schedule_notification_usecase.dart';
import '../../domain/usecases/schedule_reminder_usecase.dart';
import '../../domain/usecases/show_instant_notification_usecase.dart';
import '../../domain/usecases/show_reminder_usecase.dart';

class NotificationServiceFactory {
  final NotificationConfig config;
  final FlutterLocalNotificationsPlugin plugin;

  late final INotificationLogger logger;
  late final INotificationStorage storage;
  late final RoutingEventBus routingEvents;

  ILocalNotificationRepository? _localRepo;
  IScheduledNotificationRepository? _scheduledRepo;
  IReminderNotificationRepository? _reminderRepo;
  IPermissionRepository? _permissionRepo;

  NotificationServiceFactory(
    this.config, {
    FlutterLocalNotificationsPlugin? plugin,
    INotificationStorage? storage,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    logger = NotificationLogger(level: config.logLevel);
    this.storage = storage ?? NotificationStorageImpl();
    routingEvents = RoutingEventBus();
  }

  Future<NotificationResult<void>> initialize() async {
    final enabled = config.enabledProviders;
    try {
      final configurationFailure = _validateConfiguration();
      if (configurationFailure != null) {
        return NotificationFailureResult(configurationFailure);
      }

      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        return NotificationFailureResult(
          UnsupportedPlatformFailure(defaultTargetPlatform.name),
        );
      }

      if (enabled.isNotEmpty) {
        _permissionRepo = permission_repo.PermissionRepositoryImpl(
          config: config,
          logger: logger,
          storage: storage,
          plugin: plugin,
        );
      }

      // All local features share one initialized plugin and its channels/tap
      // callbacks, even when instant notifications are not exposed publicly.
      if (enabled.isNotEmpty) {
        _localRepo = local_repo.LocalNotificationRepositoryImpl(
          config: config,
          logger: logger,
          routingEvents: routingEvents,
          plugin: plugin,
        );
        final result = await _localRepo!.initialize();
        if (result.isFailure) return result;
      }

      if (enabled.contains(NotificationFeature.localScheduled)) {
        _scheduledRepo = scheduled_repo.ScheduledNotificationRepositoryImpl(
          config: config,
          logger: logger,
          plugin: plugin,
          permissions: _permissionRepo!,
        );
        final result = await _scheduledRepo!.initialize();
        if (result.isFailure) return result;
      }

      if (enabled.contains(NotificationFeature.localReminder)) {
        _reminderRepo = reminder_repo.ReminderNotificationRepositoryImpl(
          config: config,
          storage: storage,
          logger: logger,
          plugin: plugin,
          permissions: _permissionRepo!,
        );
        final result = await _reminderRepo!.initialize();
        if (result.isFailure) return result;
        if (config.reminderConfig.persistAcrossReboot) {
          final restore = await _reminderRepo!.rescheduleAllPersisted();
          if (restore.isFailure) return restore;
        }
      }

      final pendingEvents = await storage.consumePendingRoutingEvents();
      if (pendingEvents.isFailure) {
        return NotificationFailureResult(pendingEvents.failureOrNull!);
      }
      routingEvents.addAll(pendingEvents.valueOrNull!);

      logger.info('NotificationServiceFactory initialized');
      return const NotificationSuccess(null);
    } catch (error, stackTrace) {
      logger.error(
        'NotificationServiceFactory initialization failed',
        error,
        stackTrace,
      );
      return NotificationFailureResult(
        ProviderInitializationFailure(
          'Notification service initialization failed',
          error,
          stackTrace,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await routingEvents.dispose();
  }

  NotificationFailure? _validateConfiguration() {
    if (config.enabledProviders.isEmpty) {
      return const InvalidNotificationConfigurationFailure(
        'At least one notification feature must be enabled',
      );
    }
    if (config.channels.isEmpty) {
      return const InvalidNotificationConfigurationFailure(
        'At least one notification channel must be configured',
      );
    }

    final ids = <String>{};
    for (final channel in config.channels) {
      if (channel.id.trim().isEmpty) {
        return const InvalidNotificationConfigurationFailure(
          'Notification channel ids cannot be empty',
        );
      }
      if (!ids.add(channel.id)) {
        return InvalidNotificationConfigurationFailure(
          'Duplicate notification channel id: ${channel.id}',
        );
      }
    }

    final reminders = config.reminderConfig;
    if (reminders.maxActiveReminders <= 0 ||
        reminders.maxPendingNotifications <= 0) {
      return const InvalidNotificationConfigurationFailure(
        'Notification limits must be greater than zero',
      );
    }
    if (reminders.iosReservedSlots < 0 || reminders.iosReservedSlots >= 64) {
      return const InvalidNotificationConfigurationFailure(
        'iosReservedSlots must be between 0 and 63',
      );
    }

    final permissions = config.permissionConfig;
    if (permissions.denialsBeforeSettings < 1 ||
        permissions.dialogCooldown.isNegative ||
        permissions.settingsReturnTimeout <= Duration.zero) {
      return const InvalidNotificationConfigurationFailure(
        'Permission retry and timeout values are invalid',
      );
    }
    return null;
  }

  ILocalNotificationRepository get localRepo =>
      _localRepo ?? (throw StateError('localInstant not enabled'));
  IScheduledNotificationRepository get scheduledRepo =>
      _scheduledRepo ?? (throw StateError('localScheduled not enabled'));
  IReminderNotificationRepository get reminderRepo =>
      _reminderRepo ?? (throw StateError('localReminder not enabled'));
  IPermissionRepository get permissionRepo =>
      _permissionRepo ??
      (throw StateError('No local notification feature enabled'));

  ShowInstantNotificationUseCase get showInstantUseCase =>
      ShowInstantNotificationUseCase(localRepo, config.channelIds);
  ScheduleNotificationUseCase get scheduleUseCase =>
      ScheduleNotificationUseCase(scheduledRepo, config.channelIds);
  CancelNotificationUseCase get cancelUseCase =>
      CancelNotificationUseCase(localRepo, scheduledRepo);
  ShowReminderUseCase get showReminderUseCase =>
      ShowReminderUseCase(reminderRepo, config.channelIds);
  ScheduleReminderUseCase get scheduleReminderUseCase =>
      ScheduleReminderUseCase(
        reminderRepo,
        storage,
        config.channelIds,
        config.reminderConfig.maxActiveReminders,
      );
  CancelReminderUseCase get cancelReminderUseCase =>
      CancelReminderUseCase(reminderRepo, storage);
}
