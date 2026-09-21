import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

import 'package:notification_lab/expense_notification_config.dart';
import 'package:notification_lab/notification_lab_app.dart';

void main() {
  group('expense notification configuration', () {
    test('enables every local capability and declares app channels', () {
      expect(
        expenseNotificationConfig.enabledProviders,
        containsAll(<NotificationFeature>[
          NotificationFeature.localInstant,
          NotificationFeature.localScheduled,
          NotificationFeature.localReminder,
        ]),
      );
      expect(
        expenseNotificationConfig.channelIds,
        containsAll(<String>['general', 'reminders', 'due_dates']),
      );
      expect(
        expenseNotificationConfig.reminderConfig.persistAcrossReboot,
        isTrue,
      );
    });
  });

  group('notification capability entities', () {
    const payload = NotificationPayload(
      id: 7,
      title: 'Test',
      body: 'Body',
      channelId: 'general',
      data: {
        'route': '/test',
        'nested': {'value': 42},
      },
    );

    test('preserves payload data', () {
      final copy = NotificationPayload.fromMap(payload.toMap());

      expect(copy.id, 7);
      expect(copy.data['nested'], {'value': 42});
    });

    test('covers every repeat interval and both schedule semantics', () {
      expect(RepeatInterval.values, hasLength(5));
      expect(
        NotificationScheduleSemantics.values,
        containsAll(<NotificationScheduleSemantics>[
          NotificationScheduleSemantics.absoluteInstant,
          NotificationScheduleSemantics.localWallClock,
        ]),
      );

      for (final interval in RepeatInterval.values) {
        final schedule = ScheduledNotification(
          payload: payload,
          scheduledTime: DateTime(2026, 9, 21),
          repeatInterval: interval,
          semantics: NotificationScheduleSemantics.localWallClock,
        );
        expect(
          ScheduledNotification.fromMap(schedule.toMap()).repeatInterval,
          interval,
        );
      }
    });

    test('supports instant and scheduled reminder forms', () {
      final instant = ReminderNotification(payload: payload);
      final scheduled = ReminderNotification(
        payload: payload,
        scheduledTime: DateTime(2026, 9, 21),
        persistent: true,
        exactTiming: true,
        fullScreenIntent: true,
      );

      expect(instant.isInstant, isTrue);
      expect(
        ReminderNotification.fromMap(scheduled.toMap()).isInstant,
        isFalse,
      );
      expect(
        ReminderNotification.fromMap(scheduled.toMap()).fullScreenIntent,
        isTrue,
      );
    });
  });

  testWidgets('renders the logo and capability tabs', (tester) async {
    await tester.pumpWidget(const NotificationLabApp(initialize: false));

    expect(find.byKey(const Key('app-logo')), findsOneWidget);
    expect(find.text('Test matrix'), findsOneWidget);
    expect(find.text('Instant'), findsOneWidget);
    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
  });

  testWidgets('runs every local matrix check from the example UI', (
    tester,
  ) async {
    await tester.pumpWidget(const NotificationLabApp(initialize: false));
    await tester.tap(find.byKey(const Key('run-matrix')));
    await tester.pump();

    expect(find.text('Payload data round trip'), findsOneWidget);
    expect(find.text('6/6 checks passed'), findsOneWidget);
  });

  testWidgets('shows the typed lifecycle failure before initialization', (
    tester,
  ) async {
    await tester.pumpWidget(const NotificationLabApp(initialize: false));
    await tester.tap(find.text('Instant'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('instant-basic')));
    await tester.pump();

    expect(find.textContaining('NotInitializedFailure'), findsOneWidget);
  });
}
