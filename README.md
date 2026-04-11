# philiprehberger_event_tracker

[![Tests](https://github.com/philiprehberger/dart-event-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-event-tracker/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_event_tracker.svg)](https://pub.dev/packages/philiprehberger_event_tracker)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-event-tracker)](https://github.com/philiprehberger/dart-event-tracker/commits/main)

Analytics event tracking with filtering, buffering, and multi-sink export

## Requirements

- Dart >= 3.6

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_event_tracker: ^0.5.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_event_tracker/philiprehberger_event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());
await tracker.track('page_view', properties: {'page': '/home'});
```

### Buffered Delivery

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final memorySink = MemorySink();
final buffered = BufferedSink(memorySink, batchSize: 10);

final tracker = EventTracker();
tracker.addSink(buffered);

await tracker.track('click', properties: {'button': 'ok'});
await tracker.flush(); // Force flush pending events
```

### Filtering Events

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());

// Only track page_view and purchase events
tracker.addFilter(EventFilter.byName({'page_view', 'purchase'}));

// Sample 50% of events
tracker.addFilter(EventFilter.bySample(0.5));

// Custom filter
tracker.addFilter(EventFilter.custom((e) => e.properties.containsKey('userId')));
```

### Deduplication

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());

// Suppress duplicate events within a 1-second window
tracker.deduplicate(const Duration(seconds: 1));

await tracker.track('click', properties: {'button': 'ok'});
await tracker.track('click', properties: {'button': 'ok'}); // suppressed
```

### Enrichers

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());

// Add session ID to every event
tracker.addEnricher((event) => event.copyWith(
  properties: {...event.properties, 'session': 'abc-123'},
));

await tracker.track('page_view', properties: {'page': '/home'});
// Event will include both 'page' and 'session' properties
```

### Querying the Store

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
await tracker.track('page_view', properties: {'page': '/home'});
await tracker.track('click', properties: {'button': 'signup'});

final views = tracker.store.eventsNamed('page_view');
final summary = tracker.store.summary(); // {'page_view': 1, 'click': 1}
final results = tracker.store.search('signup');
final exported = tracker.store.export();
```

### Priority Levels

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final event = TrackedEvent(
  'error',
  priority: EventPriority.critical,
  properties: {'message': 'Out of memory'},
);

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());
await tracker.track('page_view'); // default normal priority

// Query by priority
final critical = tracker.store.byPriority(EventPriority.critical);
```

### Session Tracking

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());

// Start a session (auto-generates ID if not provided)
tracker.startSession(id: 'user-session-1');

await tracker.track('page_view', properties: {'page': '/home'});
await tracker.track('click', properties: {'button': 'signup'});

// All tracked events automatically include the session ID
final sessionEvents = tracker.store.bySession('user-session-1');
print('Session events: ${sessionEvents.length}');

tracker.endSession();
```

### Lifecycle Hooks

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();

// Fire after each event is tracked
tracker.onTrack((event) {
  print('Tracked: ${event.name}');
});

// Fire after flush completes
tracker.onFlush(() {
  print('Flush complete');
});

await tracker.track('page_view');
await tracker.flush();
```

### Memory Management

```dart
// Bounded store with max 10,000 events
final store = EventStore(
  maxCapacity: 10000,
  onEvict: (event) => print('Evicted: ${event.name}'),
);

// Check capacity
print(store.isFull);      // false
print(store.remaining);   // 9998

// Purge events older than 24 hours
final removed = store.purgeOlderThan(Duration(hours: 24));
```

### Paginated Queries

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final store = EventStore();
// ... add events ...

// Query with predicate, limit, and offset
final page = store.query(
  where: (e) => e.name == 'click',
  limit: 10,
  offset: 20,
);

// Get all distinct event names
final names = store.distinctNames(); // ['click', 'page_view', ...]
```

### Multiple Sinks

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

final tracker = EventTracker();
tracker.addSink(const ConsoleSink());
tracker.addSink(MemorySink());
tracker.addSink(BufferedSink(MemorySink(), batchSize: 50));

await tracker.track('event'); // Sent to all three sinks
```

## API

### `TrackedEvent`

| Method / Property | Description |
|-------------------|-------------|
| `TrackedEvent(name, {properties, timestamp, id, priority, sessionId})` | Create a tracked event |
| `copyWith({name, properties, timestamp, id, priority, sessionId})` | Create a copy with the given fields replaced |
| `name` | Event name |
| `properties` | Key-value string map |
| `timestamp` | When the event occurred |
| `id` | Unique event identifier |
| `priority` | Event priority level (default `EventPriority.normal`) |
| `sessionId` | Optional session identifier |

### `EventPriority`

| Value | Description |
|-------|-------------|
| `low` | Low priority event |
| `normal` | Normal priority event (default) |
| `high` | High priority event |
| `critical` | Critical priority event |

### `EventSink`

| Method | Description |
|--------|-------------|
| `send(events)` | Send a batch of events to the sink |

### `ConsoleSink`

| Method | Description |
|--------|-------------|
| `send(events)` | Print events to stdout |

### `MemorySink`

| Method / Property | Description |
|-------------------|-------------|
| `send(events)` | Store events in memory |
| `events` | List of all received events |

### `BufferedSink`

| Method / Property | Description |
|-------------------|-------------|
| `BufferedSink(inner, {batchSize})` | Create a buffered sink wrapping another sink |
| `send(events)` | Buffer events, auto-flush when batch size reached |
| `flush()` | Manually flush all pending events |
| `pending` | Number of buffered events |

### `EventFilter`

| Method | Description |
|--------|-------------|
| `EventFilter.byName(names)` | Pass events whose name is in the set |
| `EventFilter.bySample(rate)` | Pass events at the given sample rate (0.0-1.0) |
| `EventFilter.custom(predicate)` | Pass events matching a custom function |

### `EventStore`

| Method / Property | Description |
|-------------------|-------------|
| `EventStore({maxCapacity, onEvict})` | Create a bounded or unbounded event store |
| `EventStore.isFull` | Whether the store has reached capacity |
| `EventStore.remaining` | Remaining capacity (null if unbounded) |
| `EventStore.purgeOlderThan(duration)` | Remove events older than duration |
| `add(event)` | Add an event to the store |
| `all()` | Return all stored events |
| `eventsNamed(name)` | Return events with the given name |
| `eventsBetween(start, end)` | Return events in a date range |
| `search(query)` | Search events by name or property values |
| `summary()` | Return map of event name to count |
| `clear()` | Remove all events |
| `count` | Number of stored events |
| `query({where, limit, offset})` | Query events with optional predicate, limit, and offset |
| `distinctNames()` | Get all distinct event names, sorted |
| `byPriority(priority)` | Return events with the given priority level |
| `bySession(sessionId)` | Return events with the given session ID |
| `export()` | Export all events as a formatted string |

### `EventTracker`

| Method / Property | Description |
|-------------------|-------------|
| `track(name, {properties})` | Track a new event |
| `addSink(sink)` | Add an event sink |
| `removeSink(sink)` | Remove an event sink |
| `addFilter(filter)` | Add a filter (all filters must pass) |
| `deduplicate(window)` | Enable event deduplication within a time window |
| `addEnricher(enricher)` | Add an enricher that transforms events before sinking |
| `onTrack(callback)` | Register a callback fired after each event is tracked |
| `onFlush(callback)` | Register a callback fired after flush completes |
| `startSession({id})` | Start a session (auto-generates ID if not provided) |
| `endSession()` | End the current session |
| `currentSessionId` | The current session ID, or null |
| `flush()` | Force all buffered sinks to flush |
| `store` | Access the internal EventStore |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/dart-event-tracker)

🐛 [Report issues](https://github.com/philiprehberger/dart-event-tracker/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/dart-event-tracker/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
