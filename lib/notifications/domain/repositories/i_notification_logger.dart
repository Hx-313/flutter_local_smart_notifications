// lib/services/notifications/domain/repositories/i_notification_logger.dart
// DOMAIN | Logger interface

abstract interface class INotificationLogger {
  void verbose(String message);
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}
