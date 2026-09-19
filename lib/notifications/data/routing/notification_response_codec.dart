import 'dart:convert';

import '../../domain/entities/routing_event.dart';

const _sourceKey = '__flsn_source';
const _dataKey = '__flsn_data';

String encodeNotificationResponsePayload({
  required Map<String, dynamic> data,
  required NotificationSource source,
}) => jsonEncode({_sourceKey: source.name, _dataKey: data});

DecodedNotificationResponse? decodeNotificationResponsePayload(
  String? payload,
) {
  if (payload == null || payload.isEmpty) return null;

  final dynamic decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final map = Map<String, dynamic>.from(decoded);

  final source = NotificationSource.values.firstWhere(
    (value) => value.name == map[_sourceKey],
    orElse: () => NotificationSource.local,
  );
  final nestedData = map[_dataKey];
  final data = nestedData is Map ? Map<String, dynamic>.from(nestedData) : map;

  return DecodedNotificationResponse(data: data, source: source);
}

class DecodedNotificationResponse {
  const DecodedNotificationResponse({required this.data, required this.source});

  final Map<String, dynamic> data;
  final NotificationSource source;
}
