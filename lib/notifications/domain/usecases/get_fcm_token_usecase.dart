// lib/services/notifications/domain/usecases/get_fcm_token_usecase.dart
// DOMAIN | Get FCM token use case

import '../entities/notification_result.dart';
import '../repositories/i_fcm_repository.dart';
import '../repositories/i_notification_storage.dart';

class GetFcmTokenUseCase {
  final IFcmRepository _repository;
  final INotificationStorage _storage;

  const GetFcmTokenUseCase(this._repository, this._storage);

  Future<NotificationResult<String>> call() async {
    final result = await _repository.getToken();
    if (result.isSuccess) {
      await _storage.saveFcmToken(result.valueOrNull!);
    }
    return result;
  }
}
