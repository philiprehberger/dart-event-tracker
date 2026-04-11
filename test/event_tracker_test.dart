import 'dart:math';

import 'package:philiprehberger_event_tracker/event_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('TrackedEvent', () {
    test('creates event with name', () {
      final event = TrackedEvent('page_view');
      expect(event.name, 'page_view');
    });

    test('creates event with properties', () {
      final event =
          TrackedEvent('click', properties: {'button': 'submit'});
      expect(event.properties, {'button': 'submit'});
    });

    test('auto-generates an id', () {
      final event = TrackedEvent('test');
      expect(event.id, isNotEmpty);
      expect(event.id.contains('-'), isTrue);
    });

    test('uses provided id when given', () {
      final event = TrackedEvent('test', id: 'custom-id');
      expect(event.id, 'custom-id');
    });

    test('uses provided timestamp when given', () {
      final ts = DateTime(2026, 1, 1);
      final event = TrackedEvent('test', timestamp: ts);
      expect(event.timestamp, ts);
    });

    test('defaults to empty properties', () {
      final event = TrackedEvent('test');
      expect(event.properties, isEmpty);
    });

    test('toString includes name', () {
      final event = TrackedEvent('click');
      expect(event.toString(), contains('click'));
    });

    test('defaults to normal priority', () {
      final event = TrackedEvent('test');
      expect(event.priority, EventPriority.normal);
    });

    test('accepts custom priority', () {
      final event = TrackedEvent('test', priority: EventPriority.critical);
      expect(event.priority, EventPriority.critical);
    });

    test('defaults to null sessionId', () {
      final event = TrackedEvent('test');
      expect(event.sessionId, isNull);
    });

    test('accepts custom sessionId', () {
      final event = TrackedEvent('test', sessionId: 'sess-1');
      expect(event.sessionId, 'sess-1');
    });

    test('copyWith preserves all fields when no overrides given', () {
      final ts = DateTime(2026, 3, 15);
      final event = TrackedEvent(
        'click',
        properties: {'button': 'ok'},
        timestamp: ts,
        id: 'my-id',
        priority: EventPriority.high,
        sessionId: 'sess-1',
      );
      final copy = event.copyWith();
      expect(copy.name, 'click');
      expect(copy.properties, {'button': 'ok'});
      expect(copy.timestamp, ts);
      expect(copy.id, 'my-id');
      expect(copy.priority, EventPriority.high);
      expect(copy.sessionId, 'sess-1');
    });

    test('copyWith overrides individual fields', () {
      final event = TrackedEvent(
        'click',
        properties: {'a': '1'},
        priority: EventPriority.low,
        sessionId: 'old',
      );
      final copy = event.copyWith(
        name: 'tap',
        properties: {'b': '2'},
        priority: EventPriority.critical,
        sessionId: 'new',
      );
      expect(copy.name, 'tap');
      expect(copy.properties, {'b': '2'});
      expect(copy.priority, EventPriority.critical);
      expect(copy.sessionId, 'new');
      // Original fields preserved
      expect(copy.id, event.id);
      expect(copy.timestamp, event.timestamp);
    });
  });

  group('EventStore', () {
    late EventStore store;

    setUp(() {
      store = EventStore();
    });

    test('starts empty', () {
      expect(store.count, 0);
      expect(store.all(), isEmpty);
    });

    test('add increases count', () {
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      expect(store.count, 2);
    });

    test('all returns all events', () {
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      final events = store.all();
      expect(events.length, 2);
      expect(events[0].name, 'a');
      expect(events[1].name, 'b');
    });

    test('eventsNamed filters by name', () {
      store.add(TrackedEvent('page_view'));
      store.add(TrackedEvent('click'));
      store.add(TrackedEvent('page_view'));
      expect(store.eventsNamed('page_view').length, 2);
      expect(store.eventsNamed('click').length, 1);
      expect(store.eventsNamed('missing').length, 0);
    });

    test('eventsBetween filters by date range', () {
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);
      final t3 = DateTime(2026, 1, 3);
      store.add(TrackedEvent('a', timestamp: t1));
      store.add(TrackedEvent('b', timestamp: t2));
      store.add(TrackedEvent('c', timestamp: t3));
      final result = store.eventsBetween(t1, t2);
      expect(result.length, 2);
      expect(result[0].name, 'a');
      expect(result[1].name, 'b');
    });

    test('search matches event name', () {
      store.add(TrackedEvent('page_view'));
      store.add(TrackedEvent('click'));
      expect(store.search('page').length, 1);
      expect(store.search('page')[0].name, 'page_view');
    });

    test('search matches property values', () {
      store.add(
          TrackedEvent('click', properties: {'button': 'submit_form'}));
      store.add(TrackedEvent('click', properties: {'button': 'cancel'}));
      expect(store.search('submit').length, 1);
    });

    test('search is case-insensitive', () {
      store.add(TrackedEvent('PageView'));
      expect(store.search('pageview').length, 1);
    });

    test('summary returns name counts', () {
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      store.add(TrackedEvent('a'));
      expect(store.summary(), {'a': 2, 'b': 1});
    });

    test('clear removes all events', () {
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      store.clear();
      expect(store.count, 0);
      expect(store.all(), isEmpty);
    });

    test('export returns formatted string', () {
      final ts = DateTime(2026, 1, 1);
      store.add(TrackedEvent('click', timestamp: ts, properties: {'k': 'v'}));
      final output = store.export();
      expect(output, contains('[click]'));
      expect(output, contains('{k: v}'));
    });

    test('byPriority filters by priority level', () {
      store.add(TrackedEvent('a', priority: EventPriority.low));
      store.add(TrackedEvent('b', priority: EventPriority.high));
      store.add(TrackedEvent('c', priority: EventPriority.high));
      store.add(TrackedEvent('d', priority: EventPriority.normal));
      expect(store.byPriority(EventPriority.high).length, 2);
      expect(store.byPriority(EventPriority.low).length, 1);
      expect(store.byPriority(EventPriority.critical).length, 0);
    });

    test('bySession filters by session ID', () {
      store.add(TrackedEvent('a', sessionId: 'sess-1'));
      store.add(TrackedEvent('b', sessionId: 'sess-2'));
      store.add(TrackedEvent('c', sessionId: 'sess-1'));
      store.add(TrackedEvent('d'));
      expect(store.bySession('sess-1').length, 2);
      expect(store.bySession('sess-2').length, 1);
      expect(store.bySession('sess-3').length, 0);
    });
  });

  group('MemorySink', () {
    test('captures sent events', () async {
      final sink = MemorySink();
      final events = [TrackedEvent('a'), TrackedEvent('b')];
      await sink.send(events);
      expect(sink.events.length, 2);
      expect(sink.events[0].name, 'a');
    });

    test('accumulates across multiple sends', () async {
      final sink = MemorySink();
      await sink.send([TrackedEvent('a')]);
      await sink.send([TrackedEvent('b')]);
      expect(sink.events.length, 2);
    });
  });

  group('BufferedSink', () {
    test('does not flush before batch size reached', () async {
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 3);
      await buffered.send([TrackedEvent('a'), TrackedEvent('b')]);
      expect(inner.events.length, 0);
      expect(buffered.pending, 2);
    });

    test('flushes automatically when batch size reached', () async {
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 2);
      await buffered.send([TrackedEvent('a'), TrackedEvent('b')]);
      expect(inner.events.length, 2);
      expect(buffered.pending, 0);
    });

    test('manual flush sends remaining events', () async {
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 10);
      await buffered.send([TrackedEvent('a')]);
      expect(inner.events.length, 0);
      await buffered.flush();
      expect(inner.events.length, 1);
      expect(buffered.pending, 0);
    });

    test('flush with empty buffer is a no-op', () async {
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 10);
      await buffered.flush();
      expect(inner.events.length, 0);
    });

    test('handles events exceeding batch size', () async {
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 2);
      await buffered
          .send([TrackedEvent('a'), TrackedEvent('b'), TrackedEvent('c')]);
      expect(inner.events.length, 2);
      expect(buffered.pending, 1);
    });
  });

  group('EventFilter', () {
    test('byName passes matching events', () {
      final filter = EventFilter.byName({'click', 'tap'});
      expect(filter(TrackedEvent('click')), isTrue);
      expect(filter(TrackedEvent('tap')), isTrue);
      expect(filter(TrackedEvent('scroll')), isFalse);
    });

    test('bySample with rate 1.0 passes all', () {
      final filter = EventFilter.bySample(1.0);
      for (var i = 0; i < 20; i++) {
        expect(filter(TrackedEvent('test')), isTrue);
      }
    });

    test('bySample with rate 0.0 drops all', () {
      final filter =
          EventFilter.bySample(0.0, random: Random(42));
      for (var i = 0; i < 20; i++) {
        expect(filter(TrackedEvent('test')), isFalse);
      }
    });

    test('custom filter uses provided predicate', () {
      final filter = EventFilter.custom(
          (e) => e.properties.containsKey('important'));
      expect(
          filter(TrackedEvent('a', properties: {'important': 'yes'})), isTrue);
      expect(filter(TrackedEvent('a')), isFalse);
    });
  });

  group('EventTracker', () {
    test('track stores events in store', () async {
      final tracker = EventTracker();
      await tracker.track('page_view');
      expect(tracker.store.count, 1);
      expect(tracker.store.all()[0].name, 'page_view');
    });

    test('track sends events to sinks', () async {
      final tracker = EventTracker();
      final sink = MemorySink();
      tracker.addSink(sink);
      await tracker.track('click', properties: {'button': 'ok'});
      expect(sink.events.length, 1);
      expect(sink.events[0].name, 'click');
      expect(sink.events[0].properties['button'], 'ok');
    });

    test('track sends to multiple sinks', () async {
      final tracker = EventTracker();
      final sink1 = MemorySink();
      final sink2 = MemorySink();
      tracker.addSink(sink1);
      tracker.addSink(sink2);
      await tracker.track('event');
      expect(sink1.events.length, 1);
      expect(sink2.events.length, 1);
    });

    test('removeSink stops sending to removed sink', () async {
      final tracker = EventTracker();
      final sink = MemorySink();
      tracker.addSink(sink);
      await tracker.track('a');
      tracker.removeSink(sink);
      await tracker.track('b');
      expect(sink.events.length, 1);
    });

    test('filters drop non-matching events', () async {
      final tracker = EventTracker();
      final sink = MemorySink();
      tracker.addSink(sink);
      tracker.addFilter(EventFilter.byName({'allowed'}));
      await tracker.track('allowed');
      await tracker.track('blocked');
      expect(sink.events.length, 1);
      expect(tracker.store.count, 1);
    });

    test('multiple filters are ANDed together', () async {
      final tracker = EventTracker();
      final sink = MemorySink();
      tracker.addSink(sink);
      tracker.addFilter(EventFilter.byName({'click', 'tap'}));
      tracker.addFilter(
          EventFilter.custom((e) => e.properties.containsKey('target')));
      await tracker.track('click'); // passes name but no target
      await tracker.track('click', properties: {'target': 'btn'}); // passes both
      await tracker.track('scroll', properties: {'target': 'div'}); // fails name
      expect(sink.events.length, 1);
      expect(sink.events[0].properties['target'], 'btn');
    });

    test('flush forces buffered sinks to flush', () async {
      final tracker = EventTracker();
      final inner = MemorySink();
      final buffered = BufferedSink(inner, batchSize: 100);
      tracker.addSink(buffered);
      await tracker.track('a');
      await tracker.track('b');
      expect(inner.events.length, 0);
      await tracker.flush();
      expect(inner.events.length, 2);
    });

    test('onTrack callback fires after tracking', () async {
      final tracker = EventTracker();
      final tracked = <TrackedEvent>[];
      tracker.onTrack((event) => tracked.add(event));
      await tracker.track('a');
      await tracker.track('b');
      expect(tracked.length, 2);
      expect(tracked[0].name, 'a');
      expect(tracked[1].name, 'b');
    });

    test('onFlush callback fires after flush', () async {
      final tracker = EventTracker();
      var flushCount = 0;
      tracker.onFlush(() => flushCount++);
      await tracker.flush();
      await tracker.flush();
      expect(flushCount, 2);
    });

    test('startSession sets currentSessionId', () {
      final tracker = EventTracker();
      expect(tracker.currentSessionId, isNull);
      tracker.startSession(id: 'my-session');
      expect(tracker.currentSessionId, 'my-session');
    });

    test('startSession auto-generates id when not provided', () {
      final tracker = EventTracker();
      tracker.startSession();
      expect(tracker.currentSessionId, isNotNull);
      expect(tracker.currentSessionId!, startsWith('session-'));
    });

    test('endSession clears currentSessionId', () {
      final tracker = EventTracker();
      tracker.startSession(id: 'sess');
      tracker.endSession();
      expect(tracker.currentSessionId, isNull);
    });

    test('events automatically get sessionId during active session', () async {
      final tracker = EventTracker();
      await tracker.track('before');
      tracker.startSession(id: 'sess-42');
      await tracker.track('during');
      tracker.endSession();
      await tracker.track('after');

      final events = tracker.store.all();
      expect(events[0].sessionId, isNull);
      expect(events[1].sessionId, 'sess-42');
      expect(events[2].sessionId, isNull);
    });
  });

  group('Deduplication', () {
    test('suppresses duplicate events within window', () async {
      final sink = MemorySink();
      final tracker = EventTracker();
      tracker.addSink(sink);
      tracker.deduplicate(const Duration(seconds: 1));

      tracker.track('click', properties: {'button': 'ok'});
      tracker.track('click', properties: {'button': 'ok'});
      tracker.track('click', properties: {'button': 'ok'});

      await tracker.flush();
      expect(sink.events.length, equals(1));
    });

    test('allows different events', () async {
      final sink = MemorySink();
      final tracker = EventTracker();
      tracker.addSink(sink);
      tracker.deduplicate(const Duration(seconds: 1));

      tracker.track('click');
      tracker.track('view');

      await tracker.flush();
      expect(sink.events.length, equals(2));
    });
  });

  group('Enrichers', () {
    test('enricher adds properties to events', () async {
      final tracker = EventTracker();
      tracker.addEnricher((event) => TrackedEvent(
        event.name,
        properties: {...event.properties, 'session': 'abc'},
      ));
      await tracker.track('test');
      expect(tracker.store.all().first.properties['session'], equals('abc'));
    });

    test('multiple enrichers chain', () async {
      final tracker = EventTracker();
      tracker.addEnricher((e) => TrackedEvent(e.name, properties: {...e.properties, 'a': '1'}));
      tracker.addEnricher((e) => TrackedEvent(e.name, properties: {...e.properties, 'b': '2'}));
      await tracker.track('test');
      final props = tracker.store.all().first.properties;
      expect(props['a'], equals('1'));
      expect(props['b'], equals('2'));
    });
  });

  group('EventStore query', () {
    test('query with predicate', () {
      final store = EventStore();
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      store.add(TrackedEvent('a'));
      final results = store.query(where: (e) => e.name == 'a');
      expect(results.length, equals(2));
    });

    test('query with limit and offset', () {
      final store = EventStore();
      for (var i = 0; i < 10; i++) {
        store.add(TrackedEvent('e$i'));
      }
      final page = store.query(limit: 3, offset: 2);
      expect(page.length, equals(3));
      expect(page.first.name, equals('e2'));
    });

    test('distinctNames returns sorted unique names', () {
      final store = EventStore();
      store.add(TrackedEvent('b'));
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      expect(store.distinctNames(), equals(['a', 'b']));
    });
  });

  group('EventStore capacity', () {
    test('unbounded store has no capacity limit', () {
      final store = EventStore();
      expect(store.maxCapacity, isNull);
      expect(store.isFull, isFalse);
      expect(store.remaining, isNull);
    });

    test('rejects non-positive maxCapacity', () {
      expect(() => EventStore(maxCapacity: 0), throwsArgumentError);
      expect(() => EventStore(maxCapacity: -1), throwsArgumentError);
    });

    test('evicts oldest event when at capacity', () {
      final store = EventStore(maxCapacity: 3);
      store.add(TrackedEvent('a'));
      store.add(TrackedEvent('b'));
      store.add(TrackedEvent('c'));
      expect(store.isFull, isTrue);
      expect(store.remaining, 0);

      store.add(TrackedEvent('d'));
      expect(store.count, 3);
      expect(store.all().map((e) => e.name), ['b', 'c', 'd']);
    });

    test('onEvict callback fires with evicted event', () {
      final evicted = <String>[];
      final store = EventStore(
        maxCapacity: 2,
        onEvict: (event) => evicted.add(event.name),
      );
      store.add(TrackedEvent('first'));
      store.add(TrackedEvent('second'));
      store.add(TrackedEvent('third'));
      expect(evicted, ['first']);

      store.add(TrackedEvent('fourth'));
      expect(evicted, ['first', 'second']);
    });

    test('remaining decreases as events are added', () {
      final store = EventStore(maxCapacity: 5);
      expect(store.remaining, 5);
      store.add(TrackedEvent('a'));
      expect(store.remaining, 4);
      store.add(TrackedEvent('b'));
      expect(store.remaining, 3);
    });
  });

  group('EventStore purge', () {
    test('purgeOlderThan removes old events', () {
      final store = EventStore();
      final old = DateTime.now().subtract(const Duration(hours: 2));
      final recent = DateTime.now().subtract(const Duration(minutes: 5));

      store.add(TrackedEvent('old1', timestamp: old));
      store.add(TrackedEvent('old2', timestamp: old));
      store.add(TrackedEvent('recent', timestamp: recent));

      final removed = store.purgeOlderThan(const Duration(hours: 1));
      expect(removed, 2);
      expect(store.count, 1);
      expect(store.all().first.name, 'recent');
    });

    test('purgeOlderThan returns 0 when nothing to purge', () {
      final store = EventStore();
      store.add(TrackedEvent('recent'));
      final removed = store.purgeOlderThan(const Duration(hours: 1));
      expect(removed, 0);
      expect(store.count, 1);
    });
  });
}
