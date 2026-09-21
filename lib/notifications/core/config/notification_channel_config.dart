import 'dart:ui';

/// Controls how prominently a notification channel is presented on Android.
enum ChannelImportance {
  /// Suppresses sound and visual interruption for channel notifications.
  none,

  /// Presents channel notifications with minimal interruption.
  min,

  /// Presents channel notifications with low interruption.
  low,

  /// Uses the platform's default channel importance.
  defaultImportance,

  /// Presents channel notifications with high interruption.
  high,

  /// Presents channel notifications with maximum interruption.
  max,
}

/// Defines the Android notification channel used by a notification.
class NotificationChannelConfig {
  /// Stable identifier used to select this channel.
  final String id;

  /// User-visible channel name.
  final String name;

  /// User-visible explanation of the channel's purpose.
  final String description;

  /// Android interruption level for notifications on this channel.
  final ChannelImportance importance;

  /// Key of the channel sound in `NotificationConfig.soundAssets`.
  final String? soundName; // Key in soundAssets map

  /// Vibration durations, in milliseconds, alternating between off and on.
  final List<int>? vibrationPattern;

  /// Whether notifications on this channel may show an app badge.
  final bool showBadge;

  /// Whether notifications on this channel may play a sound.
  final bool playSound;

  /// Whether notifications on this channel may vibrate.
  final bool enableVibration;

  /// Whether notifications on this channel may show notification lights.
  final bool enableLights;

  /// LED color used when notification lights are enabled.
  final Color? ledColor;

  /// Creates a notification channel configuration.
  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    this.importance = ChannelImportance.high,
    this.soundName,
    this.vibrationPattern,
    this.showBadge = true,
    this.playSound = true,
    this.enableVibration = true,
    this.enableLights = true,
    this.ledColor,
  });
}
