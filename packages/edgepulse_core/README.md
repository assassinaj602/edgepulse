# EdgePulse Core

Pure Dart core library for EdgePulse — runtime observability framework for on-device AI models.

## Features

- Structured `InferenceTrace` model (memory RSS/heap/native, thermal state, battery mAh, CPU %, layer timings)
- `MetricCollector` abstract interface and `MockMetricCollector` for zero-setup testing
- `PulseRunner` orchestration engine with warmup runs and latency percentiles (p50/p95/p99)
- `JsonExporter`, `MarkdownExporter`, and `CsvExporter` for trace formatting
- `EdgePulse` facade for high-level lifecycle management
