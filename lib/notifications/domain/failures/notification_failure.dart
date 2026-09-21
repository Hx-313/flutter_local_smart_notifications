// lib/services/notifications/domain/failures/notification_failure.dart
// DOMAIN | Exhaustive sealed failure types

/// Describes a recoverable failure returned by a notification operation.
sealed class NotificationFailure {
  /// Human-readable explanation of the failure.
  final String message;

  /// Underlying error, when the failure wraps another error.
  final Object? cause;

  /// Stack trace associated with [cause], when available.
  final StackTrace? stackTrace;

  /// Creates a failure with an explanation and optional underlying error.
  const NotificationFailure(this.message, [this.cause, this.stackTrace]);

  /// Returns the failure type followed by its [message].
  @override
  String toString() => '$runtimeType: $message';
}

// Channel errors
/// The notification references a channel that is not configured.
class ChannelNotRegisteredFailure extends NotificationFailure {
  /// Identifier of the missing channel.
  final String channelId;

  /// Creates a failure for an unregistered channel.
  const ChannelNotRegisteredFailure(this.channelId)
    : super('Channel "$channelId" not registered in config');
}

// Permission errors
/// The operating system has not granted notification permission.
class PermissionNotGrantedFailure extends NotificationFailure {
  /// Creates a notification-permission failure.
  const PermissionNotGrantedFailure()
    : super('Notification permission not granted');
}

/// Exact alarm permission is unavailable for an exact schedule.
class ExactAlarmPermissionFailure extends NotificationFailure {
  /// Creates an exact-alarm permission failure.
  const ExactAlarmPermissionFailure()
    : super('Exact alarm permission not granted');
}

/// The current platform does not support the requested operation.
class UnsupportedPlatformFailure extends NotificationFailure {
  /// Name of the unsupported platform.
  final String platform;

  /// Creates a failure for [platform].
  const UnsupportedPlatformFailure(this.platform)
    : super('Notifications are not supported on $platform');
}

/// An operation was attempted before initialization completed.
class NotInitializedFailure extends NotificationFailure {
  /// Creates a not-initialized failure.
  const NotInitializedFailure()
    : super('NotificationService.initialize() has not completed');
}

/// An operation conflicts with the active service lifecycle.
class NotificationLifecycleFailure extends NotificationFailure {
  /// Creates a lifecycle failure with a description.
  const NotificationLifecycleFailure(super.message);
}

/// The supplied notification configuration is invalid.
class InvalidNotificationConfigurationFailure extends NotificationFailure {
  /// Creates a configuration failure with a description.
  const InvalidNotificationConfigurationFailure(super.message);
}

/// The platform has reached its pending-notification capacity.
class PlatformLimitExceededFailure extends NotificationFailure {
  /// Name of the platform whose pending limit was reached.
  final String platform;

  /// Effective maximum number of pending notifications.
  final int effectiveCap;

  /// Number of notifications pending before this request.
  final int currentCount;

  /// Number of notifications requested by the operation.
  final int requestedCount;

  /// Remaining capacity before this request.
  final int remainingCapacity;

  /// Creates a capacity failure with the platform and count details.
  const PlatformLimitExceededFailure({
    required this.platform,
    required this.effectiveCap,
    required this.currentCount,
    required this.requestedCount,
    required this.remainingCapacity,
  }) : super('Pending notification limit exceeded on $platform');
}

/// A permission prompt was cancelled because its owning screen was closed.
class PermissionRequestCancelledFailure extends NotificationFailure {
  /// Creates a cancelled permission-request failure.
  const PermissionRequestCancelledFailure()
    : super('Permission request was cancelled because its screen was closed');
}

// Scheduling errors
/// A notification could not be scheduled.
class SchedulingFailure extends NotificationFailure {
  /// Creates a scheduling failure with an optional underlying error.
  const SchedulingFailure(super.message, [super.cause, super.stackTrace]);
}

/// A notification was scheduled for a time in the past.
class PastTimeFailure extends NotificationFailure {
  /// Time that caused the scheduling failure.
  final DateTime scheduledTime;

  /// Creates a past-time failure for [scheduledTime].
  const PastTimeFailure(this.scheduledTime)
    : super('Cannot schedule notification in the past');
}

// Storage errors
/// Notification data could not be read from storage.
class StorageReadFailure extends NotificationFailure {
  /// Creates a storage-read failure with an optional underlying error.
  const StorageReadFailure(super.message, [super.cause, super.stackTrace]);
}

/// Notification data could not be written to storage.
class StorageWriteFailure extends NotificationFailure {
  /// Creates a storage-write failure with an optional underlying error.
  const StorageWriteFailure(super.message, [super.cause, super.stackTrace]);
}

// Provider errors
/// An operation requires a feature that is disabled in the configuration.
class ProviderNotEnabledFailure extends NotificationFailure {
  /// Name of the disabled feature or provider.
  final String provider;

  /// Creates a failure for disabled [provider].
  const ProviderNotEnabledFailure(this.provider)
    : super('Provider "$provider" not enabled in config');
}

/// A notification provider failed while starting.
class ProviderInitializationFailure extends NotificationFailure {
  /// Creates an initialization failure with optional underlying details.
  const ProviderInitializationFailure(
    super.message, [
    super.cause,
    super.stackTrace,
  ]);
}

// Reminder errors
/// The configured maximum number of active reminders has been reached.
class ReminderLimitExceededFailure extends NotificationFailure {
  /// Maximum number of active reminders allowed.
  final int maxAllowed;

  /// Creates a reminder-limit failure.
  const ReminderLimitExceededFailure(this.maxAllowed)
    : super('Maximum active reminders ($maxAllowed) exceeded');
}

/// The requested reminder identifier does not exist.
class ReminderNotFoundFailure extends NotificationFailure {
  /// Identifier of the reminder that was not found.
  final int reminderId;

  /// Creates a failure for missing reminder [reminderId].
  const ReminderNotFoundFailure(this.reminderId)
    : super('Reminder with id $reminderId not found');
}

// General errors
/// A failure that does not have a more specific failure type.
class UnknownFailure extends NotificationFailure {
  /// Creates an unknown failure with optional underlying details.
  const UnknownFailure(super.message, [super.cause, super.stackTrace]);
}
