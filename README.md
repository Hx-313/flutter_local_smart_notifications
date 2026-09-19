# flutter_local_smart_notifications

[![pub package](https://img.shields.io/pub/v/flutter_local_smart_notifications.svg)](https://pub.dev/packages/flutter_local_smart_notifications)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue.svg)](https://pub.dev/packages/flutter_local_smart_notifications)

A typed, local-only notification service for Flutter. Show notifications immediately, schedule them for later, repeat them on a recurring basis, and create persistent alarm-style reminders, all through a single Dart API.

The package owns the difficult platform details so your app does not have to: **permissions, exact alarms, time zones, reboot recovery, pending-notification limits, and notification-tap routing.**

> **Local only.** This package does not include Firebase Cloud Messaging, OneSignal, or any other push SDK. If your app also needs server-triggered push notifications, keep that integration in a separate package or adapter.

---

## Table of contents

- [Features](#features)
- [When to use this package](#when-to-use-this-package)
- [Supported platforms](#supported-platforms)
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting started](#getting-started)
- [Usage](#usage)
  - [Show an instant notification](#show-an-instant-notification)
  - [Add notification actions](#add-notification-actions)
  - [Schedule a notification](#schedule-a-notification)
  - [Create a persistent reminder](#create-a-persistent-reminder)
  - [Handle taps and actions](#handle-taps-and-actions)
  - [Cancel and inspect notifications](#cancel-and-inspect-notifications)
- [Error handling with `NotificationResult`](#error-handling-with-notificationresult)
- [Permissions](#permissions)
- [Example application](#example-application)
- [Limitations](#limitations)
- [Release checklist](#release-checklist)
- [Documentation](#documentation)

---

## Features

| Capability | Typical use cases | API |
| --- | --- | --- |
| **Instant notification** | Immediate local events and status updates | `showNotification` |
| **Scheduled notification** | One-time future alerts | `scheduleNotification` |
| **Recurring schedule** | Daily, weekly, monthly, and yearly routines | `scheduleNotification` |
| **Persistent reminder** | Alarm-like, high-priority user tasks | `showReminder`, `scheduleReminder` |
| **Notification actions** | Done, Snooze, Review, Dismiss, Open | `NotificationAction` |
| **Exact timing** | Precise, user-visible deadlines | `exactTiming: true` |
| **Wall-clock timing** | Same local time after the user travels | `localWallClock` |
| **Absolute timing** | The same global instant everywhere | `absoluteInstant` |
| **Tap routing** | Navigate after a tap or action | `onRoutingEvent` |
| **Pending inspection** | Display or debug scheduled IDs | `getPendingScheduled` |
| **Cancellation** | Remove one or all notifications | `cancel*` methods |

### Highlights

- **Typed results, not exceptions.** Every public operation returns `NotificationResult<T>`, so expected runtime conditions (missing permission, past time, platform limits) are values your app can display or recover from.
- **Explicit time-zone semantics.** Choose between `localWallClock` ("every day at 09:00 where the user is now") and `absoluteInstant` ("at this exact moment globally").
- **Honest exact alarms.** An exact request is never silently downgraded to an inexact schedule. If Android exact-alarm access is unavailable, you receive `ExactAlarmPermissionFailure`.
- **Routing that survives the background.** Tap and action events are persisted first, then delivered through `onRoutingEvent` after the next successful initialization.
- **Lifecycle recovery.** Persistent reminders are stored and reconciled on the next initialization. Android boot restoration works when your app declares the documented boot receiver.
- **Platform-neutral permissions.** Typed statuses, a configurable permission dialog, a denial cooldown, a bounded settings-return wait, and a re-check when the app resumes. No upstream plugin enums leak into your code.
- **Pending-limit awareness.** Capacity is checked before scheduling. On iOS, the budget respects the platform's 64-pending-notification cap and the slots reserved in `ReminderConfig`.

## When to use this package

Use it when **the device can decide when to notify**:

- **Instant:** an expense was recorded, a download finished, a local message was saved, a form needs attention, or a background task completed.
- **Scheduled:** a bill due in two hours, a meeting reminder, a trial-expiry warning, a medication reminder, or a delivery window.
- **Recurring:** daily habits and check-ins, weekly budget reviews, monthly rent or statement reminders, yearly birthdays, renewals, or tax dates.
- **Persistent reminders:** a critical bill due date, a medication alarm, an attendance or check-in deadline, a safety or monitoring alert, or any task that should remain visible until handled.

It does **not** fetch remote messages. Pair it with a separate push adapter if a server must trigger delivery.

## Supported platforms

| Platform | Supported |
| --- | :---: |
| Android | ✅ |
| iOS | ✅ |

## Requirements

- Flutter `3.38.1` or newer
- Dart `3.11.3` or newer
- Android compile SDK 35 or newer (when building for Android)
- Java 17 and core-library desugaring (Android)
- A real device or emulator for delivery tests. Unit and widget tests can run without a notification-capable device.

## Installation

Add the package to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_smart_notifications: ^0.0.1
```

Then fetch dependencies:

```shell
flutter pub get
```

### Native setup

Native setup is **required** before testing on a device. This package intentionally does not modify your Android manifest, Gradle files, iOS Podfile, or iOS project settings, because every app has different product requirements.

See [docs/SETUP.md](docs/SETUP.md) for:

- Android permissions and receivers
- Exact-alarm access and Google Play policy considerations
- Java 17, compile SDK 35, and desugaring
- Android launcher and notification resources, and custom sounds
- iOS permission-handler configuration
- iOS's pending-notification limit
- The platform verification matrix

## Getting started

1. Add the package and complete the [native setup](#native-setup).
2. Declare your notification channels.
3. Initialize the service once.
4. Request permission from a user-visible screen.
5. Call `showNotification`, `scheduleNotification`, or `showReminder`.
6. Handle the returned `NotificationResult` instead of assuming delivery succeeded.

### 1. Configure

Create a file such as `lib/notification_config.dart`. A configuration has three key parts:

- `enabledProviders` turns on the capabilities your app needs.
- `channels` declares every channel a payload may use.
- `androidDefaultIcon` names a native Android resource used for notifications.

```dart
import 'dart:ui';

import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

const notificationConfig = NotificationConfig(
  enabledProviders: {
    NotificationFeature.localInstant,
    NotificationFeature.localScheduled,
    NotificationFeature.localReminder,
  },
  channels: [
    NotificationChannelConfig(
      id: 'general',
      name: 'General',
      description: 'General application notifications',
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
    dialogTitle: 'Enable notifications',
    dialogMessage: 'Allow notifications so important reminders arrive on time.',
    openSettingsLabel: 'Open settings',
    notNowLabel: 'Not now',
  ),
);
```

> `NotificationProvider` is a backwards-compatible alias for `NotificationFeature`; either name is valid.

Every `channelId` used in a `NotificationPayload` **must** be present in `channels`. Otherwise the operation returns `ChannelNotRegisteredFailure`.

### 2. Initialize once

Initialization validates the configuration, prepares the platform plugin, restores persisted routing and reminder state, and checks the current permission status.

```dart
import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

Future<void> initializeNotifications() async {
  final result = await NotificationService.initialize(notificationConfig);

  result.fold(
    onSuccess: (service) {
      service.onRoutingEvent.listen((event) {
        // Navigate using event.target and read extra values from event.data.
        print('Notification route: ${event.target}');
      });
    },
    onFailure: (failure) {
      // Show a useful message or log the typed failure.
      print('Notification setup failed: ${failure.message}');
    },
  );
}
```

Call this once at app startup, for example after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp`.

- Only **one active runtime** is permitted at a time. Do not create multiple runtimes with different configurations. Call `await service.dispose()` before replacing the configuration (for example, in a test).
- `NotificationService.instance` is always safe to read. Before initialization completes, operations return `NotInitializedFailure` rather than throwing.

### 3. Request permission

Connect permission prompts to a user-visible action, such as an "Enable notifications" button. Avoid surprising users with a dialog on a splash screen unless that is an intentional product decision.

```dart
Future<void> enableNotifications(BuildContext context) async {
  final result = await NotificationService.instance.requestPermission(
    context: context,
  );

  if (!context.mounted) return;

  result.fold(
    onSuccess: (status) {
      if (status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications are enabled.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current status: ${status.runtimeType}')),
        );
      }
    },
    onFailure: (failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    },
  );
}
```

For features that need precise timing, request notification permission and exact-alarm access together, and only when the user chooses such a feature:

```dart
final result = await NotificationService.instance.requestPermission(
  context: context,
  includeExactAlarm: true,
);
```

`includeExactAlarm` never silently makes a schedule inexact. If Android exact-alarm access is unavailable, the operation returns `ExactAlarmPermissionFailure`.

## Usage

### Show an instant notification

```dart
final result = await NotificationService.instance.showNotification(
  const NotificationPayload(
    id: 1,
    title: 'Expense recorded',
    body: 'Your coffee expense was added.',
    channelId: 'general',
    data: {'route': '/expenses'},
  ),
);

if (result.isFailure) {
  print(result.failureOrNull);
}
```

The `id` is the platform notification ID. Reusing an ID updates or replaces the notification on platforms that support it. Use unique IDs when you want multiple alerts to remain visible.

#### `NotificationPayload` fields

| Field | Description |
| --- | --- |
| `id` | Numeric platform notification ID. |
| `title` | Notification title. |
| `body` | Notification body. |
| `channelId` | One of the channels declared in `NotificationConfig`. |
| `data` | JSON-like routing and application data. |
| `actions` | Buttons shown by the platform, where supported. |
| `imageUrl` | Optional remote image URL, subject to platform and network support. |
| `soundName` | Optional key registered in `soundAssets`. |
| `silent` | Requests silent presentation. |

### Add notification actions

Actions let a user respond without opening the app. Action taps are delivered through the same routing stream as notification taps.

```dart
const payload = NotificationPayload(
  id: 2,
  title: 'Review purchase',
  body: 'A large purchase needs your attention.',
  channelId: 'general',
  data: {'route': '/expenses/2'},
  actions: [
    NotificationAction(id: 'review', title: 'Review'),
    NotificationAction(
      id: 'dismiss',
      title: 'Dismiss',
      cancelNotification: true,
      openApp: false,
    ),
  ],
);

await NotificationService.instance.showNotification(payload);
```

- `cancelNotification` controls whether the notification is removed after the action.
- `openApp` controls whether the action opens the app, where the platform supports that choice.
- Android action taps require the action receiver described in [docs/SETUP.md](docs/SETUP.md).

### Schedule a notification

Use `ScheduledNotification` when delivery should happen in the future or repeat:

```dart
final result = await NotificationService.instance.scheduleNotification(
  ScheduledNotification(
    payload: const NotificationPayload(
      id: 42,
      title: 'Daily check-in',
      body: 'Record today’s expense.',
      channelId: 'reminders',
      data: {'route': '/dashboard'},
    ),
    scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
    repeatInterval: RepeatInterval.none,
    allowWhileIdle: true,
    exactTiming: false,
    semantics: NotificationScheduleSemantics.absoluteInstant,
  ),
);
```

The scheduled time must be in the future. A past time returns `PastTimeFailure`.

#### Repeat intervals

| Value | Behavior | Example |
| --- | --- | --- |
| `RepeatInterval.none` | Deliver once | Meeting reminder |
| `RepeatInterval.daily` | Repeat every day | Medication, check-ins |
| `RepeatInterval.weekly` | Repeat every week | Weekly planning, budget review |
| `RepeatInterval.monthly` | Repeat every month | Rent, subscriptions, statements |
| `RepeatInterval.yearly` | Repeat every year | Birthdays, renewals, taxes |

#### Choose the time-zone meaning

This choice matters when a user travels or changes the device time zone.

```dart
// "Every day at the user's local 09:00."
semantics: NotificationScheduleSemantics.localWallClock,

// "The same absolute moment everywhere."
semantics: NotificationScheduleSemantics.absoluteInstant,
```

| Semantics | Use for |
| --- | --- |
| `localWallClock` | Habits, medication, morning check-ins, and other time-of-day reminders |
| `absoluteInstant` | Deadlines, expiry moments, and events tied to one global instant |

Persistent wall-clock reminders are re-synchronized after the package detects a device time-zone change during initialization.

#### Exact versus inexact timing

Set `exactTiming: true` only when the product requirement justifies precise timing. Android may require the user to grant the exact-alarm special access. The package checks that access and returns `ExactAlarmPermissionFailure` when it is unavailable. It does **not** silently downgrade the request.

Use exact alarms only when the requirement justifies the extra permission and the associated platform policy review.

### Create a persistent reminder

Reminders are intended for high-priority, alarm-like experiences. They can be instant or scheduled.

```dart
final result = await NotificationService.instance.scheduleReminder(
  ReminderNotification(
    payload: const NotificationPayload(
      id: 300,
      title: 'Bill due soon',
      body: 'Your electricity bill is due today.',
      channelId: 'reminders',
      data: {'route': '/bills/electricity'},
    ),
    scheduledTime: DateTime.now().add(const Duration(minutes: 2)),
    timeout: const Duration(minutes: 10),
    loopSound: true,
    persistent: true,
    fullScreenIntent: false,
    exactTiming: true,
    actions: const [
      NotificationAction(id: 'done', title: 'Done'),
      NotificationAction(id: 'snooze', title: 'Snooze'),
    ],
    semantics: NotificationScheduleSemantics.absoluteInstant,
  ),
);
```

Use `showReminder` instead when `scheduledTime` is `null` and the reminder should appear immediately. `ReminderNotification.isInstant` reports which form an object represents.

| Field | Description |
| --- | --- |
| `timeout` | How long the reminder stays active before timing out. |
| `loopSound` | Requests repeated sound, where supported. |
| `persistent` | Requests an ongoing, harder-to-dismiss presentation. |
| `fullScreenIntent` | Requests an alarm-like full-screen presentation. Use only when genuinely needed, and verify platform and store policy separately. |
| `exactTiming` | Requests exact scheduling for a scheduled reminder. |
| `actions` | Reminder-specific action buttons. |
| `semantics` | Absolute-instant or local-wall-clock meaning. |

`ReminderConfig` limits active reminders, sets the default timeout, enables persistence for reboot recovery, and controls the platform pending-notification budget.

### Handle taps and actions

Subscribe after successful initialization:

```dart
service.onRoutingEvent.listen((event) {
  switch (event.target) {
    case '/expenses':
      // Navigate to the expenses page.
      break;
    case '/bills/electricity':
      // Navigate to the bill details page.
      break;
  }

  print('source=${event.source} interaction=${event.interaction}');
  print('actionId=${event.actionId} data=${event.data}');
});
```

Put a route and any small JSON-like values in `NotificationPayload.data`. This works for foreground taps, app-launch taps, and background action or tap events.

`RoutingEvent` contains:

| Property | Description |
| --- | --- |
| `target` | The route or target name, from `data['route']` or `data['target']`. |
| `actionId` | The tapped action, when an action caused the event. |
| `data` | The original payload data. |
| `source` | `local`, `scheduled`, or `reminder`. |
| `interaction` | `tap`, `action`, `dismiss`, or `timeout`. |
| `timestamp` | When the routing event was created. |

Background callbacks cannot access the singleton or in-memory UI state. The package persists the event first and delivers it through `onRoutingEvent` after the next initialization.

### Cancel and inspect notifications

```dart
await NotificationService.instance.cancelNotification(42);
await NotificationService.instance.cancelScheduled(42);
await NotificationService.instance.cancelReminder(300);

final pending = await NotificationService.instance.getPendingScheduled();
pending.fold(
  onSuccess: (ids) => print('Pending scheduled IDs: $ids'),
  onFailure: (failure) => print(failure.message),
);

await NotificationService.instance.cancelAllScheduled();
await NotificationService.instance.cancelAllReminders();
await NotificationService.instance.cancelAll();
```

`cancelNotification` cancels the matching notification through the enabled local and scheduled providers. Use the provider-specific methods when you want the intent to be explicit.

## Error handling with `NotificationResult`

Every public operation returns `NotificationResult<T>`:

```dart
final result = await NotificationService.instance.showNotification(payload);

if (result.isSuccess) {
  print('Notification request accepted by the platform.');
} else {
  final failure = result.failureOrNull!;
  print('${failure.runtimeType}: ${failure.message}');
}
```

For a single expression, use `fold`:

```dart
final message = result.fold(
  onSuccess: (_) => 'Done',
  onFailure: (failure) => failure.message,
);
```

### Common failures

| Failure | Resolution |
| --- | --- |
| `NotInitializedFailure` | Initialize first, or wait for initialization to finish. |
| `ProviderNotEnabledFailure` | Enable the feature in `NotificationConfig`. |
| `PermissionNotGrantedFailure` | Request notification access. |
| `ExactAlarmPermissionFailure` | Ask for exact-alarm access, or use inexact timing. |
| `ChannelNotRegisteredFailure` | Add the payload's channel to the config. |
| `PastTimeFailure` | Choose a future schedule time. |
| `PlatformLimitExceededFailure` | Reduce pending notifications or adjust the reminder budget. |
| `ReminderLimitExceededFailure` | Cancel reminders or increase `maxActiveReminders`. |
| `UnsupportedPlatformFailure` | Run the operation on a supported platform. |

See the complete list in [docs/API.md](docs/API.md).

## Permissions

The package exposes its own platform-neutral status types:

| Status | Meaning |
| --- | --- |
| `PermissionNotDetermined` | The user has not answered yet. |
| `PermissionGranted` | Normal notification access is granted. |
| `PermissionDenied` | Access is denied but may be requested again. |
| `PermissionPermanentlyDenied` | The user must use system settings. |
| `PermissionRestricted` | The platform restricts access. |
| `PermissionProvisional` | iOS provisional access. Counts as granted. |

Use `status.isGranted`, `status.isDenied`, and `status.canRequest` rather than inspecting platform plugin enums.

Permission is checked at initialization and whenever the app resumes.

## Example application

The [`example/`](example/) app is a capability lab that demonstrates every supported notification and scheduling mode:

- App-level expense notification configuration
- Instant notification cases
- One-shot and recurring schedules
- Both time-zone semantics
- Persistent reminders and full-screen policy
- Cancellation and pending-ID cases
- Deterministic widget and unit tests

```shell
cd example
flutter pub get
dart run flutter_launcher_icons
flutter run
flutter test
```

## Limitations

- Remote push notifications are not supported.
- Android manifest entries and iOS project settings are not added to your app automatically.
- Exact schedules are never silently downgraded to inexact schedules.
- Dart code cannot run immediately after an Android reboot. Native boot restoration plus next-launch reconciliation are used instead.
- A permission revocation cannot be observed while the app is fully closed. Permission is checked at initialization and on app resume.

## Release checklist

Before shipping a notification feature:

1. Test a fresh install with permission granted and denied.
2. Test permanent denial and opening system settings.
3. Test Android API 31, 33, 34, and 35+.
4. Test exact-alarm grant and refusal.
5. Test both an exact and an inexact schedule.
6. Test a device reboot with the boot receiver declared.
7. Change the device time zone and verify both schedule semantics.
8. Tap the notification, tap each action, and test a background tap.
9. Test iOS pending-notification capacity.
10. Verify that every operation displays or logs its `NotificationFailure`.

## Documentation

- [Public API reference](docs/API.md)
- [Consumer native setup](docs/SETUP.md)
- [Architecture and lifecycle model](docs/ARCHITECTURE.md)
- [Runnable example app](example/README.md)