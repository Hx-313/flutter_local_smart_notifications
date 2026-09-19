
class NotificationAction {
  final String id;
  final String title;
  final bool cancelNotification;
  final bool openApp;

  const NotificationAction({
    required this.id,
    required this.title,
    this.cancelNotification = true,
    this.openApp = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'cancelNotification': cancelNotification,
    'openApp': openApp,
  };

  factory NotificationAction.fromMap(Map<String, dynamic> map) =>
      NotificationAction(
        id: map['id'] as String,
        title: map['title'] as String,
        cancelNotification: map['cancelNotification'] as bool? ?? true,
        openApp: map['openApp'] as bool? ?? true,
      );
}
