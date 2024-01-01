import 'tracked_event.dart';

/// Abstract sink that receives batches of events.
abstract class EventSink {
  /// Send a batch of events to this sink.
  Future<void> send(List<TrackedEvent> events);
}

/// A sink that prints events to stdout.
class ConsoleSink implements EventSink {
  /// Create a console sink.
  const ConsoleSink();

  @override
  Future<void> send(List<TrackedEvent> events) async {
    for (final event in events) {
      print('[EventTracker] ${event.name} ${event.properties} '
          'at ${event.timestamp.toIso8601String()}');
    }
  }
}

/// A sink that stores events in memory. Useful for testing.
class MemorySink implements EventSink {
  /// All events received by this sink.
  final List<TrackedEvent> events = [];

  /// Create a memory sink.
  MemorySink();

  @override
  Future<void> send(List<TrackedEvent> events) async {
    this.events.addAll(events);
  }
}
