// lib/services/notifications/domain/usecases/cancel_reminder_usecase.dart
// DOMAIN | Cancel reminder use case

import '../entities/notification_result.dart';
import '../repositories/i_reminder_notification_repository.dart';
import '../repositories/i_notification_storage.dart';

class CancelReminderUseCase {
  final IReminderNotificationRepository _repository;
  final INotificationStorage _storage;

  const CancelReminderUseCase(this._repository, this._storage);

  Future<NotificationResult<void>> call(int id) async {
    final result = await _repository.cancel(id);
    if (result.isSuccess) {
      await _storage.removeReminder(id);
    }
    return result;
  }
}
