## 0.2.0

### Changed

- Upgrade to Flutter `3.50.0` or newer and Dart `3.12.0` or newer.
- Migrate to the decoupled standalone `material_ui` package (`^1.11.1`).
- Decouple presentation interfaces (`IPermissionDialog`, `NotificationService`) from Material UI to use core style-neutral `package:flutter/widgets.dart`.
- Upgrade `flutter_local_notifications` to `^23.0.3` with support for Android `compileSdk 37`, AGP 9.1.1, and live update notifications.
- Upgrade dependencies: `device_info_plus: ^13.3.0`, `flutter_timezone: ^5.1.1`, `shared_preferences: ^2.5.6`, `timezone: ^0.11.2`, and `app_settings: ^9.0.1`.
- Update setup documentation and example configuration for Android `compileSdk 37`.

## 0.1.1

### Changed

- Bump the pub.dev release version for the Flutter 3.44+ support update.

## 0.1.0

### Changed

- Add Dartdoc coverage across the public API.
- Align the example app theme and Android notification color with the new logo.
- Remove unused notification options and push-token failure types from the public API.
- Remove unused permission UI and forwarding use cases.
- Require Flutter `3.44.0` or newer and Dart `3.11.3` or newer.

## 0.0.1

Initial release of `flutter_local_smart_notifications`.

### Added

- Show local notifications immediately or schedule them for a future time.
- Repeat schedules daily, weekly, monthly, or yearly.
- Choose between local-wall-clock and absolute-instant scheduling semantics.
- Request exact Android timing without silently downgrading to inexact delivery.
- Create persistent, high-priority reminders with timeouts, looping sound,
  action buttons, and optional full-screen intent requests.
- Configure notification channels, sounds, permission prompts, reminder limits,
  and pending-notification budgets.
- Receive typed permission statuses and `NotificationResult<T>` failure values.
- Route notification taps, action taps, dismissals, and timeouts with
  `RoutingEvent` data, including persisted background events.
- Restore persisted reminders and reconcile schedules after lifecycle changes
  and Android reboot recovery setup.
- Keep the package local-only, with no Firebase, OneSignal, or other push SDK
  dependency.
- Document consumer Android and iOS setup, capability limits, and the complete
  runnable example application.
