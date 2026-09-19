// lib/services/notifications/domain/usecases/open_notification_settings_usecase.dart
// DOMAIN | Open notification settings use case

import '../entities/notification_result.dart';
import '../repositories/i_permission_repository.dart';

class OpenNotificationSettingsUseCase {
  final IPermissionRepository _repository;

  const OpenNotificationSettingsUseCase(this._repository);

  Future<NotificationResult<void>> call() => _repository.openSettings();
}
