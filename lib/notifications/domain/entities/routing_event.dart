// lib/services/notifications/domain/entities/routing_event.dart
// DOMAIN | Event emitted when notification tapped for navigation

enum NotificationSource { local, scheduled, reminder, fcm, oneSignal }

enum NotificationInteraction { tap, action, dismiss, timeout }

class RoutingEvent {
  final String target;
  final String? actionId;
  final Map<String, dynamic> data;
  final NotificationSource source;
  final NotificationInteraction interaction;
  final DateTime timestamp;

  const RoutingEvent({
    required this.target,
    this.actionId,
    this.data = const {},
    required this.source,
    required this.interaction,
    required this.timestamp,
  });

  factory RoutingEvent.fromPayloadData({
    required Map<String, dynamic> data,
    required NotificationSource source,
    NotificationInteraction interaction = NotificationInteraction.tap,
    String? actionId,
  }) => RoutingEvent(
    target: data['route'] as String? ?? data['target'] as String? ?? 'home',
    actionId: actionId,
    data: data,
    source: source,
    interaction: interaction,
    timestamp: DateTime.now(),
  );
}
