import 'dart:math';

/// Priority levels for tracked events.
enum EventPriority {
  /// Low priority event.
  low,

  /// Normal priority event (default).
  normal,

  /// High priority event.
  high,

  /// Critical priority event.
  critical,
}

/// An analytics event with a name, properties, and timestamp.
class TrackedEvent {
  /// The event name.
  final String name;

  /// Key-value properties attached to this event.
  final Map<String, String> properties;

  /// When the event occurred.
  final DateTime timestamp;

  /// Unique identifier for this event.
  final String id;

  /// The priority level of this event.
  final EventPriority priority;

  /// Optional session identifier for grouping events.
  final String? sessionId;

  /// Create a new tracked event.
  ///
  /// If [id] is not provided, a random UUID-like string is generated.
  /// If [timestamp] is not provided, the current time is used.
  /// If [priority] is not provided, defaults to [EventPriority.normal].
  TrackedEvent(
    this.name, {
    Map<String, String>? properties,
    DateTime? timestamp,
    String? id,
    this.priority = EventPriority.normal,
    this.sessionId,
  })  : properties = properties ?? const {},
        timestamp = timestamp ?? DateTime.now(),
        id = id ?? _generateId();

  static final _random = Random();

  static String _generateId() {
    const chars = '0123456789abcdef';
    String segment(int length) =>
        List.generate(length, (_) => chars[_random.nextInt(chars.length)])
            .join();
    return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
  }

  @override
  String toString() =>
      'TrackedEvent($name, properties: $properties, timestamp: $timestamp, id: $id, priority: $priority, sessionId: $sessionId)';
}
