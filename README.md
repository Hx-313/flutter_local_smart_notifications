# Flutter Local Smart Notifications

`flutter_local_smart_notifications` is a local-notification runtime for Flutter apps that need immediate alerts, scheduled notifications, and persistent reminders without rebuilding the same permission, exact-alarm, timezone, and reboot-recovery logic in every app.

It is deliberately local-only. Firebase Cloud Messaging and OneSignal are not dependencies of this package; pair them with a separate integration package or your own adapter when a product needs push delivery.

## What it handles

- Android and iOS local notifications with declared channels.
- Zoned schedules, including daily, weekly, monthly, and yearly recurrence.
- Exact Android scheduling when the user has explicitly granted exact-alarm access.
- Persistent reminders that are re-scheduled on the next app launch and, when the consumer declares the boot receiver, by the native receiver after reboot.
- Permission state, denial cooldown, a settings return timeout, and permission re-checking when the app resumes.
- Local-wall-clock versus absolute-instant schedule semantics for timezone changes.
- Foreground, launch, and background tap routing through `onRoutingEvent`.
- The iOS pending-notification cap, reserving four of its 64 pending slots by default.

## Install

```yaml
dependencies:
  flutter_local_smart_notifications: ^0.0.1
```

Then run `flutter pub get`.

## Required native setup

This package is a Dart package: it contributes no Android manifest, iOS plist, or Gradle entries itself. Add the setup required by the features your app enables. See [docs/SETUP.md](docs/SETUP.md) for the complete Android, Gradle, and iOS instructions.

For Android exact schedules, declare `SCHEDULE_EXACT_ALARM` and let the package take the user to Android's special-access screen. Do not use `USE_EXACT_ALARM` merely to bypass that user decision. The documented setup does not include `USE_FULL_SCREEN_INTENT` either.

## Quick start

```dart
import 'dart:ui';

import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

final notifications = NotificationConfig(
  enabledProviders: const {
    NotificationProvider.localInstant,
    NotificationProvider.localScheduled,
    NotificationProvider.localReminder,
  },
  channels: const [
    NotificationChannelConfig(
      id: 'general',
      name: 'General',
      description: 'General alerts',
      importance: ChannelImportance.high,
    ),
    NotificationChannelConfig(
      id: 'reminders',
      name: 'Reminders',
      description: 'Time-sensitive reminders',
      importance: ChannelImportance.max,
    ),
  ],
  androidDefaultIcon: '@mipmap/ic_launcher',
  androidDefaultColor: Color(0xFF4CAF50),
  permissionConfig: PermissionConfig(
    autoRequestOnInit: false,
    dialogTitle: 'Enable reminders',
    dialogMessage: 'Allow notifications to receive reminders on time.',
  ),
);

Future<void> bootstrapNotifications() async {
  final result = await NotificationService.initialize(notifications);
  result.fold(
    onSuccess: (service) {
      service.onRoutingEvent.listen((event) {
        // Route from event.target and use event.data as needed.
      });
    },
    onFailure: (failure) {
      // Log or display a recoverable setup failure.
    },
  );
}
```

Request access from a user-visible screen, not automatically at app startup:

```dart
final result = await NotificationService.instance.requestPermission(
  context: context,
  includeExactAlarm: true,
);

if (result.isSuccess && result.valueOrNull!.isGranted) {
  // It is now appropriate to create exact schedules.
}
```

Use `NotificationScheduleSemantics.localWallClock` for a reminder such as “every day at 09:00”; it is re-synced when the device timezone changes. Use the default `absoluteInstant` for a time that must represent the same instant globally.

```dart
await NotificationService.instance.scheduleNotification(
  ScheduledNotification(
    payload: const NotificationPayload(
      id: 42,
      title: 'Daily check-in',
      body: 'Record today’s expense.',
      channelId: 'reminders',
      data: {'route': '/dashboard'},
    ),
    scheduledTime: DateTime(2026, 9, 21, 9),
    repeatInterval: RepeatInterval.daily,
    exactTiming: true,
    semantics: NotificationScheduleSemantics.localWallClock,
  ),
);
```

## Result model and lifecycle

All operations return `NotificationResult<T>`; recoverable failures are values, not uncaught lifecycle exceptions. `NotificationService.instance` is always safe to obtain. Calling a method before successful initialization returns `NotInitializedFailure`.

Only one active runtime is allowed. Calling `initialize()` again with the same `NotificationConfig` object returns the active runtime; supplying another configuration returns `NotificationLifecycleFailure`. Call `dispose()` before replacing configuration, such as in tests.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the runtime model and [AGENTS.md](AGENTS.md) for repository conventions.
