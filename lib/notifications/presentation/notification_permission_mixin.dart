// lib/features/.../presentation/mixins/notification_permission_mixin.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

mixin NotificationPermissionMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _checkingPermissions = false;
  bool _waitingForSettingsReturn = false;

  /// Call this from initState after first frame or after login.
  Future<void> checkAndPromptNotificationPermission({
    bool remindersNeedExactAlarm = true,
  }) async {
    if (!mounted || _checkingPermissions) return;

    _checkingPermissions = true;

    try {
      // ------------------------------------------------------------------
      // 1. BASIC NOTIFICATION PERMISSION
      // iOS: native notification prompt
      // Android 13+: native POST_NOTIFICATIONS prompt
      // Android <=12: normally granted unless user disabled app notifications
      // ------------------------------------------------------------------
      var notificationStatus = await Permission.notification.status;

      if (notificationStatus.isDenied) {
        notificationStatus = await Permission.notification.request();
      }

      if (!mounted) return;

      // On iOS, once denied, it effectively needs Settings.
      // On Android, permanentlyDenied also needs Settings.
      if (notificationStatus.isPermanentlyDenied ||
          notificationStatus.isRestricted) {
        await _showSettingsBottomSheet(
          title: 'Enable Notifications',
          message:
              'Notifications are disabled. Please enable them from app settings to receive reminders.',
          primaryLabel: 'Open Settings',
          onPrimaryPressed: () async {
            _waitingForSettingsReturn = true;
            await openAppSettings();
          },
        );
        return;
      }

      if (!notificationStatus.isGranted &&
          !notificationStatus.isLimited &&
          !notificationStatus.isProvisional) {
        return;
      }

      // ------------------------------------------------------------------
      // 2. ADVANCED PERMISSION: EXACT ALARM
      // Android 12+ special access.
      // Only needed if you schedule exact reminders.
      // ------------------------------------------------------------------
      if (Platform.isAndroid && remindersNeedExactAlarm) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;

        if (!exactAlarmStatus.isGranted) {
          if (!mounted) return;

          await _showSettingsBottomSheet(
            title: 'Allow Reminders',
            message:
                'To fire reminders exactly on time, please allow Alarms & reminders access.',
            primaryLabel: 'Open Alarm Settings',
            onPrimaryPressed: () async {
              _waitingForSettingsReturn = true;

              // Opens Android's special access screen for exact alarms.
              await Permission.scheduleExactAlarm.request();
            },
          );
        }
      }
    } finally {
      _checkingPermissions = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_waitingForSettingsReturn) return;

    _waitingForSettingsReturn = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      checkAndPromptNotificationPermission();
    });
  }

  Future<void> _showSettingsBottomSheet({
    required String title,
    required String message,
    required String primaryLabel,
    required Future<void> Function() onPrimaryPressed,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await onPrimaryPressed();
                    },
                    child: Text(primaryLabel),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Not Now'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
