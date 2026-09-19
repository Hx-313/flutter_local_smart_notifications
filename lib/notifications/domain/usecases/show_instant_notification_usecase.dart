// lib/services/notifications/domain/usecases/show_instant_notification_usecase.dart
// DOMAIN | Show instant local notification use case

import '../entities/notification_payload.dart';
import '../entities/notification_result.dart';
import '../failures/notification_failure.dart';
import '../repositories/i_local_notification_repository.dart';

class ShowInstantNotificationUseCase {
  final ILocalNotificationRepository _repository;
  final Set<String> _registeredChannels;

  const ShowInstantNotificationUseCase(
    this._repository,
    this._registeredChannels,
  );

  Future<NotificationResult<void>> call(NotificationPayload payload) async {
    if (!_registeredChannels.contains(payload.channelId)) {
      return NotificationFailureResult(
        ChannelNotRegisteredFailure(payload.channelId),
      );
    }
    return _repository.show(payload);
  }
}
