---
layout: default
title: SATE AI
nav_order: 3
permalink: /sate-ai/
---

# SATE AI

**Fault injection framework for on-device AI models**

[![pub.dev](https://img.shields.io/pub/v/sate_ai?style=for-the-badge&logo=dart&color=0175C2)](https://pub.dev/packages/sate_ai)
[![GitHub](https://img.shields.io/badge/GitHub-assassinaj602%2Fsate__ai-blue?style=for-the-badge&logo=github)](https://github.com/assassinaj602/sate_ai)

---

## Overview

SATE AI simulates real-world fault conditions against on-device AI models so you can see how they degrade before shipping.

**Available injectors:**
- Memory pressure
- Thermal throttling
- Malformed input
- Quantization drift
- Latency injection
- Model swap
- Confidence threshold

---

## Quick Start

```bash
dart pub global activate sate_ai
sate_ai --model model.gguf --injectors memoryPressure,malformedInput
```

```dart
import 'package:sate_ai/sate_ai.dart';

final runner = StressRunner(model);
final report = await runner.stress(
  injectors: [
    MemoryPressureInjector(limitMb: 200),
    MalformedInputInjector(),
  ],
);

print(report.toMarkdown());
```

---

## Pairs With EdgePulse

SATE AI **injects faults**; EdgePulse **measures what changes**.

```dart
// Inject a fault
await SateAI.applyFault(MemoryPressureInjector(limitMb: 200));

// Measure the response
final trace = await pulse.trace(
  modelId: 'my-model',
  modelFormat: 'tflite',
  run: () => model.runInference(input),
);

print('Memory delta: ${trace.memoryDeltaMb} MB');
print('Latency delta: ${trace.totalDurationMs} ms');
```

A joint SATE AI + EdgePulse reliability study is planned for [v0.4.0](https://github.com/assassinaj602/edgepulse/milestones).

---

## Links

- **[GitHub Repository](https://github.com/assassinaj602/sate_ai)**
- **[pub.dev Package](https://pub.dev/packages/sate_ai)**
- **[Documentation](https://github.com/assassinaj602/sate_ai#readme)**
