import 'package:philiprehberger_event_tracker/event_tracker.dart';

Future<void> main() async {
  // Create a tracker with a console sink
  final tracker = EventTracker();
  tracker.addSink(const ConsoleSink());

  // Track simple events
  await tracker.track('page_view', properties: {'page': '/home'});
  await tracker.track('button_click', properties: {'button': 'signup'});

  // Use a buffered sink for batching
  final memorySink = MemorySink();
  final buffered = BufferedSink(memorySink, batchSize: 5);
  tracker.addSink(buffered);

  // Track more events
  for (var i = 0; i < 7; i++) {
    await tracker.track('loop_event', properties: {'index': '$i'});
  }

  // Flush remaining buffered events
  await tracker.flush();

  // Add a filter — only allow page_view events going forward
  tracker.addFilter(EventFilter.byName({'page_view'}));
  await tracker.track('page_view', properties: {'page': '/about'});
  await tracker.track('button_click'); // This is filtered out

  // Session tracking
  tracker.startSession(id: 'user-session-1');

  await tracker.track('page_view', properties: {'page': '/dashboard'});
  await tracker.track('click', properties: {'button': 'settings'});

  // Query events in the current session
  final sessionEvents = tracker.store.bySession('user-session-1');
  print('\nSession events: ${sessionEvents.length}');

  tracker.endSession();

  // Lifecycle hooks
  tracker.onTrack((event) {
    print('Tracked: ${event.name}');
  });

  tracker.onFlush(() {
    print('Flush complete');
  });

  await tracker.track('post_session_event');
  await tracker.flush();

  // Query the store
  print('\nTotal events: ${tracker.store.count}');
  print('Page views: ${tracker.store.eventsNamed('page_view').length}');
  print('Summary: ${tracker.store.summary()}');

  // Search
  final results = tracker.store.search('signup');
  print('Search "signup": ${results.length} result(s)');

  // Export
  print('\n--- Export ---');
  print(tracker.store.export());
}
