// lib/services/notifications/domain/failures/notification_failure.dart
// DOMAIN | Exhaustive sealed failure types

sealed class NotificationFailure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const NotificationFailure(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

// Channel errors
class ChannelNotRegisteredFailure extends NotificationFailure {
  final String channelId;
  const ChannelNotRegisteredFailure(this.channelId)
    : super('Channel "$channelId" not registered in config');
}

// Permission errors
class PermissionNotGrantedFailure extends NotificationFailure {
  const PermissionNotGrantedFailure()
    : super('Notification permission not granted');
}

class ExactAlarmPermissionFailure extends NotificationFailure {
  const ExactAlarmPermissionFailure()
    : super('Exact alarm permission not granted');
}

// Scheduling errors
class SchedulingFailure extends NotificationFailure {
  const SchedulingFailure(super.message, [super.cause, super.stackTrace]);
}

class PastTimeFailure extends NotificationFailure {
  final DateTime scheduledTime;
  const PastTimeFailure(this.scheduledTime)
    : super('Cannot schedule notification in the past');
}

// Token errors
class TokenNotAvailableFailure extends NotificationFailure {
  const TokenNotAvailableFailure() : super('Push token not available');
}

class TokenRefreshFailure extends NotificationFailure {
  const TokenRefreshFailure(super.message, [super.cause, super.stackTrace]);
}

// Storage errors
class StorageReadFailure extends NotificationFailure {
  const StorageReadFailure(super.message, [super.cause, super.stackTrace]);
}

class StorageWriteFailure extends NotificationFailure {
  const StorageWriteFailure(super.message, [super.cause, super.stackTrace]);
}

// Provider errors
class ProviderNotEnabledFailure extends NotificationFailure {
  final String provider;
  const ProviderNotEnabledFailure(this.provider)
    : super('Provider "$provider" not enabled in config');
}

class ProviderInitializationFailure extends NotificationFailure {
  const ProviderInitializationFailure(
    super.message, [
    super.cause,
    super.stackTrace,
  ]);
}

// Reminder errors
class ReminderLimitExceededFailure extends NotificationFailure {
  final int maxAllowed;
  const ReminderLimitExceededFailure(this.maxAllowed)
    : super('Maximum active reminders ($maxAllowed) exceeded');
}

class ReminderNotFoundFailure extends NotificationFailure {
  final int reminderId;
  const ReminderNotFoundFailure(this.reminderId)
    : super('Reminder with id $reminderId not found');
}

// General errors
class UnknownFailure extends NotificationFailure {
  const UnknownFailure(super.message, [super.cause, super.stackTrace]);
}
