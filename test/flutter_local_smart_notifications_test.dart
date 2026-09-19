import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

void main() {
  test('exports notification configuration through the package API', () {
    const config = NotificationConfig(
      enabledProviders: {NotificationProvider.localInstant},
      channels: [
        NotificationChannelConfig(
          id: 'general',
          name: 'General',
          description: 'General notifications',
        ),
      ],
      androidDefaultIcon: '@mipmap/ic_launcher',
    );

    expect(config.channelIds, contains('general'));
    expect(config.isFeatureEnabled(NotificationFeature.localInstant), isTrue);
    expect(config.isProviderEnabled(NotificationProvider.localInstant), isTrue);
  });

  test('uninitialized singleton returns a typed failure', () async {
    const payload = NotificationPayload(
      id: 1,
      title: 'Title',
      body: 'Body',
      channelId: 'general',
    );

    final result = await NotificationService.instance.showNotification(payload);

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<NotInitializedFailure>());
  });

  test('provisional permission can display notifications', () {
    const status = PermissionProvisional();

    expect(status.isGranted, isTrue);
    expect(status.canRequest, isFalse);
  });

  test('reminder exact alarms require explicit opt-in', () {
    const config = ReminderConfig();

    expect(config.useExactAlarm, isFalse);
  });

  test('invalid configuration is a typed initialization failure', () async {
    const config = NotificationConfig(
      enabledProviders: {},
      channels: [],
      androidDefaultIcon: '@mipmap/ic_launcher',
    );

    final result = await NotificationService.initialize(config);

    expect(result.isFailure, isTrue);
    expect(
      result.failureOrNull,
      isA<InvalidNotificationConfigurationFailure>(),
    );
  });
}
