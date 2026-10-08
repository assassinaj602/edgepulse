---
layout: default
title: Quick Start
parent: Docs
nav_order: 2
permalink: /docs/quickstart/
---

# Quick Start

## In a Flutter app

```dart
import 'package:edgepulse/edgepulse.dart';

Future<void> main() async {
  final pulse = EdgePulse(
    collector: PlatformMetricCollector(),
    config: const TraceConfig(
      measuredRuns: 50,
      warmupRuns: 5,
      collectThermal: true,
      collectBattery: true,
      collectCpu: true,
    ),
  );

  await pulse.initialize();

  final traces = await pulse.traceMany(
    modelId: 'gemma-2b-q4',
    modelFormat: 'gguf',
    run: () => myModel.runInference(input),
  );

  print(pulse.exportMarkdown(traces));
  await pulse.dispose();
}
```

## From the CLI

```bash
# Trace a model 50 times
edgepulse trace --model model.tflite --runs 50 --output trace.json

# Compare two runs
edgepulse compare baseline.json stressed.json
```

## In tests (no device required)

```dart
final pulse = EdgePulse.mock();
await pulse.initialize();
final trace = await pulse.trace(
  modelId: 'test',
  modelFormat: 'mock',
  run: () async => Future.delayed(const Duration(milliseconds: 50)),
);
```
