// lib/services/notifications/domain/usecases/request_permission_usecase.dart
// DOMAIN | Request permission use case

import '../entities/permission_status.dart';
import '../entities/notification_result.dart';
import '../repositories/i_permission_repository.dart';
import '../repositories/i_notification_storage.dart';

class RequestPermissionUseCase {
  final IPermissionRepository _repository;
  final INotificationStorage _storage;

  const RequestPermissionUseCase(this._repository, this._storage);

  Future<NotificationResult<PermissionStatus>> call() async {
    await _storage.savePermissionAsked(true);
    final result = await _repository.request();

    if (result.isSuccess && !result.valueOrNull!.isGranted) {
      await _storage.incrementDenialCount();
    }

    return result;
  }
}
