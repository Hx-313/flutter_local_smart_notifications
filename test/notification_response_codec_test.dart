import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

import 'package:flutter_local_smart_notifications/notifications/data/routing/notification_response_codec.dart';
import 'package:flutter_local_smart_notifications/notifications/data/routing/routing_event_bus.dart';

void main() {
  test('routing payload preserves nested data and source', () {
    final encoded = encodeNotificationResponsePayload(
      data: const {
        'route': '/expenses',
        'filters': {'month': 9},
      },
      source: NotificationSource.scheduled,
    );

    final decoded = decodeNotificationResponsePayload(encoded);

    expect(decoded, isNotNull);
    expect(decoded!.source, NotificationSource.scheduled);
    expect(decoded.data['route'], '/expenses');
    expect(decoded.data['filters'], {'month': 9});
  });

  test('legacy raw JSON payload defaults to local source', () {
    final decoded = decodeNotificationResponsePayload(
      jsonEncode(const {'route': '/home'}),
    );

    expect(decoded, isNotNull);
    expect(decoded!.source, NotificationSource.local);
    expect(decoded.data, {'route': '/home'});
  });

  test('malformed payload is ignored', () {
    expect(decodeNotificationResponsePayload('not-json'), isNull);
  });

  test('startup routing events wait for the first listener', () async {
    final bus = RoutingEventBus();
    final event = RoutingEvent(
      target: '/dashboard',
      source: NotificationSource.reminder,
      interaction: NotificationInteraction.tap,
      timestamp: DateTime(2026, 9, 20),
    );

    bus.add(event);

    expect(await bus.stream.first, event);
    await bus.dispose();
  });
}
