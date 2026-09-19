

import 'dart:ui';
import 'notification_channel_config.dart';
import 'fcm_config.dart';
import 'one_signal_config.dart';
import 'permission_config.dart';
import 'reminder_config.dart';
import '../../presentation/dialogs/i_permission_dialog.dart';

enum NotificationProvider {
  localInstant,
  localScheduled,
  localReminder,
  fcm,
  oneSignal,
}

enum LogLevel { verbose, debug, info, warning, error, none }

class NotificationConfig {
  final Set<NotificationProvider> enabledProviders;
  final List<NotificationChannelConfig> channels;
  final String androidDefaultIcon;
  final Color? androidDefaultColor;
  final List<String> iosCategories;
  final Map<String, String> soundAssets;
  final FcmConfig? fcmConfig;
  final OneSignalConfig? oneSignalConfig;
  final PermissionConfig permissionConfig;
  final ReminderConfig reminderConfig;
  final IPermissionDialog? permissionDialog;
  final LogLevel logLevel;

  const NotificationConfig({
    required this.enabledProviders,
    required this.channels,
    required this.androidDefaultIcon,
    this.androidDefaultColor,
    this.iosCategories = const [],
    this.soundAssets = const {},
    this.fcmConfig,
    this.oneSignalConfig,
    this.permissionConfig = const PermissionConfig(),
    this.reminderConfig = const ReminderConfig(),
    this.permissionDialog,
    this.logLevel = LogLevel.info,
  });

  Set<String> get channelIds => channels.map((c) => c.id).toSet();

  NotificationChannelConfig? getChannel(String id) {
    try {
      return channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isProviderEnabled(NotificationProvider provider) =>
      enabledProviders.contains(provider);
}
