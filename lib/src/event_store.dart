import 'tracked_event.dart';

/// An in-memory queryable store for tracked events.
///
/// Optionally bounded by [maxCapacity]. When the capacity is reached,
/// the oldest events are evicted (FIFO) to make room for new ones.
class EventStore {
  final List<TrackedEvent> _events = [];

  /// The maximum number of events this store will hold, or `null` for unbounded.
  final int? maxCapacity;

  /// Called with an event just before it is evicted due to capacity limits.
  final void Function(TrackedEvent)? onEvict;

  /// Create a new empty event store.
  ///
  /// If [maxCapacity] is provided, the store will automatically evict the
  /// oldest events when the limit is reached. The optional [onEvict] callback
  /// fires for each evicted event.
  EventStore({this.maxCapacity, this.onEvict}) {
    if (maxCapacity != null && maxCapacity! <= 0) {
      throw ArgumentError.value(maxCapacity, 'maxCapacity', 'Must be positive');
    }
  }

  /// Add an event to the store.
  ///
  /// If the store is at [maxCapacity], the oldest event is evicted first.
  void add(TrackedEvent event) {
    if (maxCapacity != null && _events.length >= maxCapacity!) {
      final evicted = _events.removeAt(0);
      onEvict?.call(evicted);
    }
    _events.add(event);
  }

  /// Whether the store has reached its [maxCapacity].
  ///
  /// Always returns `false` for unbounded stores.
  bool get isFull => maxCapacity != null && _events.length >= maxCapacity!;

  /// The remaining capacity, or `null` for unbounded stores.
  int? get remaining =>
      maxCapacity != null ? maxCapacity! - _events.length : null;

  /// Remove all events older than [age] from now.
  ///
  /// Returns the number of events removed.
  int purgeOlderThan(Duration age) {
    final cutoff = DateTime.now().subtract(age);
    final before = _events.length;
    _events.removeWhere((e) => e.timestamp.isBefore(cutoff));
    return before - _events.length;
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
