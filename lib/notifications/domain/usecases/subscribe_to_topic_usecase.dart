// lib/services/notifications/domain/usecases/subscribe_to_topic_usecase.dart
// DOMAIN | Subscribe to FCM topic use case

import '../entities/notification_result.dart';
import '../repositories/i_fcm_repository.dart';

class SubscribeToTopicUseCase {
  final IFcmRepository _repository;

  const SubscribeToTopicUseCase(this._repository);

  Future<NotificationResult<void>> call(String topic) =>
      _repository.subscribeToTopic(topic);
}
