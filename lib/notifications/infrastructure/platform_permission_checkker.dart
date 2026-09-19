// lib/services/notifications/infrastructure/platform/platform_permission_checker.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/permission_status.dart';

class PlatformPermissionChecker {
  static Future<NotificationPermissionState> check({
    required bool reminderProviderEnabled,
  }) async {
    if (Platform.isIOS) {
      return _checkIOS();
    } else if (Platform.isAndroid) {
      return _checkAndroid(reminderProviderEnabled: reminderProviderEnabled);
    }
    // Desktop / other — assume granted
    return const NotificationPermissionState(
      canShowNotifications: true,
      canScheduleExact: true,
      needsExactAlarmSetting: false,
      isPermanentlyDenied: false,
    );
  }

  static Future<NotificationPermissionState> _checkIOS() async {
    // iOS uses a single permission gate for all notification types
    final status = await Permission.notification.status;
    return NotificationPermissionState(
      canShowNotifications: status.isGranted,
      canScheduleExact: true, // iOS has no separate exact alarm gate
      needsExactAlarmSetting: false,
      isPermanentlyDenied: status.isPermanentlyDenied,
    );
  }

  static Future<NotificationPermissionState> _checkAndroid({
    required bool reminderProviderEnabled,
  }) async {
    final sdk = await _androidSdkVersion();

    // Android < 13: POST_NOTIFICATIONS didn't exist — always granted
    final bool canNotify;
    final bool permanentlyDenied;

    if (sdk >= 33) {
      final status = await Permission.notification.status;
      canNotify = status.isGranted;
      permanentlyDenied = status.isPermanentlyDenied;
    } else {
      canNotify = true;
      permanentlyDenied = false;
    }

    // Exact alarms: Android 12 (sdk 31) split into SCHEDULE_EXACT_ALARM
    // Android 13+ (sdk 33) apps targeting 33+ also need USE_EXACT_ALARM or
    // runtime grant from settings — cannot request at runtime, must deep-link
    bool canScheduleExact = true;
    bool needsExactAlarmSetting = false;

    if (reminderProviderEnabled && sdk >= 31) {
      final exactStatus = await Permission.scheduleExactAlarm.status;
      canScheduleExact = exactStatus.isGranted;
      // scheduleExactAlarm can never be requested via requestPermission()
      // on SDK 31+ — user must go to Settings > Apps > Special app access
      needsExactAlarmSetting = !exactStatus.isGranted;
    }

    return NotificationPermissionState(
      canShowNotifications: canNotify,
      canScheduleExact: canScheduleExact,
      needsExactAlarmSetting: needsExactAlarmSetting,
      isPermanentlyDenied: permanentlyDenied,
    );
  }

  static Future<int> _androidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }
}
