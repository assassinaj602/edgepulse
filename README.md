# EdgePulse

**Runtime observability framework for on-device AI models**

[![edgepulse](https://img.shields.io/pub/v/edgepulse.svg?style=for-the-badge&logo=flutter&logoColor=white&label=edgepulse)](https://pub.dev/packages/edgepulse)
[![edgepulse_core](https://img.shields.io/pub/v/edgepulse_core.svg?style=for-the-badge&logo=dart&logoColor=white&label=edgepulse_core)](https://pub.dev/packages/edgepulse_core)
[![edgepulse_cli](https://img.shields.io/pub/v/edgepulse_cli.svg?style=for-the-badge&logo=dart&logoColor=white&label=edgepulse_cli)](https://pub.dev/packages/edgepulse_cli)
[![GitHub Release](https://img.shields.io/github/v/release/assassinaj602/edgepulse?style=for-the-badge&logo=github)](https://github.com/assassinaj602/edgepulse/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/assassinaj602/edgepulse/test.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI)](https://github.com/assassinaj602/edgepulse/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23248718.svg)](https://doi.org/10.5281/zenodo.23248718)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![GitHub Discussions](https://img.shields.io/github/discussions/assassinaj602/edgepulse?style=for-the-badge&logo=github&color=0E8A16)](https://github.com/assassinaj602/edgepulse/discussions)
[![GitHub Stars](https://img.shields.io/github/stars/assassinaj602/edgepulse?style=for-the-badge&logo=github&color=FBCA04)](https://github.com/assassinaj602/edgepulse/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/assassinaj602/edgepulse?style=for-the-badge&logo=github&color=00B4D8)](https://github.com/assassinaj602/edgepulse/forks)

🌐 **Website:** [assassinaj602.github.io/edgepulse](https://assassinaj602.github.io/edgepulse/)

---

## Overview

When an on-device AI model runs on a phone, you currently get one of two outcomes: 
it worked, or it crashed. You have no visibility into *what happened during inference* — 
how much memory was consumed, whether the CPU was thermally throttled, how battery 
draw correlated with model size, or which layers were the bottleneck.

EdgePulse fills that gap. It attaches to any on-device AI model and captures a 
structured `InferenceTrace` for every run — covering memory (RSS, heap, native), 
thermal state, battery microamp draw, CPU utilisation, per-layer timing, and output 
confidence. Traces are exported as JSON, Markdown, or CSV for analysis, CI/CD 
integration, or academic research.

EdgePulse pairs directly with [SATE AI](https://github.com/assassinaj602/sate_ai): 
SATE AI *injects faults*, EdgePulse *measures what changes*. Together they form a 
complete reliability testing pipeline for on-device AI.

---

## Research

EdgePulse is the tooling behind a real-device empirical study published on Zenodo.

📄 **Paper:** *EdgePulse: A Runtime Observability Framework for Quantized Large Language Models on Consumer Edge Devices*

**DOI:** [10.5281/zenodo.23248718](https://doi.org/10.5281/zenodo.23248718)

**Key finding:** Sustained TinyLlama 1.1B inference for 15 minutes on a Tecno CH7n (MediaTek Helio G35, Android 12) produced a +16.5% latency regression while `PowerManager.currentThermalStatus` reported `nominal` throughout. Standard Android thermal APIs miss real hardware throttling on budget ARM SoCs.

**Dataset:** [real_device_telemetry_90_traces.csv](research/experiment/real_device_telemetry_90_traces.csv)

### Citation

```bibtex
@software{ullah2026edgepulse,
  author    = {Muhammad Assad Ullah},
  title     = {EdgePulse: A Runtime Observability Framework for Quantized Large Language Models on Consumer Edge Devices},
  year      = {2026},
  publisher = {Zenodo},
  version   = {1.0.0},
  doi       = {10.5281/zenodo.23248718},
  url       = {https://doi.org/10.5281/zenodo.23248718}
}
```

---

## Platform Support

| Platform        | Language   | Package          | Status                                   |
|-----------------|------------|------------------|------------------------------------------|
| Flutter         | Dart       | `edgepulse`      | ✅ v0.2.0 on pub.dev                     |
| CLI / CI        | Dart       | `edgepulse_cli`  | ✅ v0.1.0 on pub.dev                    |
| Pure Dart Core  | Dart       | `edgepulse_core` | ✅ v0.1.0 on pub.dev                    |
| Android Native  | Kotlin     | Coming soon      | 🗺️ Planned v1.0                        |
| Web / Node.js   | TypeScript | Coming soon      | 🗺️ Planned v1.0                        |
| iOS Native      | Swift      | SPM coming soon  | 🔭 Future                               |

---

## Installation

```yaml
dependencies:
  edgepulse: ^0.2.0
```

For CI/CD without Flutter:

```bash
dart pub global activate edgepulse_cli
```

---

## Quick Start

```dart
import 'package:edgepulse/edgepulse.dart';

Future<void> main() async {
  final pulse = EdgePulse(
    collector: PlatformMetricCollector(),
  );

  await pulse.initialize();

  final trace = await pulse.trace(
    modelId: 'gemma-2b-q4',
    run: () => myModel.runInference(myInput),
  );

  print(trace.toMarkdown());
  await pulse.dispose();
}
```

**CLI:**

```bash
edgepulse trace --model model.tflite --runs 50 --output trace.json
edgepulse compare baseline.json stressed.json
```

---

## Architecture

```
edgepulse/
├── packages/
│   ├── edgepulse_core/      ← Pure Dart. FaultInjector, PulseRunner, exporters.
│   ├── edgepulse/           ← Flutter plugin. Native Android + iOS metric collectors.
│   └── edgepulse_cli/       ← Standalone CLI binary.
└── research/
    ├── experiment/          ← Empirical study scripts.
    └── paper/               ← Research paper source.
```

The `MetricCollector` interface is the central plugin point. Implement it to add 
new metric sources — hardware counters, cloud telemetry, custom sensors.

---

## What a Trace Looks Like

```json
{
  "trace_id": "ep_1a2b3c",
  "model_id": "gemma-2b-q4",
  "model_format": "gguf",
  "device_model": "Pixel 8",
  "os_version": "Android 14",
  "timestamp": "2026-10-03T10:22:31.000Z",
  "total_duration_ms": 847,
  "memory": {
    "start_rss_mb": 312.4,
    "peak_rss_mb": 489.1,
    "end_rss_mb": 318.2
  },
  "thermal_state": "nominal",
  "battery_drain_mah": 0.023,
  "cpu_usage_percent": 87.3,
  "output_confidence": 0.91,
  "layer_timings": [
    { "name": "embedding", "type": "embedding", "duration_ms": 12 },
    { "name": "attention_0", "type": "attention", "duration_ms": 94 }
  ]
}
```

---

## Integrates with SATE AI

```dart
// SATE AI injects a fault, EdgePulse measures the impact
await SateAI.applyFault(MemoryPressureInjector(limitMb: 200));

final trace = await pulse.trace(
  modelId: 'my-model',
  run: () => model.runInference(input),
);

print('Memory delta: ${trace.memoryDeltaMb} MB');
print('Latency delta: ${trace.totalDurationMs} ms');
```

---

## Documentation

- [API Reference](https://pub.dev/documentation/edgepulse)
- [Contributing Guide](CONTRIBUTING.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)
- [Research Paper](research/paper/) *(coming soon)*

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup 
instructions, the contribution workflow, and how to add a new MetricCollector 
or language SDK.

Good first issues are labeled 
[`good first issue`](https://github.com/assassinaj602/edgepulse/issues?q=label%3A%22good+first+issue%22).

---

## 🌟 Contributors

EdgePulse is built by people who believe on-device AI deserves visibility.
Every contribution — code, docs, bug reports, or experiment traces — matters.

<a href="https://github.com/assassinaj602/edgepulse/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=assassinaj602/edgepulse" />
</a>

**Want to be here?** Start with a
[`good first issue`](https://github.com/assassinaj602/edgepulse/issues?q=label%3A%22good+first+issue%22)
or introduce yourself in
[Discussions](https://github.com/assassinaj602/edgepulse/discussions).

---

## License

MIT License. See [LICENSE](LICENSE).

---

## Related Projects

- [SATE AI](https://github.com/assassinaj602/sate_ai) — Fault injection framework 
  for on-device AI models in Flutter. EdgePulse is the observability companion to SATE AI.
