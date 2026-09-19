// lib/services/notifications/domain/usecases/request_permission_usecase.dart
// DOMAIN | Request permission use case

import '../entities/permission_status.dart';
import '../entities/notification_result.dart';
import '../repositories/i_permission_repository.dart';

class RequestPermissionUseCase {
  final IPermissionRepository _repository;

  const RequestPermissionUseCase(this._repository);

  Future<NotificationResult<NotificationPermissionStatus>> call() =>
      _repository.request();
}
