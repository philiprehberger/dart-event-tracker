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
  });
}
