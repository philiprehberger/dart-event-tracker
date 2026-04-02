import 'buffered_sink.dart';
import 'event_sink.dart';
import 'event_store.dart';
import 'tracked_event.dart';

/// Main event tracker that coordinates tracking, filtering, storing, and
/// sinking of analytics events.
class EventTracker {
  final List<EventSink> _sinks = [];
  final List<bool Function(TrackedEvent)> _filters = [];

  /// The internal event store for querying tracked events.
  final EventStore store = EventStore();

  /// Create a new event tracker.
  EventTracker();

  /// Add a sink that will receive tracked events.
  void addSink(EventSink sink) {
    _sinks.add(sink);
  }

  /// Remove a previously added sink.
  void removeSink(EventSink sink) {
    _sinks.remove(sink);
  }

  /// Add a filter. Events that do not pass any filter are dropped.
  ///
  /// If no filters are added, all events pass through.
  /// If one or more filters are added, an event must pass **all** filters.
  void addFilter(bool Function(TrackedEvent) filter) {
    _filters.add(filter);
  }

  /// Track a new event with the given [name] and optional [properties].
  ///
  /// The event is stored in the internal [store] and sent to all sinks,
  /// provided it passes all registered filters.
  Future<void> track(String name, {Map<String, String>? properties}) async {
    final event = TrackedEvent(name, properties: properties);

    // Apply filters
    for (final filter in _filters) {
      if (!filter(event)) return;
    }

    store.add(event);

    for (final sink in _sinks) {
      await sink.send([event]);
    }
  }

  /// Force all [BufferedSink] instances to flush their pending events.
  Future<void> flush() async {
    for (final sink in _sinks) {
      if (sink is BufferedSink) {
        await sink.flush();
      }
    }
  }
}
