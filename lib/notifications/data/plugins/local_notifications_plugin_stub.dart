
import 'dart:async';

class LocalNotificationsPlugin {
  Future<void> initialize({
    required String androidDefaultIcon,
    required void Function(String? payload) onTap,
  }) async {
    throw UnsupportedError('Local notifications not available in this build');
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    throw UnsupportedError('Local notifications not available in this build');
  }

  Future<void> cancel(int id) async {
    throw UnsupportedError('Local notifications not available in this build');
  }

  Future<void> cancelAll() async {
    throw UnsupportedError('Local notifications not available in this build');
  }

  Future<bool> areNotificationsEnabled() async => false;
  Future<bool> requestPermission() async => false;
  Future<void> createChannel(Map<String, dynamic> config) async {}
}

LocalNotificationsPlugin createLocalNotificationsPlugin() =>
    LocalNotificationsPlugin();
