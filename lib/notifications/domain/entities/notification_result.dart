// lib/services/notifications/domain/entities/notification_result.dart
// DOMAIN | Operation result with success/failure

import '../failures/notification_failure.dart';

/// Result returned by a notification service operation.
///
/// A result is either [NotificationSuccess] or [NotificationFailureResult].
sealed class NotificationResult<T> {
  /// Creates a result value.
  const NotificationResult();

  /// Whether this result contains a value.
  bool get isSuccess => this is NotificationSuccess<T>;

  /// Whether this result contains a [NotificationFailure].
  bool get isFailure => this is NotificationFailureResult<T>;

  /// The success value, or `null` when this is a failure result.
  T? get valueOrNull => this is NotificationSuccess<T>
      ? (this as NotificationSuccess<T>).value
      : null;

  /// The failure, or `null` when this is a success result.
  NotificationFailure? get failureOrNull => this is NotificationFailureResult<T>
      ? (this as NotificationFailureResult<T>).failure
      : null;

  /// Calls the callback for the result's success or failure case.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(NotificationFailure failure) onFailure,
  }) => switch (this) {
    NotificationSuccess<T>(value: final v) => onSuccess(v),
    NotificationFailureResult<T>(failure: final f) => onFailure(f),
  };
}

/// Successful result containing a value of type [T].
class NotificationSuccess<T> extends NotificationResult<T> {
  /// Value produced by the operation.
  final T value;

  /// Creates a successful result containing [value].
  const NotificationSuccess(this.value);
}

/// Failed result containing a typed [NotificationFailure].
class NotificationFailureResult<T> extends NotificationResult<T> {
  /// Failure that explains why the operation did not succeed.
  final NotificationFailure failure;

  /// Creates a failed result containing [failure].
  const NotificationFailureResult(this.failure);
}
