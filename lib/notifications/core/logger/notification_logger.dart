import '../../d_print.dart';
import '../../domain/repositories/i_notification_logger.dart';
import '../config/notification_config.dart';

class NotificationLogger implements INotificationLogger {
  final LogLevel _level;
  final String _tag;

  NotificationLogger({
    LogLevel level = LogLevel.info,
    String tag = 'NotificationService',
  }) : _level = level,
       _tag = tag;

  bool _shouldLog(LogLevel messageLevel) {
    if (_level == LogLevel.none) return false;
    return messageLevel.index >= _level.index;
  }

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_shouldLog(level)) return;

    final prefix = switch (level) {
      LogLevel.verbose => '🔍',
      LogLevel.debug => '🐛',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
      LogLevel.none => '',
    };

    final timestamp = DateTime.now().toIso8601String();
    dPrint('$prefix [$_tag] $timestamp: $message');
    if (error != null) dPrint('   Error: $error');
    if (stackTrace != null) dPrint('   Stack: $stackTrace');
  }

  @override
  void verbose(String message) => _log(LogLevel.verbose, message);

  @override
  void debug(String message) => _log(LogLevel.debug, message);

  @override
  void info(String message) => _log(LogLevel.info, message);

  @override
  void warning(String message) => _log(LogLevel.warning, message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);
}
