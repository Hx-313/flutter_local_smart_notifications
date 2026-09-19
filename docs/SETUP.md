# Consumer setup

`flutter_local_smart_notifications` does not merge a manifest or modify host project files. Complete the entries below in every consuming app according to the features it uses.

## Android manifest

For scheduled notifications and reboot restoration, put these entries in `android/app/src/main/AndroidManifest.xml`.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- Add only when exactTiming: true or ReminderConfig(useExactAlarm: true) is used. -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <application>
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>

        <!-- Add only if your reminders use NotificationAction. -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
            android:exported="false" />
    </application>
</manifest>
```

`flutter_local_notifications` supplies its basic `POST_NOTIFICATIONS` and `VIBRATE` manifest declarations. The consumer declarations above are still required for scheduling and reboot restoration.

### Exact alarms and Play policy

Use `SCHEDULE_EXACT_ALARM`. When an app requests `includeExactAlarm: true`, the package uses the system special-access flow; scheduling returns `ExactAlarmPermissionFailure` if access remains unavailable. Do **not** declare `USE_EXACT_ALARM` for this package's flow. It bypasses the user grant and can trigger store eligibility review.

Review Android's [exact-alarm behavior](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) and the [Google Play exact-alarm policy](https://support.google.com/googleplay/android-developer/answer/16909972) before publishing. Use exact alarms only for a user-visible feature that genuinely needs precise timing.

This package does not require `USE_FULL_SCREEN_INTENT`. Declare that permission only after separately establishing that your product and Play policy eligibility require a full-screen alarm UI.

The boot receiver lets Android restore scheduled work after a restart. Dart cannot run immediately after a reboot; the package also re-syncs persisted reminders the next time the app starts. Permission changes are similarly observed at app launch and resume, not while a closed app is inactive.

## Android Gradle

`flutter_local_notifications` 22.x requires compile SDK 35 or newer and Java 17/desugaring configuration. In `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35

    defaultConfig {
        multiDexEnabled = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

For Groovy projects, use the equivalent `coreLibraryDesugaringEnabled true` setting and dependency. Keep Android Gradle Plugin compatible with Java 17 and your Flutter version.

## Android resources

`androidDefaultIcon` is a native Android resource name, not an arbitrary file path. For example, `@mipmap/ic_launcher` requires an `ic_launcher` asset in the app's mipmap resources. Custom Android sounds must be lower-case raw resources in `android/app/src/main/res/raw/`; register each usable sound name in `NotificationConfig.soundAssets`.

## iOS

Enable only the notifications macro for `permission_handler` in the consumer `ios/Podfile`. Inside the existing `post_install` target/configuration loop:

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_NOTIFICATIONS=1'
```

Do not copy the full `permission_handler` macro list: this package uses notifications only. No notification usage-description key is required in `Info.plist`. Add custom sounds to the iOS app target and list their file names in `soundAssets`.

iOS permits at most 64 pending notifications. The package uses the lower of `ReminderConfig.maxPendingNotifications` and `64 - iosReservedSlots`; the defaults are 60 and 4 respectively. A capacity problem returns `PlatformLimitExceededFailure` with the platform, cap, current count, and remaining capacity.

## Dart integration checklist

1. Declare the channels your payloads will use.
2. Await `NotificationService.initialize(config)` before calling the singleton.
3. Request notification access from a contextual UI interaction. Request exact-alarm access only when the user selects a feature that needs exact timing. Exact timing is enabled per notification with `exactTiming: true`, or as an explicit reminder default with `ReminderConfig(useExactAlarm: true)`.
4. Subscribe to `onRoutingEvent` after initialization. Background interaction events are stored and delivered after the next runtime initialization.
5. For time-of-day reminders choose `localWallClock`; absolute one-off deadlines should use `absoluteInstant`.

## Verification matrix

Validate on physical/emulated Android API 31, 33, 34, and 35+:

- notification permission granted, denied, permanently denied, and revoked in Settings;
- exact-alarm grant and refusal;
- an exact and an inexact schedule;
- reboot restoration with the boot receiver declared;
- timezone change for both schedule semantics;
- notification tap, action tap, and background tap routing.

Validate iOS permission denial/settings return, regular schedule delivery, and the pending-notification capacity boundary.
