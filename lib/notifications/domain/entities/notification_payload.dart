
import 'notification_action.dart';

class NotificationPayload {
  final int id;
  final String title;
  final String body;
  final String channelId;
  final Map<String, dynamic> data;
  final List<NotificationAction> actions;
  final String? imageUrl;
  final String? soundName;
  final bool silent;

  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    this.data = const {},
    this.actions = const [],
    this.imageUrl,
    this.soundName,
    this.silent = false,
  });

  NotificationPayload copyWith({
    int? id,
    String? title,
    String? body,
    String? channelId,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
    String? imageUrl,
    String? soundName,
    bool? silent,
  }) => NotificationPayload(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    channelId: channelId ?? this.channelId,
    data: data ?? this.data,
    actions: actions ?? this.actions,
    imageUrl: imageUrl ?? this.imageUrl,
    soundName: soundName ?? this.soundName,
    silent: silent ?? this.silent,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'channelId': channelId,
    'data': data,
    'actions': actions.map((a) => a.toMap()).toList(),
    'imageUrl': imageUrl,
    'soundName': soundName,
    'silent': silent,
  };

  factory NotificationPayload.fromMap(Map<String, dynamic> map) =>
      NotificationPayload(
        id: map['id'] as int,
        title: map['title'] as String,
        body: map['body'] as String,
        channelId: map['channelId'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
        actions:
            (map['actions'] as List?)
                ?.map(
                  (a) => NotificationAction.fromMap(a as Map<String, dynamic>),
                )
                .toList() ??
            [],
        imageUrl: map['imageUrl'] as String?,
        soundName: map['soundName'] as String?,
        silent: map['silent'] as bool? ?? false,
      );
}
