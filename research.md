---
layout: default
title: Research
nav_order: 2
permalink: /research/
---

# Research

## Paper

**EdgePulse: A Runtime Observability Framework for Quantized Large Language Models on Consumer Edge Devices**

*Muhammad Assad Ullah* — Independent Researcher

📄 **[Read the paper (PDF)](/assets/edgepulse-paper.pdf)**  
📦 **[Zenodo Publication](https://doi.org/10.5281/zenodo.23248718)**  
🐙 **[Code + dataset on GitHub](https://github.com/assassinaj602/edgepulse/tree/main/research)**

---

## Abstract

On-device AI deployment lacks unified runtime observability. Existing tools focus on accuracy or on profiling a single framework; none provide a cross-platform view of memory, thermal state, battery draw, and latency during inference on consumer edge hardware.

We present **EdgePulse**, an open-source framework for on-device AI runtime observability. EdgePulse captures structured `InferenceTrace` records on Android (Kotlin) and iOS (Swift) via native platform channels.

We report a real-device characterisation study on a **Tecno CH7n** (MediaTek Helio G35, Android 12, API 31) spanning three on-device AI runtimes:

| Runtime | Model | Mean Latency | Peak RSS |
|---------|-------|--------------|----------|
| TFLite | MobileNet-V3-Small | 508 ms | 276 MB |
| ONNX Runtime | ResNet18 | 148 ms | 409 MB |
| GGUF (llama.cpp) | TinyLlama-1.1B Q4 | 1779 ms | 905 MB |

**Key finding:** Sustained TinyLlama inference for 15 minutes produced a **+16.5% latency regression** (1829 ms → 2131 ms) — yet `PowerManager.currentThermalStatus` reported `nominal` throughout. This demonstrates that standard Android thermal APIs are insufficient for detecting real-world performance degradation on budget ARM SoCs.

---

## Dataset

The raw traces are available in the repository:

- **[90 baseline traces](https://github.com/assassinaj602/edgepulse/blob/main/research/experiment/real_device_telemetry_90_traces.csv)** — TFLite, ONNX, GGUF
- **[60 thermal stress traces](https://github.com/assassinaj602/edgepulse/blob/main/research/experiment/real_device_thermal_gguf_stress.csv)** — MobileNet + TinyLlama

---

## Reproduce the Study

```bash
git clone https://github.com/assassinaj602/edgepulse.git
cd edgepulse/research/experiment
dart pub get

# Run simulation study (fast)
dart run run_experiment.dart --fast

# Analyse
pip install -r requirements.txt
python3 analyse.py
```

For real-device reproduction, see the integration tests in `packages/edgepulse/example/integration_test/`.

---

## Cite This Work

```bibtex
@misc{ullah2026edgepulse,
  author = {Ullah, Muhammad Assad},
  title  = {EdgePulse: A Runtime Observability Framework for Quantized Large Language Models on Consumer Edge Devices},
  year   = {2026},
  doi    = {10.5281/zenodo.23248718},
  url    = {https://doi.org/10.5281/zenodo.23248718}
}
```
