---
layout: default
title: Home
nav_order: 1
description: "EdgePulse — runtime observability for on-device AI"
permalink: /
---

# EdgePulse

**Runtime observability for on-device AI**

[![pub.dev](https://img.shields.io/pub/v/edgepulse?style=for-the-badge&logo=dart&color=0175C2)](https://pub.dev/packages/edgepulse)
[![CI](https://img.shields.io/github/actions/workflow/status/assassinaj602/edgepulse/test.yml?branch=main&style=for-the-badge&logo=githubactions)](https://github.com/assassinaj602/edgepulse/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## The Problem

On-device AI is shipped blind. When a model runs on a phone, you find out that it worked — or that it crashed. You don't see:

- How much memory it consumed
- Whether the CPU was thermally throttled
- How battery draw correlated with model size
- Which layers were the bottleneck

## The Solution

EdgePulse attaches to any on-device AI model and captures a structured `InferenceTrace` for every run — memory (RSS, heap, native), thermal state, battery microamp draw, CPU utilisation, per-layer timing, and output confidence.

---

## Quick Start

```bash
dart pub global activate edgepulse_cli
edgepulse trace --model model.tflite --runs 50 --output trace.json
edgepulse compare baseline.json stressed.json
```

```dart
import 'package:edgepulse/edgepulse.dart';

final pulse = EdgePulse(collector: PlatformMetricCollector());
await pulse.initialize();

final trace = await pulse.trace(
  modelId: 'gemma-2b-q4',
  modelFormat: 'gguf',
  run: () => myModel.runInference(input),
);

print(trace.toMarkdown());
await pulse.dispose();
```

---

## What You Can Measure

| Metric | Android Source | iOS Source |
|--------|----------------|------------|
| Memory (RSS) | `Debug.getPss()` | `mach_task_basic_info` |
| Thermal state | `PowerManager.currentThermalStatus()` | `ProcessInfo.thermalState` |
| Battery | `BatteryManager.CURRENT_NOW` | `UIDevice.batteryLevel` |
| CPU | `/proc/stat` | `host_statistics HOST_CPU_LOAD_INFO` |

---

## Packages

- **[`edgepulse`](https://pub.dev/packages/edgepulse)** — Flutter plugin with Android + iOS native metrics
- **[`edgepulse_core`](https://pub.dev/packages/edgepulse_core)** — Pure Dart core (no Flutter)
- **[`edgepulse_cli`](https://pub.dev/packages/edgepulse_cli)** — Standalone CLI (installable without Flutter)

---

## Research

EdgePulse is the tooling behind a real-device characterisation study. [Read the paper →](/research/)

**Key finding:** Sustained LLM inference on a budget Android SoC produces a **+16.5% latency regression** that `PowerManager.currentThermalStatus` reports as `nominal` — a blind spot in Android's standard thermal API.

---

## Companion Tool

EdgePulse pairs with **[SATE AI](https://github.com/assassinaj602/sate_ai)** — a fault-injection framework for on-device models. SATE AI injects faults; EdgePulse measures what changes.

[Learn more about SATE AI →](/sate-ai/)

---

## Contributing

See [CONTRIBUTING.md](https://github.com/assassinaj602/edgepulse/blob/main/CONTRIBUTING.md) or start with a [good first issue](https://github.com/assassinaj602/edgepulse/issues?q=label%3A%22good+first+issue%22).
