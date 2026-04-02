# philiprehberger_event_tracker

[![Tests](https://github.com/philiprehberger/dart-event-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-event-tracker/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_event_tracker.svg)](https://pub.dev/packages/philiprehberger_event_tracker)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-event-tracker)](https://github.com/philiprehberger/dart-event-tracker/commits/main)

Analytics event tracking with filtering, buffering, and multi-sink export

## Requirements

- Dart >= 3.5

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_event_tracker: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_event_tracker/event_tracker.dart';

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
| `TrackedEvent(name, {properties, timestamp, id})` | Create a tracked event |
| `name` | Event name |
| `properties` | Key-value string map |
| `timestamp` | When the event occurred |
| `id` | Unique event identifier |

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
| `add(event)` | Add an event to the store |
| `all()` | Return all stored events |
| `eventsNamed(name)` | Return events with the given name |
| `eventsBetween(start, end)` | Return events in a date range |
| `search(query)` | Search events by name or property values |
| `summary()` | Return map of event name to count |
| `clear()` | Remove all events |
| `count` | Number of stored events |
| `export()` | Export all events as a formatted string |

### `EventTracker`

| Method / Property | Description |
|-------------------|-------------|
| `track(name, {properties})` | Track a new event |
| `addSink(sink)` | Add an event sink |
| `removeSink(sink)` | Remove an event sink |
| `addFilter(filter)` | Add a filter (all filters must pass) |
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
