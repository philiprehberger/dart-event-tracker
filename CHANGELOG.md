# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-11

### Added
- `TrackedEvent.copyWith()` for creating modified copies while preserving unchanged fields

### Fixed
- Barrel file structure now follows guide convention (primary barrel exports src, short alias re-exports primary)
- README Requirements section corrected from "Dart >= 3.5" to "Dart >= 3.6"
- Enricher example updated to use `copyWith` to prevent silent field loss
- PR template aligned with guide standard
- `lints` constraint normalized to `^5.0.0`

## [0.4.0] - 2026-04-02

### Added
- `EventStore` now supports optional `maxCapacity` with FIFO eviction
- `EventStore.onEvict` callback fires when events are evicted due to capacity limits
- `EventStore.isFull` getter indicates whether the store has reached capacity
- `EventStore.remaining` getter returns remaining capacity
- `EventStore.purgeOlderThan()` removes events older than a given duration

## [0.3.0] - 2026-04-02

### Added
- `EventPriority` enum with `low`, `normal`, `high`, `critical` levels
- `TrackedEvent.priority` field for ranking event importance
- `TrackedEvent.sessionId` field for session grouping
- `EventStore.byPriority()` to filter events by priority level
- `EventStore.bySession()` to filter events by session ID
- `EventTracker.onTrack()` lifecycle hook fired after each event
- `EventTracker.onFlush()` lifecycle hook fired after flush
- `EventTracker.startSession()` and `endSession()` for automatic session tagging

## [0.2.0] - 2026-04-01

### Added
- Event deduplication within a configurable time window via `deduplicate()`
- Event enrichers that transform events before sinking via `addEnricher()`
- Paginated event queries with `EventStore.query()` supporting predicate, limit, and offset
- `EventStore.distinctNames()` for retrieving sorted unique event names

## [0.1.0] - 2026-04-01

### Added
- Initial release
- TrackedEvent with name, properties, timestamp, and auto-generated ID
- EventSink abstraction with ConsoleSink and MemorySink implementations
- BufferedSink for batch event delivery with configurable batch size
- EventFilter with byName, bySample, and custom filter factories
- EventStore for in-memory querying, searching, and export
- EventTracker as the main coordinator with multi-sink and multi-filter support
