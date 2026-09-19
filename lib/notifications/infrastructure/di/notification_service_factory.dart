// lib/services/notifications/infrastructure/di/notification_service_factory.dart
// INFRASTRUCTURE | DI factory with conditional provider loading

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/config/notification_config.dart';
import '../../core/logger/notification_logger.dart';
import '../../data/repositories/local/local_notification_repository_impl.dart'
    as local_repo;
import '../../data/repositories/permission/permission_repository_impl.dart'
    as permission_repo;
import '../../data/repositories/reminder/reminder_notification_repository_impl.dart'
    as reminder_repo;
import '../../data/repositories/scheduled/scheduled_notification_repository_impl.dart'
    as scheduled_repo;
import '../../data/storage/notification_storage_impl.dart';
import '../../domain/entities/routing_event.dart';
import '../../domain/repositories/i_fcm_repository.dart';
import '../../domain/repositories/i_local_notification_repository.dart';
import '../../domain/repositories/i_notification_logger.dart';
import '../../domain/repositories/i_notification_storage.dart';
import '../../domain/repositories/i_one_signal_repository.dart';
import '../../domain/repositories/i_permission_repository.dart';
import '../../domain/repositories/i_reminder_notification_repository.dart';
import '../../domain/repositories/i_scheduled_notification_repository.dart';
import '../../domain/usecases/cancel_all_scheduled_usecase.dart';
import '../../domain/usecases/cancel_notification_usecase.dart';
import '../../domain/usecases/cancel_reminder_usecase.dart';
import '../../domain/usecases/check_permission_usecase.dart';
import '../../domain/usecases/get_fcm_token_usecase.dart';
import '../../domain/usecases/get_pending_scheduled_usecase.dart';
import '../../domain/usecases/manage_one_signal_subscription_usecase.dart';
import '../../domain/usecases/open_notification_settings_usecase.dart';
import '../../domain/usecases/refresh_fcm_token_usecase.dart';
import '../../domain/usecases/request_permission_usecase.dart';
import '../../domain/usecases/schedule_notification_usecase.dart';
import '../../domain/usecases/schedule_reminder_usecase.dart';
import '../../domain/usecases/show_instant_notification_usecase.dart';
import '../../domain/usecases/show_reminder_usecase.dart'
    show ShowReminderUseCase;
import '../../domain/usecases/subscribe_to_topic_usecase.dart';
import '../../domain/usecases/unsubscribe_from_topic_usecase.dart';

class NotificationServiceFactory {
  final NotificationConfig config;

  late final INotificationLogger logger;
  late final INotificationStorage storage;
  late final StreamController<RoutingEvent> routingController;

  ILocalNotificationRepository? _localRepo;
  IScheduledNotificationRepository? _scheduledRepo;
  IReminderNotificationRepository? _reminderRepo;
  IPermissionRepository? _permissionRepo;
  IFcmRepository? _fcmRepo;
  IOneSignalRepository? _oneSignalRepo;

  NotificationServiceFactory(this.config) {
    logger = NotificationLogger(level: config.logLevel);
    storage = NotificationStorageImpl();
    routingController = StreamController<RoutingEvent>.broadcast();
  }

  Future<void> initialize() async {
    final enabled = config.enabledProviders;

    // Local Instant
    if (enabled.contains(NotificationProvider.localInstant)) {
      _localRepo = local_repo.LocalNotificationRepositoryImpl(
        config: config,
        logger: logger,
        routingController: routingController,
      );
      await _localRepo!.initialize();
    }

    // Scheduled
    if (enabled.contains(NotificationProvider.localScheduled)) {
      _scheduledRepo = scheduled_repo.ScheduledNotificationRepositoryImpl(
        config: config,
        logger: logger,
        routingController: routingController,
      );
      await _scheduledRepo!.initialize();
    }

    // Reminder
    if (enabled.contains(NotificationProvider.localReminder)) {
      _reminderRepo = reminder_repo.ReminderNotificationRepositoryImpl(
        config: config,
        storage: storage,
        logger: logger,
        routingController: routingController,
      );
      await _reminderRepo!.initialize();

      // Reboot survival re-schedule
      if (config.reminderConfig.persistAcrossReboot) {
        await _reminderRepo!.rescheduleAllPersisted();
      }
    }

    // Permission (available if any local provider enabled)
    if (enabled.contains(NotificationProvider.localInstant) ||
        enabled.contains(NotificationProvider.localScheduled) ||
        enabled.contains(NotificationProvider.localReminder)) {
      _permissionRepo = permission_repo.PermissionRepositoryImpl(
        config: config,
        logger: logger,
        storage: storage,
        plugin: FlutterLocalNotificationsPlugin(),
      );
    }

    // FCM
    if (enabled.contains(NotificationProvider.fcm)) {
      await _fcmRepo!.initialize();
    }

    // OneSignal
    // if (enabled.contains(NotificationProvider.oneSignal)) {
    //   _oneSignalRepo = one_signal_repo.OneSignalRepositoryImpl(
    //     config: config,
    //     logger: logger,
    //   );
    //   await _oneSignalRepo!.initialize();
    // }

    logger.info('NotificationServiceFactory initialized');
  }

  Future<void> dispose() async {
    await _fcmRepo?.dispose();
    await _oneSignalRepo?.dispose();
    await routingController.close();
  }

  // Repository getters
  ILocalNotificationRepository get localRepo =>
      _localRepo ?? (throw StateError('localInstant not enabled'));

  IScheduledNotificationRepository get scheduledRepo =>
      _scheduledRepo ?? (throw StateError('localScheduled not enabled'));

  IReminderNotificationRepository get reminderRepo =>
      _reminderRepo ?? (throw StateError('localReminder not enabled'));

  IPermissionRepository get permissionRepo =>
      _permissionRepo ??
      (throw StateError(
        'Permission not available (no local provider enabled)',
      ));

  IFcmRepository get fcmRepo =>
      _fcmRepo ?? (throw StateError('fcm not enabled'));

  IOneSignalRepository get oneSignalRepo =>
      _oneSignalRepo ?? (throw StateError('oneSignal not enabled'));

  // Use case getters (NotificationService depends on these)
  ShowInstantNotificationUseCase get showInstantUseCase =>
      ShowInstantNotificationUseCase(localRepo, config.channelIds);

  ScheduleNotificationUseCase get scheduleUseCase =>
      ScheduleNotificationUseCase(scheduledRepo, config.channelIds);

  CancelNotificationUseCase get cancelUseCase =>
      CancelNotificationUseCase(localRepo, scheduledRepo);

  CancelAllScheduledUseCase get cancelAllScheduledUseCase =>
      CancelAllScheduledUseCase(scheduledRepo);

  GetPendingScheduledUseCase get getPendingUseCase =>
      GetPendingScheduledUseCase(scheduledRepo);

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

  CheckPermissionUseCase get checkPermissionUseCase =>
      CheckPermissionUseCase(permissionRepo);

  RequestPermissionUseCase get requestPermissionUseCase =>
      RequestPermissionUseCase(permissionRepo, storage);

  OpenNotificationSettingsUseCase get openSettingsUseCase =>
      OpenNotificationSettingsUseCase(permissionRepo);

  GetFcmTokenUseCase get getFcmTokenUseCase =>
      GetFcmTokenUseCase(fcmRepo, storage);

  RefreshFcmTokenUseCase get refreshFcmTokenUseCase =>
      RefreshFcmTokenUseCase(fcmRepo, storage);

  SubscribeToTopicUseCase get subscribeToTopicUseCase =>
      SubscribeToTopicUseCase(fcmRepo);

  UnsubscribeFromTopicUseCase get unsubscribeFromTopicUseCase =>
      UnsubscribeFromTopicUseCase(fcmRepo);

  ManageOneSignalSubscriptionUseCase get oneSignalSubscriptionUseCase =>
      ManageOneSignalSubscriptionUseCase(oneSignalRepo);
}
