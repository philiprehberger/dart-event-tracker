import 'event_sink.dart';
import 'tracked_event.dart';

/// A sink that buffers events and flushes them in batches to a wrapped sink.
class BufferedSink implements EventSink {
  /// The underlying sink to flush events to.
  final EventSink _inner;

  /// The number of events to buffer before automatically flushing.
  final int batchSize;

  final List<TrackedEvent> _buffer = [];

  /// Create a buffered sink wrapping [inner].
  ///
  /// Events are accumulated until [batchSize] is reached, then flushed
  /// automatically. Call [flush] to force a flush at any time.
  BufferedSink(this._inner, {this.batchSize = 10});

  /// The number of events currently buffered and not yet flushed.
  int get pending => _buffer.length;

  @override
  Future<void> send(List<TrackedEvent> events) async {
    _buffer.addAll(events);
    while (_buffer.length >= batchSize) {
      final batch = _buffer.sublist(0, batchSize);
      _buffer.removeRange(0, batchSize);
      await _inner.send(batch);
    }
  }

  /// Flush all buffered events to the underlying sink, even if
  /// [batchSize] has not been reached.
  Future<void> flush() async {
    if (_buffer.isNotEmpty) {
      final batch = List<TrackedEvent>.from(_buffer);
      _buffer.clear();
      await _inner.send(batch);
    }
  }
}
