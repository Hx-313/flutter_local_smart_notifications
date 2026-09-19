// lib/services/notifications/domain/entities/notification_result.dart
// DOMAIN | Operation result with success/failure

import '../failures/notification_failure.dart';

sealed class NotificationResult<T> {
  const NotificationResult();

  bool get isSuccess => this is NotificationSuccess<T>;
  bool get isFailure => this is NotificationFailureResult<T>;

  T? get valueOrNull => this is NotificationSuccess<T>
      ? (this as NotificationSuccess<T>).value
      : null;

  NotificationFailure? get failureOrNull => this is NotificationFailureResult<T>
      ? (this as NotificationFailureResult<T>).failure
      : null;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(NotificationFailure failure) onFailure,
  }) => switch (this) {
    NotificationSuccess<T>(value: final v) => onSuccess(v),
    NotificationFailureResult<T>(failure: final f) => onFailure(f),
  };
}

class NotificationSuccess<T> extends NotificationResult<T> {
  final T value;
  const NotificationSuccess(this.value);
}

class NotificationFailureResult<T> extends NotificationResult<T> {
  final NotificationFailure failure;
  const NotificationFailureResult(this.failure);
}
