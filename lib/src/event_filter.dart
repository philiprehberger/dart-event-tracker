import 'dart:math';

import 'tracked_event.dart';

/// Provides static methods for creating event filters.
///
/// Each filter is a function that takes a [TrackedEvent] and returns `true`
/// if the event should pass through, or `false` if it should be dropped.
class EventFilter {
  EventFilter._();

  /// Create a filter that only passes events whose name is in [names].
  static bool Function(TrackedEvent) byName(Set<String> names) {
    return (event) => names.contains(event.name);
  }

  /// Create a sampling filter that passes events at the given [rate].
  ///
  /// [rate] must be between 0.0 (drop all) and 1.0 (pass all).
  static bool Function(TrackedEvent) bySample(double rate, {Random? random}) {
    assert(rate >= 0.0 && rate <= 1.0, 'rate must be between 0.0 and 1.0');
    final rng = random ?? Random();
    return (_) => rng.nextDouble() < rate;
  }

  /// Create a custom filter from any predicate function.
  static bool Function(TrackedEvent) custom(bool Function(TrackedEvent) test) {
    return test;
  }
}
