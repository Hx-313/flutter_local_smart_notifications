import 'dart:ui';
import 'notification_channel_config.dart';
import 'permission_config.dart';
import 'reminder_config.dart';
import '../../presentation/dialogs/i_permission_dialog.dart';

/// A local notification feature that can be enabled in [NotificationConfig].
enum NotificationFeature {
  /// Enables immediate local notifications.
  localInstant,

  /// Enables local notifications scheduled for a future time.
  localScheduled,

  /// Enables reminder notifications.
  localReminder,
}

/// Compatibility alias for [NotificationFeature].
typedef NotificationProvider = NotificationFeature;

/// Minimum severity of messages emitted by the notification logger.
enum LogLevel {
  /// Includes detailed diagnostic messages.
  verbose,

  /// Includes debugging messages and more severe messages.
  debug,

  /// Includes informational messages and more severe messages.
  info,

  /// Includes warnings and errors.
  warning,

  /// Includes errors only.
  error,

  /// Disables package logging.
  none,
}

/// Configuration shared by the local notification service.
class NotificationConfig {
  /// Local notification features available to the service.
  final Set<NotificationFeature> enabledProviders;

  /// Android notification channels available to notification payloads.
  final List<NotificationChannelConfig> channels;

  /// Android drawable resource name used as the default small icon.
  final String androidDefaultIcon;

  /// Default Android notification color.
  final Color? androidDefaultColor;

  /// Maps sound names used by notifications to bundled asset paths.
  final Map<String, String> soundAssets;

  /// Permission prompting and requested permission options.
  final PermissionConfig permissionConfig;

  /// Reminder limits and scheduling defaults.
  final ReminderConfig reminderConfig;

  /// Optional UI shown when permission has been permanently denied.
  final IPermissionDialog? permissionDialog;

  /// Minimum severity of package log messages.
  final LogLevel logLevel;

  /// Creates the configuration used to initialize `NotificationService`.
  const NotificationConfig({
    required this.enabledProviders,
    required this.channels,
    required this.androidDefaultIcon,
    this.androidDefaultColor,
    this.soundAssets = const {},
    this.permissionConfig = const PermissionConfig(),
    this.reminderConfig = const ReminderConfig(),
    this.permissionDialog,
    this.logLevel = LogLevel.info,
  });

  /// Identifiers of all configured notification channels.
  Set<String> get channelIds => channels.map((c) => c.id).toSet();

  /// Returns the channel with [id], or `null` if no channel matches.
  NotificationChannelConfig? getChannel(String id) {
    try {
      return channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Whether [feature] is enabled in [enabledProviders].
  bool isFeatureEnabled(NotificationFeature feature) =>
      enabledProviders.contains(feature);

  /// Whether [provider] is enabled; retained as an alias for
  /// [isFeatureEnabled].
  bool isProviderEnabled(NotificationFeature provider) =>
      enabledProviders.contains(provider);
}
