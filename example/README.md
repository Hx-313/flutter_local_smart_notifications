# Smart Notifications Lab

This is a device-backed example app for `flutter_local_smart_notifications`. It uses the app-owned configuration in `lib/expense_notification_config.dart` and the supplied SmartX logo at `assets/logo.png`.

The same logo is generated as the Android `launcher_icon` and iOS app icon with `flutter_launcher_icons`. Android notifications use the generated `@mipmap/launcher_icon` resource as the package default icon. For a production Android app, consider shipping a separate white monochrome notification drawable because Android may mask or tint notification icons.

## Run

From this directory:

```shell
flutter pub get
dart run flutter_launcher_icons
flutter run
flutter test
```

Complete the consumer Android/iOS setup in the package's [`docs/SETUP.md`](../docs/SETUP.md) before testing delivery. The example intentionally does not request notification permission at startup; use the permission controls in the runtime banner.

## Coverage map

| Screen | Cases |
| --- | --- |
| Test matrix | Public payload, action, schedule, reminder, configuration, recurrence, and timezone-semantic round trips |
| Instant | Basic, actions, silent/sound/image fields, cancel by ID, cancel all |
| Scheduling | One-shot absolute inexact, one-shot absolute exact, daily/weekly/monthly/yearly recurrence, local wall clock, past-time rejection, pending IDs, cancellation |
| Reminders | Instant, scheduled exact, local wall clock, persistent, looping sound, timeout, actions, full-screen policy, cancellation |

The matrix tab is deterministic and safe to run in widget tests. The other tabs intentionally call the real platform runtime so they should be exercised on Android API 31, 33, 34, 35+, and iOS as described in the setup documentation.
