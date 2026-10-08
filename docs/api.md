---
layout: default
title: API Reference
parent: Docs
nav_order: 3
permalink: /docs/api/
---

# API Reference

## `EdgePulse`

Main user-facing class.

```dart
EdgePulse({required MetricCollector collector, TraceConfig config});
factory EdgePulse.mock({TraceConfig config});
```

| Method | Returns | Description |
|--------|---------|-------------|
| `initialize()` | `Future<void>` | Prepares the collector |
| `trace(...)` | `Future<InferenceTrace>` | Traces one inference |
| `traceMany(...)` | `Future<List<InferenceTrace>>` | Traces N inferences |
| `summary(...)` | `Future<TraceSummary>` | Aggregated statistics |
| `dispose()` | `Future<void>` | Releases the collector |

## `MetricCollector`

Abstract interface for metric sources.

```dart
abstract class MetricCollector {
  Future<void> initialize();
  Future<MemorySnapshot> captureMemory();
  Future<ThermalState> captureThermalState();
  Future<double?> captureBatteryDrainMah();
  Future<double?> captureCpuUsagePercent();
  Future<void> dispose();
  bool get isInitialized;
}
```

Implementations:
- `MockMetricCollector` — configurable fake values (testing, CLI)
- `PlatformMetricCollector` — real device metrics (Android + iOS)

## `InferenceTrace`

The complete observability record for one inference run.

```dart
class InferenceTrace {
  final String traceId;
  final String modelId;
  final String modelFormat;
  final String? deviceModel;
  final String? osVersion;
  final DateTime timestamp;
  final Duration totalDuration;
  final MemorySnapshot? memoryStart;
  final MemorySnapshot? memoryPeak;
  final MemorySnapshot? memoryEnd;
  final ThermalState thermalState;
  final double? batteryDrainMah;
  final double? cpuUsagePercent;
  final List<LayerTiming> layerTimings;
  final double? outputConfidence;
  final Map<String, dynamic> metadata;

  double? get memoryDeltaMb;
  int get totalDurationMs;
  Map<String, dynamic> toJson();
  factory InferenceTrace.fromJson(Map<String, dynamic> json);
}
```

## `ThermalState`

```dart
enum ThermalState {
  nominal, fair, serious, critical, unknown;

  static ThermalState fromString(String value);
  bool get isDegraded;
  String get displayName;
}
```

## `TraceConfig`

```dart
const TraceConfig({
  bool collectMemory = true,
  bool collectThermal = true,
  bool collectBattery = true,
  bool collectCpu = true,
  bool collectLayerTimings = false,
  Duration samplingInterval = const Duration(milliseconds: 100),
  int warmupRuns = 3,
  int measuredRuns = 10,
});

const TraceConfig.minimal();
const TraceConfig.full();
```

Full API docs: [pub.dev/documentation/edgepulse](https://pub.dev/documentation/edgepulse)
