# edgepulse_core

Pure Dart core library for EdgePulse — providing data models, metric collectors, exporters, and the `PulseRunner` orchestration engine for on-device AI inference tracing.

Zero Flutter dependency — runs anywhere Dart runs.

## Features

- **Models**: `InferenceTrace`, `MemorySnapshot`, `LayerTiming`, `ThermalState`, `TraceConfig`, `TraceSummary`
- **Collectors**: `MetricCollector`, `MockMetricCollector`, `LatencyCollector`
- **Exporters**: `JsonExporter`, `MarkdownExporter`, `CsvExporter`
- **Runner**: `PulseRunner` with warmup, iteration measurement, and error handling
- **Facade**: `EdgePulse` entrypoint with `EdgePulse.mock()` for non-Flutter / CLI / testing usage

## Getting Started

Add `edgepulse_core` to your `pubspec.yaml`:

```yaml
dependencies:
  edgepulse_core: ^0.1.0
```

### Usage Example

```dart
import 'package:edgepulse_core/edgepulse_core.dart';

Future<void> main() async {
  final pulse = EdgePulse.mock();

  await pulse.initialize();

  final traces = await pulse.traceMany(
    modelId: 'example-model',
    modelFormat: 'mock',
    runs: 3,
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
  );

  print('Captured ${traces.length} traces');
  print(pulse.exportJson(traces));

  await pulse.dispose();
}
```

## License

MIT License. See [LICENSE](LICENSE) for details.
