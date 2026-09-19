# Agent guide

## Scope

This is a local-only Flutter package. Keep Firebase, OneSignal, and other push SDKs out of its dependency graph and public API. Push integrations belong in separate packages/adapters.

The stable public entry point is `lib/flutter_local_smart_notifications.dart`; do not expose internal repositories or platform plugin classes from it.

## Design rules

- Public operations return `NotificationResult<T>` and use typed `NotificationFailure` values for recoverable failures.
- `NotificationService.instance` must not throw when uninitialized; its operations return `NotInitializedFailure`.
- Keep a single active `NotificationService` runtime. Dispose it before changing configuration.
- Do not silently downgrade an exact alarm to inexact scheduling.
- Treat `localWallClock` and `absoluteInstant` schedules differently when a device timezone changes.
- Background notification callbacks cannot use singleton/in-memory state. Persist the routing event and deliver it at the next initialization.
- Do not add a package-owned Android manifest. Update `docs/SETUP.md` when an upstream native requirement changes.

## Development workflow

Run these from the repository root:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Add a focused regression test for non-trivial behavior. Keep production code under `lib/notifications/` and test only public behavior unless an internal codec/storage detail requires a narrowly scoped unit test.

## Documentation and platform work

When modifying scheduling, permissions, setup, or capability limits, update `README.md`, `docs/SETUP.md`, and/or `docs/ARCHITECTURE.md` in the same change. Test Android API 31, 33, 34, and 35+ for permission and exact-alarm behavior before release.

`AGENTS.md` is shared project guidance. The similarly named local agent-state files and directories are ignored in `.gitignore`; do not put durable repository instructions there.
