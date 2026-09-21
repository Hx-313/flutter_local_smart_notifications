/// Content and display options for a local notification.
class NotificationPayload {
  /// Identifier used to update or cancel this notification.
  final int id;

  /// Notification title.
  final String title;

  /// Notification body text.
  final String body;

  /// Identifier of the configured notification channel.
  final String channelId;

  /// Application data delivered with the notification interaction.
  final Map<String, dynamic> data;

  /// Optional key selecting a sound from the configured sound assets.
  final String? soundName;

  /// Whether the notification should be presented without sound.
  final bool silent;

  /// Creates the content and display options for a local notification.
  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    this.data = const {},
    this.soundName,
    this.silent = false,
  });

  /// Returns a copy with the supplied non-null fields replaced.
  ///
  /// Passing `null` keeps the current value, including nullable fields.
  NotificationPayload copyWith({
    int? id,
    String? title,
    String? body,
    String? channelId,
    Map<String, dynamic>? data,
    String? soundName,
    bool? silent,
  }) => NotificationPayload(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    channelId: channelId ?? this.channelId,
    data: data ?? this.data,
    soundName: soundName ?? this.soundName,
    silent: silent ?? this.silent,
  );

  /// Serializes this payload to a map accepted by [fromMap].
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'channelId': channelId,
    'data': data,
    'soundName': soundName,
    'silent': silent,
  };

  /// Creates a payload from its serialized [map].
  factory NotificationPayload.fromMap(Map<String, dynamic> map) =>
      NotificationPayload(
        id: map['id'] as int,
        title: map['title'] as String,
        body: map['body'] as String,
        channelId: map['channelId'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
        soundName: map['soundName'] as String?,
        silent: map['silent'] as bool? ?? false,
      );
}
