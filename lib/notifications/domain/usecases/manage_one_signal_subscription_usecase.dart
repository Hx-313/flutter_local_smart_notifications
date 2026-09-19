// lib/services/notifications/domain/usecases/manage_one_signal_subscription_usecase.dart
// DOMAIN | OneSignal subscription management use case

import '../entities/notification_result.dart';
import '../repositories/i_one_signal_repository.dart';

class ManageOneSignalSubscriptionUseCase {
  final IOneSignalRepository _repository;

  const ManageOneSignalSubscriptionUseCase(this._repository);

  Future<NotificationResult<void>> setExternalUserId(String userId) =>
      _repository.setExternalUserId(userId);

  Future<NotificationResult<void>> removeExternalUserId() =>
      _repository.removeExternalUserId();

  Future<NotificationResult<String?>> getPlayerId() =>
      _repository.getPlayerId();
}
