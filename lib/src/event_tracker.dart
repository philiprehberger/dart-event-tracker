import 'buffered_sink.dart';
import 'event_sink.dart';
import 'event_store.dart';
import 'tracked_event.dart';

/// Main event tracker that coordinates tracking, filtering, storing, and
/// sinking of analytics events.
class EventTracker {
  final List<EventSink> _sinks = [];
  final List<bool Function(TrackedEvent)> _filters = [];
  Duration? _dedupeWindow;
  TrackedEvent? _lastEvent;
  final List<TrackedEvent Function(TrackedEvent)> _enrichers = [];

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

  /// Enable event deduplication within a time window.
  ///
  /// Events with the same name and properties within [window] are suppressed.
  void deduplicate(Duration window) {
    _dedupeWindow = window;
  }

  /// Add an enricher that transforms events before they are sunk.
  ///
  /// Enrichers run in order and can add context like device info or session ID.
  void addEnricher(TrackedEvent Function(TrackedEvent) enricher) {
    _enrichers.add(enricher);
  }

  /// Track a new event with the given [name] and optional [properties].
  ///
  /// The event is stored in the internal [store] and sent to all sinks,
  /// provided it passes all registered filters.
  Future<void> track(String name, {Map<String, String>? properties}) async {
    var event = TrackedEvent(name, properties: properties);

    // Check deduplication
    if (_dedupeWindow != null && _lastEvent != null) {
      final elapsed = event.timestamp.difference(_lastEvent!.timestamp);
      if (elapsed <= _dedupeWindow! &&
          event.name == _lastEvent!.name &&
          _mapsEqual(event.properties, _lastEvent!.properties)) {
        return;
      }
    }

    // Run enrichers
    for (final enricher in _enrichers) {
      event = enricher(event);
    }

    // Apply filters
    for (final filter in _filters) {
      if (!filter(event)) return;
    }

    _lastEvent = event;
    store.add(event);

    for (final sink in _sinks) {
      await sink.send([event]);
    }
  }

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
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
