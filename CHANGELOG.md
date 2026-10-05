# Changelog

All notable changes to EdgePulse are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] — v0.2.0

### Added
- Android Kotlin native plugin (EdgePulsePlugin.kt)
  - captureMemory: Debug.getPss() for accurate PSS
  - captureThermal: PowerManager.currentThermalStatus (API 29+)
  - captureBattery: BatteryManager.CURRENT_NOW in milliamps
  - captureCpu: /proc/stat utilisation ratio
- iOS Swift native plugin (EdgePulsePlugin.swift)
  - captureMemory: mach_task_basic_info resident_size
  - captureThermal: ProcessInfo.thermalState (iOS 11+)
  - captureBattery: UIDevice.batteryLevel (level fraction 0.0–1.0)
  - captureCpu: host_statistics HOST_CPU_LOAD_INFO
- PlatformMetricCollector: Dart bridge to native MethodChannel
- edgepulse Flutter plugin package (re-exports edgepulse_core)
- Example Flutter app demonstrating PlatformMetricCollector on device
- 11 Flutter unit tests with mock MethodChannel
- docs/ios-battery-note.md documenting iOS vs Android battery difference

### Fixed
- KGP deprecation warning in Android build.gradle

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
