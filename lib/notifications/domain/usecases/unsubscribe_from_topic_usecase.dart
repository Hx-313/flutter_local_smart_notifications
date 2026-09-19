// lib/services/notifications/domain/usecases/unsubscribe_from_topic_usecase.dart
// DOMAIN | Unsubscribe from FCM topic use case

import '../entities/notification_result.dart';
import '../repositories/i_fcm_repository.dart';

class UnsubscribeFromTopicUseCase {
  final IFcmRepository _repository;

  const UnsubscribeFromTopicUseCase(this._repository);

  Future<NotificationResult<void>> call(String topic) =>
      _repository.unsubscribeFromTopic(topic);
}
