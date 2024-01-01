# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-01

### Added
- Initial release
- TrackedEvent with name, properties, timestamp, and auto-generated ID
- EventSink abstraction with ConsoleSink and MemorySink implementations
- BufferedSink for batch event delivery with configurable batch size
- EventFilter with byName, bySample, and custom filter factories
- EventStore for in-memory querying, searching, and export
- EventTracker as the main coordinator with multi-sink and multi-filter support
