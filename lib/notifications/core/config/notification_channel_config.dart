

import 'dart:ui';

enum ChannelImportance { none, min, low, defaultImportance, high, max }

class NotificationChannelConfig {
  final String id;
  final String name;
  final String description;
  final ChannelImportance importance;
  final String? soundName; // Key in soundAssets map
  final List<int>? vibrationPattern;
  final bool showBadge;
  final bool playSound;
  final bool enableVibration;
  final bool enableLights;
  final Color? ledColor;

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
