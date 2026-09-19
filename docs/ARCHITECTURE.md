# Architecture

## Package boundary

The package owns local notification delivery only. Its direct dependencies are `flutter_local_notifications`, `timezone`/`flutter_timezone`, `shared_preferences`, `permission_handler`, `device_info_plus`, and `app_settings`. Firebase and OneSignal are intentionally absent from the public API and dependency graph.

## Runtime

`NotificationService` is the public façade. `initialize()` creates one runtime, validates its configuration, initializes one shared `FlutterLocalNotificationsPlugin`, then assembles only the repositories selected by `NotificationFeature`.

```
NotificationService
        |
NotificationServiceFactory
  | permission | local plugin | scheduled | reminders | storage |
```

All public operations return `NotificationResult<T>`. This keeps lifecycle, permission, capacity, channel, and scheduling problems recoverable by the app instead of turning ordinary runtime state into uncaught exceptions.

## Scheduling

Scheduled notifications and reminders use `TZDateTime`.

- `absoluteInstant` represents a fixed moment. A timezone change does not change its meaning.
- `localWallClock` represents a local calendar time. The reminder store records it and the package re-schedules persistent wall-clock reminders after detecting a timezone change on initialization.

Timezone-aware scheduling naturally covers daylight-saving transitions; a device timezone change, not DST alone, is the re-sync trigger.

Exact scheduling is opt-in per notification/reminder. Android exact alarm access is checked before scheduling and a denied request returns `ExactAlarmPermissionFailure`; there is no silent inexact downgrade.

## Permissions and lifecycle

`NotificationPermissionStatus` is owned by this package rather than leaking an upstream plugin enum. The service refreshes it at initialization and whenever the app resumes, publishing changes on `onPermissionStatusChanged`.

When a permission cannot be requested again, a configured dialog can route the user to settings. Its display is persisted with a cooldown; the wait for the settings return is bounded by `PermissionConfig.settingsReturnTimeout` and a disposed widget returns `PermissionRequestCancelledFailure`.

## Tap routing

Every local payload is encoded as JSON with a notification source. Foreground taps emit `RoutingEvent` directly. A background callback has no access to the service singleton, so it writes its `RoutingEvent` to storage. Factory initialization drains those stored events into `onRoutingEvent`, including an event from an app launch caused by a notification.

## Persistence and recovery

Persistent reminders are held in `shared_preferences`. Android's native boot receiver restores the platform schedules when the consumer declares it. On normal application startup, the package additionally reschedules persisted reminders as a backup. It cannot run Dart code at boot or detect a permission revocation while the app is closed.
