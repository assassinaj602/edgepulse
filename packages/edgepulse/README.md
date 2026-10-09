# edgepulse

**Flutter plugin for EdgePulse: runtime observability for on-device AI.**

[![pub package](https://img.shields.io/pub/v/edgepulse.svg)](https://pub.dev/packages/edgepulse)

EdgePulse captures real-time device metrics (Memory RSS, thermal state, battery draw, and CPU usage) on Android and iOS via native platform channels during on-device AI inference execution.

---

## Features

- **Real Device Metrics**: Captures actual process memory (RSS), thermal state, battery current draw/level, and CPU utilization.
- **Android & iOS Support**: Kotlin native plugin (`Debug.getPss()`, `PowerManager`, `/proc/stat`) and iOS Swift native plugin (`mach_task_basic_info`, `ProcessInfo`, `host_statistics`).
- **Core Compatibility**: Seamlessly integrates with `edgepulse_core` models, `PulseRunner`, and exporters (JSON, Markdown, CSV).

---

## Installation

Add `edgepulse` to your `pubspec.yaml`:

```yaml
dependencies:
  edgepulse: ^0.2.0
```

---

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:edgepulse/edgepulse.dart';

Future<void> main() async {
  final pulse = EdgePulse(
    collector: PlatformMetricCollector(),
    config: const TraceConfig(
      measuredRuns: 5,
      warmupRuns: 1,
      collectThermal: true,
      collectBattery: true,
      collectCpu: true,
    ),
  );

  await pulse.initialize();

  final traces = await pulse.traceMany(
    modelId: 'mobilenet_v3',
    modelFormat: 'tflite',
    run: () async {
      // Execute your model inference here
      await Future<void>.delayed(const Duration(milliseconds: 120));
    },
  );

  await pulse.dispose();

  final markdownReport = pulse.exportMarkdown(traces);
  print(markdownReport);
}
```

---

## Documentation

For full documentation and core utilities, visit the [EdgePulse GitHub repository](https://github.com/assassinaj602/edgepulse).
