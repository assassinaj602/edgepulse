# Changelog

All notable changes to `edgepulse_core` are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0 — 2026-10-04

### Added

- `InferenceTrace` — top-level observability record with JSON/Markdown/CSV serialization
- `MemorySnapshot` — RSS, heap, and native memory in MB
- `LayerTiming` and `LayerType` — per-layer timing breakdown
- `ThermalState` — enum mapping to Android ThermalStatus and iOS NSProcessInfo
- `TraceConfig` — default, minimal(), and full() configurations
- `MetricCollector` — abstract plugin interface
- `MockMetricCollector` — configurable fake values with call counters
- `LatencyCollector` — Stopwatch wrapper
- `PulseRunner` — orchestration engine with warmup and measured runs
- `TraceSummary` — p50/p95/p99 latency percentiles
- `TraceExporter` — abstract exporter interface
- `JsonExporter`, `MarkdownExporter`, `CsvExporter`
- `EdgePulse` — main user-facing facade with `EdgePulse.mock()` factory
- Zero Flutter dependency — pure Dart, runs anywhere Dart runs
