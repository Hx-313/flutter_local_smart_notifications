
// import 'dart:async';
// import '../../../domain/entities/notification_payload.dart';
// import '../../../domain/entities/notification_result.dart';
// import '../../../domain/failures/notification_failure.dart';
// import '../../../domain/repositories/i_one_signal_repository.dart';

// class OneSignalRepositoryImpl implements IOneSignalRepository {
//   OneSignalRepositoryImpl({required dynamic config, required dynamic logger});

//   @override
//   Future<NotificationResult<void>> initialize() async {
//     return const NotificationFailureResult(
//       ProviderNotEnabledFailure('oneSignal'),
//     );
//   }

//   @override
//   Future<NotificationResult<void>> setExternalUserId(String userId) async {
//     return const NotificationFailureResult(
//       ProviderNotEnabledFailure('oneSignal'),
//     );
//   }

//   @override
//   Future<NotificationResult<void>> removeExternalUserId() async {
//     return const NotificationFailureResult(
//       ProviderNotEnabledFailure('oneSignal'),
//     );
//   }

//   @override
//   Future<NotificationResult<String?>> getPlayerId() async {
//     return const NotificationFailureResult(
//       ProviderNotEnabledFailure('oneSignal'),
//     );
//   }

//   @override
//   Stream<NotificationPayload> get onNotificationReceived =>
//       const Stream.empty();

//   @override
//   Stream<NotificationPayload> get onNotificationTapped => const Stream.empty();

//   @override
//   Future<NotificationResult<void>> dispose() async {
//     return const NotificationSuccess(null);
//   }
// }
