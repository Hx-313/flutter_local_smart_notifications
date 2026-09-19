// lib/services/notifications/domain/usecases/check_permission_usecase.dart
// DOMAIN | Check permission without prompting use case

import '../entities/permission_status.dart';
import '../entities/notification_result.dart';
import '../repositories/i_permission_repository.dart';

class CheckPermissionUseCase {
  final IPermissionRepository _repository;

  const CheckPermissionUseCase(this._repository);

  Future<NotificationResult<PermissionStatus>> call() => _repository.check();
}
