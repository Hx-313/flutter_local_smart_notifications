// lib/services/notifications/domain/entities/routing_event.dart
// DOMAIN | Event emitted when notification tapped for navigation

/// Kind of notification that produced a [RoutingEvent].
enum NotificationSource {
  /// An immediate local notification.
  local,

  /// A scheduled local notification.
  scheduled,

  /// A reminder notification.
  reminder,
}

/// User or system interaction that produced a [RoutingEvent].
enum NotificationInteraction {
  /// The user opened the notification.
  tap,

  /// The user selected a notification action.
  action,

  /// The notification was dismissed.
  dismiss,

  /// The notification expired after its timeout.
  timeout,
}

/// Describes how a notification interaction should be routed in the app.
class RoutingEvent {
  /// Destination route, taken from the notification data.
  final String target;

  /// Identifier of the selected action, if the interaction was an action.
  final String? actionId;

  /// Application data carried by the notification.
  final Map<String, dynamic> data;

  /// Kind of notification that produced this event.
  final NotificationSource source;

  /// Interaction that produced this event.
  final NotificationInteraction interaction;

  /// Time at which this event was created or restored.
  final DateTime timestamp;

  /// Creates a routing event.
  const RoutingEvent({
    required this.target,
    this.actionId,
    this.data = const {},
    required this.source,
    required this.interaction,
    required this.timestamp,
  });

  /// Builds an event from notification data.
  ///
  /// The route is read from `route`, then `target`, and defaults to `home`.
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

  /// Serializes this event to a map accepted by [fromMap].
  Map<String, dynamic> toMap() => {
    'target': target,
    'actionId': actionId,
    'data': data,
    'source': source.name,
    'interaction': interaction.name,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Creates an event from its serialized [map].
  factory RoutingEvent.fromMap(Map<String, dynamic> map) => RoutingEvent(
    target: map['target'] as String? ?? 'home',
    actionId: map['actionId'] as String?,
    data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
    source: NotificationSource.values.firstWhere(
      (value) => value.name == map['source'],
      orElse: () => NotificationSource.local,
    ),
    interaction: NotificationInteraction.values.firstWhere(
      (value) => value.name == map['interaction'],
      orElse: () => NotificationInteraction.tap,
    ),
    timestamp:
        DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}
