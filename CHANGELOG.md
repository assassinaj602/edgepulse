# Changelog

All notable changes to EdgePulse are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] — v0.2.0

### Planned
- Android Kotlin native plugin (`io.github.edgepulse/metrics` MethodChannel)
- iOS Swift native plugin
- `PlatformMetricCollector` in the `edgepulse` Flutter package
- Real memory RSS, thermal state, battery draw, and CPU usage on device

## [0.1.0] — 2026-10-04

### Added
- Monorepo structure with `edgepulse_core`, `edgepulse`, and `edgepulse_cli`
- Core data models: `InferenceTrace`, `MemorySnapshot`, `LayerTiming`, `ThermalState`, `TraceConfig`, `TraceSummary`
- Abstract `MetricCollector` interface and `MockMetricCollector` for testing
- `PulseRunner` orchestration engine with warmup and percentiles calculation
- `LatencyCollector` Stopwatch wrapper
- `EdgePulse` main facade with `EdgePulse.mock()` factory
- JSON, Markdown, and CSV trace exporters
- Standalone CLI (`edgepulse_cli`) with `trace` and `compare` commands
- 52 unit tests and GitHub Actions CI workflow
- Live packages published to pub.dev
