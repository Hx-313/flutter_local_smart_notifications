import 'dart:async';

import '../../domain/entities/routing_event.dart';

/// Buffers startup notification interactions until an app has subscribed.
class RoutingEventBus {
  RoutingEventBus() {
    _controller = StreamController<RoutingEvent>.broadcast(
      onListen: _flushStartupEvents,
    );
  }

  late final StreamController<RoutingEvent> _controller;
  final List<RoutingEvent> _startupEvents = [];

  Stream<RoutingEvent> get stream => _controller.stream;

  void add(RoutingEvent event) {
    if (_controller.hasListener) {
      _controller.add(event);
    } else {
      _startupEvents.add(event);
    }
  }

  void addAll(Iterable<RoutingEvent> events) {
    for (final event in events) {
      add(event);
    }
  }

  Future<void> dispose() => _controller.close();

  void _flushStartupEvents() {
    if (_startupEvents.isEmpty) return;
    final events = List<RoutingEvent>.of(_startupEvents);
    _startupEvents.clear();
    for (final event in events) {
      _controller.add(event);
    }
  }
}
