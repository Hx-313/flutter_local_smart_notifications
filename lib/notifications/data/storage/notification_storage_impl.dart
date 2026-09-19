// ignore_for_file: override_on_non_overriding_member

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_result.dart';
import '../../domain/entities/reminder_notification.dart';
import '../../domain/entities/routing_event.dart';
import '../../domain/failures/notification_failure.dart';
import '../../domain/repositories/i_notification_storage.dart';

class NotificationStorageImpl implements INotificationStorage {
  static const _remindersKey = 'ns_reminders';
  static const _permissionAskedKey = 'ns_permission_asked';
  static const _denialCountKey = 'ns_denial_count';
  static const _permissionDialogAtKey = 'ns_permission_dialog_at';
  static const _pendingRoutingEventsKey = 'ns_pending_routing_events';
  static const _lastKnownTimezoneKey = 'ns_last_known_timezone';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<NotificationResult<void>> saveReminder(
    ReminderNotification reminder,
  ) async {
    try {
      final prefs = await _preferences;
      final reminders = await _getRemindersMap();
      reminders[reminder.payload.id.toString()] = reminder.toMap();
      await prefs.setString(_remindersKey, jsonEncode(reminders));
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to save reminder', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<ReminderNotification?>> getReminder(int id) async {
    try {
      final reminders = await _getRemindersMap();
      final data = reminders[id.toString()];
      if (data == null) return const NotificationSuccess(null);
      return NotificationSuccess(ReminderNotification.fromMap(data));
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read reminder', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<List<ReminderNotification>>>
  getAllReminders() async {
    try {
      final reminders = await _getRemindersMap();
      final list = reminders.values
          .map((data) => ReminderNotification.fromMap(data))
          .toList();
      return NotificationSuccess(list);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read reminders', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> removeReminder(int id) async {
    try {
      final prefs = await _preferences;
      final reminders = await _getRemindersMap();
      reminders.remove(id.toString());
      await prefs.setString(_remindersKey, jsonEncode(reminders));
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to remove reminder', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> clearAllReminders() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_remindersKey);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to clear reminders', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> savePermissionAsked(bool asked) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_permissionAskedKey, asked);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to save permission state', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> hasPermissionBeenAsked() async {
    try {
      final prefs = await _preferences;
      return NotificationSuccess(prefs.getBool(_permissionAskedKey) ?? false);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read permission state', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> incrementDenialCount() async {
    try {
      final prefs = await _preferences;
      final current = prefs.getInt(_denialCountKey) ?? 0;
      await prefs.setInt(_denialCountKey, current + 1);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to update denial count', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> resetDenialCount() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_denialCountKey);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to reset denial count', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<int>> getDenialCount() async {
    try {
      final prefs = await _preferences;
      return NotificationSuccess(prefs.getInt(_denialCountKey) ?? 0);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read denial count', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<bool>> shouldShowPermissionDialog({
    required Duration cooldown,
  }) async {
    try {
      final prefs = await _preferences;
      final lastShown = prefs.getInt(_permissionDialogAtKey);
      if (lastShown == null) return const NotificationSuccess(true);
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastShown),
      );
      return NotificationSuccess(elapsed >= cooldown);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read permission dialog cooldown', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> recordPermissionPromptShown() async {
    try {
      final prefs = await _preferences;
      await prefs.setInt(
        _permissionDialogAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to save permission dialog time', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> savePendingRoutingEvent(
    RoutingEvent event,
  ) async {
    try {
      final prefs = await _preferences;
      final events = prefs.getStringList(_pendingRoutingEventsKey) ?? [];
      events.add(jsonEncode(event.toMap()));
      await prefs.setStringList(_pendingRoutingEventsKey, events);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to save pending routing event', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<List<RoutingEvent>>>
  consumePendingRoutingEvents() async {
    try {
      final prefs = await _preferences;
      final encoded = prefs.getStringList(_pendingRoutingEventsKey) ?? [];
      final events = encoded
          .map(
            (item) => RoutingEvent.fromMap(
              Map<String, dynamic>.from(jsonDecode(item) as Map),
            ),
          )
          .toList();
      await prefs.remove(_pendingRoutingEventsKey);
      return NotificationSuccess(events);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to restore pending routing events', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<String?>> getLastKnownTimezone() async {
    try {
      final prefs = await _preferences;
      return NotificationSuccess(prefs.getString(_lastKnownTimezoneKey));
    } catch (e, s) {
      return NotificationFailureResult(
        StorageReadFailure('Failed to read last known timezone', e, s),
      );
    }
  }

  @override
  Future<NotificationResult<void>> saveLastKnownTimezone(
    String timezone,
  ) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_lastKnownTimezoneKey, timezone);
      return const NotificationSuccess(null);
    } catch (e, s) {
      return NotificationFailureResult(
        StorageWriteFailure('Failed to save last known timezone', e, s),
      );
    }
  }

  Future<Map<String, dynamic>> _getRemindersMap() async {
    final prefs = await _preferences;
    final json = prefs.getString(_remindersKey);
    if (json == null) return {};
    return Map<String, dynamic>.from(jsonDecode(json));
  }
}
