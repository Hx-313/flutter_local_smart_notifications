// lib/services/notifications/domain/usecases/refresh_fcm_token_usecase.dart
// DOMAIN | Refresh FCM token stream use case

import '../repositories/i_fcm_repository.dart';
import '../repositories/i_notification_storage.dart';

class RefreshFcmTokenUseCase {
  final IFcmRepository _repository;
  final INotificationStorage _storage;

  const RefreshFcmTokenUseCase(this._repository, this._storage);

  Stream<String> call() => _repository.onTokenRefresh.asyncMap((token) async {
    await _storage.saveFcmToken(token);
    return token;
  });
}
