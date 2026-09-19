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
