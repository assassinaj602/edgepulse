# Changelog

All notable changes to EdgePulse are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial monorepo structure with `edgepulse_core`, `edgepulse`, and `edgepulse_cli`
- Core data models: `InferenceTrace`, `MemorySnapshot`, `LayerTiming`, `TraceConfig`
- Abstract `MetricCollector` interface
- `MockMetricCollector` for testing without a physical device
- `PulseRunner` orchestration engine
- JSON, Markdown, and CSV exporters
- Standalone CLI (`edgepulse_cli`)
- Android native plugin (Kotlin) for real memory, thermal, and battery metrics
- iOS native plugin (Swift)
