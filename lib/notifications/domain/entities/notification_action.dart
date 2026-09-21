/// Describes an action a user can select from a notification.
class NotificationAction {
  /// Stable identifier returned when this action is selected.
  final String id;

  /// User-visible action label.
  final String title;

  /// Whether selecting the action dismisses its notification.
  final bool cancelNotification;

  /// Whether selecting the action opens the app.
  final bool openApp;

  /// Creates a notification action.
  const NotificationAction({
    required this.id,
    required this.title,
    this.cancelNotification = true,
    this.openApp = true,
  });

  /// Serializes this action to a map accepted by [fromMap].
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'cancelNotification': cancelNotification,
    'openApp': openApp,
  };

  /// Creates an action from its serialized [map].
  factory NotificationAction.fromMap(Map<String, dynamic> map) =>
      NotificationAction(
        id: map['id'] as String,
        title: map['title'] as String,
        cancelNotification: map['cancelNotification'] as bool? ?? true,
        openApp: map['openApp'] as bool? ?? true,
      );
}
