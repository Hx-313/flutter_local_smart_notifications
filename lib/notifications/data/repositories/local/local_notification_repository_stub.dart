import '../../../domain/entities/notification_payload.dart';
import '../../../domain/entities/notification_result.dart';
import '../../../domain/failures/notification_failure.dart';
import '../../../domain/repositories/i_local_notification_repository.dart';
import '../../routing/routing_event_bus.dart';

class LocalNotificationRepositoryImpl implements ILocalNotificationRepository {
  LocalNotificationRepositoryImpl({
    required dynamic config,
    required dynamic logger,
    required RoutingEventBus routingEvents,
    required dynamic plugin,
  });

  @override
  Future<NotificationResult<void>> initialize() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localInstant'),
    );
  }

  @override
  Future<NotificationResult<void>> show(NotificationPayload payload) async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localInstant'),
    );
  }

  @override
  Future<NotificationResult<void>> cancel(int id) async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localInstant'),
    );
  }

  @override
  Future<NotificationResult<void>> cancelAll() async {
    return const NotificationFailureResult(
      ProviderNotEnabledFailure('localInstant'),
    );
  }
}
