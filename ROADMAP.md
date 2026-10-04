# EdgePulse Roadmap

## v0.1.0 — Core Foundation ✅ Released 2026-10-04
- [x] Monorepo structure (edgepulse_core, edgepulse, edgepulse_cli)
- [x] InferenceTrace data model
- [x] MetricCollector abstract interface
- [x] MockMetricCollector
- [x] PulseRunner with p50/p95/p99 TraceSummary
- [x] JSON, Markdown, CSV exporters
- [x] EdgePulse facade (EdgePulse.mock() factory)
- [x] LatencyCollector
- [x] CLI with trace and compare commands
- [x] 52 unit tests
- [x] GitHub Actions CI (test + analyze + format)
- [x] Published to pub.dev

## v0.2.0 — Native Platform Layer
- [ ] Android Kotlin plugin (memory, thermal, battery)
- [ ] iOS Swift plugin (memory, thermal)
- [ ] PlatformMetricCollector in Flutter package

## v0.3.0 — SATE AI Integration
- [ ] EdgePulse + SATE AI joint API
- [ ] FaultTrace: combines FaultResult + InferenceTrace
- [ ] Research experiment script

## v0.4.0 — Dashboard
- [ ] Web-based trace visualiser (memory curves, latency histograms)
- [ ] Compare two traces side by side

## v1.0.0 — Stable
- [ ] Full pub.dev 160/160 score
- [ ] arXiv paper published
- [ ] Kotlin Android SDK
