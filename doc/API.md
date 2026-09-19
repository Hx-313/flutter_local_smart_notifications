# Public API reference

Import the package through its stable public entry point:

```dart
import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';
```

## Configuration

- `NotificationConfig` enables local features, declares channels, configures
  Android defaults, permission behavior, and reminder limits.
- `NotificationFeature` identifies `localInstant`, `localScheduled`, and
  `localReminder` capabilities.
- `NotificationProvider` is a backwards-compatible alias for
  `NotificationFeature`.
- `NotificationChannelConfig`, `PermissionConfig`, and `ReminderConfig`
  provide the nested configuration values.

## Payloads and schedules

- `NotificationPayload` contains the notification ID, title, body, channel,
  routing data, actions, optional image, sound, and silent-presentation flag.
- `NotificationAction` declares an action button and its open/cancel behavior.
- `ScheduledNotification` contains a payload, future `scheduledTime`,
  `RepeatInterval`, exact-timing preference, idle behavior, and
  `NotificationScheduleSemantics`.
- `ReminderNotification` contains a payload plus timeout, persistence, sound,
  full-screen, exact-timing, action, and optional scheduled-time settings.

`NotificationScheduleSemantics.localWallClock` preserves a local calendar time
after a timezone change. `absoluteInstant` preserves the same instant globally.

## Service

`NotificationService.initialize(config)` creates the single active runtime.
`NotificationService.instance` is safe before initialization; operations return
`NotInitializedFailure` until a runtime is ready.

The service exposes these operations:

- `requestPermission` and `checkPermission`;
- `showNotification` and `cancelNotification`;
- `scheduleNotification`, `getPendingScheduled`, and `cancelScheduled`;
- `showReminder`, `scheduleReminder`, and `cancelReminder`;
- `cancelAllScheduled`, `cancelAllReminders`, and `cancelAll`; and
- `openNotificationSettings`.

Every operation returns `NotificationResult<T>`. Handle success with
`isSuccess`, `valueOrNull`, or `fold`; handle recoverable conditions through
the typed `NotificationFailure` subclasses.

## Routing

Subscribe to `service.onRoutingEvent` for notification taps, action taps,
dismissals, and timeouts. Each `RoutingEvent` includes the target route,
original data, source, interaction, timestamp, and optional action ID.

## Common failures

- `NotInitializedFailure`
- `ProviderNotEnabledFailure`
- `PermissionNotGrantedFailure`
- `ExactAlarmPermissionFailure`
- `ChannelNotRegisteredFailure`
- `PastTimeFailure`
- `PlatformLimitExceededFailure`
- `ReminderLimitExceededFailure`
- `UnsupportedPlatformFailure`

See [SETUP.md](SETUP.md) for native configuration and platform capability
limits.
