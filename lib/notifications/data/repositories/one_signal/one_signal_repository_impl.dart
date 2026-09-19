
// import 'dart:async';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import '../../../core/config/notification_config.dart';
// import '../../../domain/entities/notification_payload.dart';
// import '../../../domain/entities/notification_result.dart';
// import '../../../domain/failures/notification_failure.dart';
// import '../../../domain/repositories/i_one_signal_repository.dart';
// import '../../../domain/repositories/i_notification_logger.dart';

// class OneSignalRepositoryImpl implements IOneSignalRepository {
//   final NotificationConfig _config;
//   final INotificationLogger _logger;

//   final StreamController<NotificationPayload> _receivedController =
//       StreamController.broadcast();
//   final StreamController<NotificationPayload> _tappedController =
//       StreamController.broadcast();

//   OneSignalRepositoryImpl({
//     required NotificationConfig config,
//     required INotificationLogger logger,
//   }) : _config = config,
//        _logger = logger;

//   @override
//   Future<NotificationResult<void>> initialize() async {
//     try {
//       final osConfig = _config.oneSignalConfig;
//       if (osConfig == null) {
//         return const NotificationFailureResult(
//           ProviderNotEnabledFailure('OneSignal config missing'),
//         );
//       }

//       OneSignal.initialize(osConfig.appId);

//       OneSignal.Notifications.addClickListener((event) {
//         _tappedController.add(_map(event.notification));
//       });

//       OneSignal.Notifications.addForegroundWillDisplayListener((event) {
//         _receivedController.add(_map(event.notification));
//         event.notification.display();
//       });

//       _logger.info('OneSignal initialized');
//       return const NotificationSuccess(null);
//     } catch (e, s) {
//       _logger.error('OneSignal init failed', e, s);
//       return NotificationFailureResult(
//         ProviderInitializationFailure('OneSignal init failed', e, s),
//       );
//     }
//   }

//   @override
//   Future<NotificationResult<void>> setExternalUserId(String userId) async {
//     try {
//       await OneSignal.login(userId);
//       return const NotificationSuccess(null);
//     } catch (e, s) {
//       return NotificationFailureResult(
//         UnknownFailure('SetUserId failed', e, s),
//       );
//     }
//   }

//   @override
//   Future<NotificationResult<void>> removeExternalUserId() async {
//     try {
//       await OneSignal.logout();
//       return const NotificationSuccess(null);
//     } catch (e, s) {
//       return NotificationFailureResult(
//         UnknownFailure('RemoveUserId failed', e, s),
//       );
//     }
//   }

//   @override
//   Future<NotificationResult<String?>> getPlayerId() async {
//     try {
//       return NotificationSuccess(OneSignal.User.pushSubscription.id);
//     } catch (e, s) {
//       return NotificationFailureResult(
//         UnknownFailure('GetPlayerId failed', e, s),
//       );
//     }
//   }

//   @override
//   Stream<NotificationPayload> get onNotificationReceived =>
//       _receivedController.stream;

//   @override
//   Stream<NotificationPayload> get onNotificationTapped =>
//       _tappedController.stream;

//   @override
//   Future<NotificationResult<void>> dispose() async {
//     await _receivedController.close();
//     await _tappedController.close();
//     return const NotificationSuccess(null);
//   }

//   NotificationPayload _map(OSNotification notif) {
//     return NotificationPayload(
//       id: notif.notificationId.hashCode,
//       title: notif.title ?? '',
//       body: notif.body ?? '',
//       channelId:
//           notif.additionalData?['channelId'] ?? _config.channels.first.id,
//       data: notif.additionalData ?? {},
//     );
//   }
// }
