import 'tracked_event.dart';

/// An in-memory queryable store for tracked events.
class EventStore {
  final List<TrackedEvent> _events = [];

  /// Create a new empty event store.
  EventStore();

  /// Add an event to the store.
  void add(TrackedEvent event) {
    _events.add(event);
  }

  /// Return all stored events.
  List<TrackedEvent> all() => List.unmodifiable(_events);

  /// Return all events with the given [name].
  List<TrackedEvent> eventsNamed(String name) =>
      _events.where((e) => e.name == name).toList();

  /// Return events whose timestamp falls between [start] and [end] (inclusive).
  List<TrackedEvent> eventsBetween(DateTime start, DateTime end) =>
      _events
          .where((e) =>
              !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
          .toList();

  /// Search events by [query]. Matches against event name and property values.
  List<TrackedEvent> search(String query) {
    final lower = query.toLowerCase();
    return _events.where((e) {
      if (e.name.toLowerCase().contains(lower)) return true;
      for (final value in e.properties.values) {
        if (value.toLowerCase().contains(lower)) return true;
      }
      return false;
    }).toList();
  }

  /// Return a summary mapping each event name to its count.
  Map<String, int> summary() {
    final map = <String, int>{};
    for (final event in _events) {
      map[event.name] = (map[event.name] ?? 0) + 1;
    }
    return map;
  }

  /// Remove all events from the store.
  void clear() {
    _events.clear();
  }

  /// The number of events in the store.
  int get count => _events.length;

  /// Query events with optional predicate, limit, and offset.
  List<TrackedEvent> query({
    bool Function(TrackedEvent)? where,
    int? limit,
    int? offset,
  }) {
    var results = where != null ? _events.where(where).toList() : List.of(_events);
    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }
    return results;
  }

  /// Get all distinct event names.
  List<String> distinctNames() {
    return _events.map((e) => e.name).toSet().toList()..sort();
  }

  /// Return all events with the given [priority].
  List<TrackedEvent> byPriority(EventPriority priority) =>
      _events.where((e) => e.priority == priority).toList();

  /// Return all events with the given [sessionId].
  List<TrackedEvent> bySession(String sessionId) =>
      _events.where((e) => e.sessionId == sessionId).toList();

  /// Export all events as a formatted string.
  String export() {
    final buffer = StringBuffer();
    for (final event in _events) {
      buffer.writeln(
          '${event.timestamp.toIso8601String()} [${event.name}] ${event.properties}');
    }
    return buffer.toString();
  }
}
