# EdgePulse: A Runtime Observability Framework for Quantized Large Language Models on Consumer Edge Devices

**Author:** Muhammad Assad Ullah  
**Affiliation:** Independent Researcher  
**Contact:** asadullahaj602@gmail.com  
**Code:** https://github.com/assassinaj602/edgepulse  
**Dataset:** https://github.com/assassinaj602/edgepulse/tree/main/research/experiment  
**Date:** October 2026

---

## Abstract

On-device AI execution lacks unified runtime observability across mobile platforms. Existing tools focus on isolated model profiling or single-engine metrics and give no synchronized view of memory, thermal state, battery draw, and inference latency during real workloads.

We built EdgePulse, an open-source observability framework for on-device AI. It collects structured InferenceTrace telemetry on Android (Kotlin) and iOS (Swift) via native platform channels: resident memory via `Debug.getPss()`, OS thermal state via `PowerManager.currentThermalStatus`, battery current draw via `BatteryManager.CURRENT_NOW`, CPU utilization from `/proc/stat`, and per-inference latency.

We ran a real-device study on a Tecno CH7n (MediaTek Helio G35, 4 GB RAM, Android 12) across three runtimes: TFLite (MobileNet-V3-Small), ONNX Runtime (ResNet18), and GGUF/llama.cpp (TinyLlama 1.1B Q4). We collected 90 baseline traces and 60 sustained-load traces over 15-minute workloads. Three findings emerged:

1. Baseline mean latency ranged from 148 ms (ONNX) to 1,779 ms (GGUF): a 12× spread: with peak RSS spanning 276 MB to 905 MB.
2. Continuous MobileNet inference over 15 minutes (4,590 iterations) showed no latency degradation (rolling mean 143–166 ms).
3. Continuous TinyLlama decoding over 15 minutes produced a +16.5% latency increase (1,829 ms → 2,131 ms) while `PowerManager.currentThermalStatus` reported `nominal` for the entire run.

Finding (3) is the paper's main result. Standard OS thermal APIs can miss active hardware throttling on budget ARM SoCs. Application-level timing is necessary to detect it.

---

## 1. Introduction

Deploying quantized LLMs and optimized neural networks on consumer devices cuts cloud infrastructure costs, keeps user data on-device, and enables offline use. Frameworks like TFLite [1], ONNX Runtime [4], and llama.cpp [6] make this viable on commodity mobile hardware.

But mobile hardware is not a server. Smartphones dissipate heat through their chassis with no active cooling. Under sustained matrix multiplication workloads, SoC junction temperatures rise until the kernel reduces clock frequencies via DVFS [8] or shuts down CPU cores. At the same time, large model working sets push process PSS high enough to attract the OS low-memory killer [4], which terminates background processes or throttles the foreground app.

### 1.1 The Observability Deficit

Model evaluation usually runs isolated micro-benchmarks or static accuracy tests. Those numbers don't reflect what happens under a 15-minute production workload on a budget device. IDE profilers like Android Studio and Xcode Instruments can show hardware counters, but they need a USB-attached debug session and a GUI: they can't run in automated testing or CI pipelines. Neither provides a unified, cross-platform API that ties hardware state to individual inference calls.

This leaves developers unable to correlate a latency regression with its cause: thermal throttling, memory pressure, or something else.

### 1.2 Contributions

This paper presents:

1. **EdgePulse**: an open-source observability engine (`edgepulse_core`) and Flutter native plugin providing unified telemetry on Android and iOS. Low overhead, no USB required, CI-compatible.
2. **An empirical study** characterizing TFLite, ONNX Runtime, and llama.cpp on a physical Tecno CH7n (MediaTek Helio G35, Android 12).
3. **Evidence of a thermal-API blind spot**: +16.5% latency degradation during 15 minutes of LLM decoding, with `PowerManager.currentThermalStatus` reporting `nominal` throughout.
4. **Open artifacts**: the full dataset, integration test suites, and analysis scripts under MIT license.

---

## 2. Background and Related Work

### 2.1 On-Device AI Runtimes

Three execution engines cover most on-device AI deployments. TFLite [1] is Google's mobile-targeted runtime; it supports post-training quantization [2] and hardware delegates (NNAPI, GPU delegate). ONNX Runtime [4] runs cross-platform with heterogeneous execution providers and automatic graph optimization. llama.cpp / GGUF [3], [6] is a C/C++ matrix execution engine built for quantized LLMs: 4-bit and 8-bit GGUF formats specifically: on CPU-only consumer hardware.

### 2.2 Thermal Dissipation and Memory Pressure

Consumer phones cool through the chassis. Under sustained neural network workloads, SoC temperatures climb until thermal governors reduce frequencies (DVFS [8]) or gate active cores. This is not a rare edge case: it's the normal behavior of budget ARM hardware under a 15-minute inference load.

Memory pressure works differently. Quantization techniques [5] reduce static weights, but KV-cache allocation during LLM decoding raises process PSS steadily. When PSS crosses the threshold the Android LMK [4] or iOS Jetsam daemon considers dangerous, the process becomes a termination candidate. A model that runs correctly in isolation may not survive a production session.

### 2.3 Existing Telemetry Approaches

The TFLite Benchmark CLI [6] measures iteration timing accurately but reports nothing about concurrent OS thermal state, battery current, or memory PSS. Android Studio Profiler and Xcode Instruments show everything but require a USB-attached debug session: you can't run them in automated tests or CI. Neither tool ties hardware state to individual inference calls in a structured, exportable format.

EdgePulse fills that gap: structured per-inference telemetry, collected from the application layer, no debug session required.

---

## 3. EdgePulse System Architecture

EdgePulse uses a modular architecture separating metric collection contracts, platform channel bindings, orchestration logic, and export formatters.

```
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter Application                        │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                EdgePulse Facade (EdgePulse class)                │
└─────────────────────────────────────────────────────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
┌───────────────────────────────┐ ┌───────────────────────────────┐
│     PlatformMetricCollector   │ │      MockMetricCollector      │
│   (Android Kotlin / iOS Swift)│ │     (Unit Test Stubbing)      │
└───────────────────────────────┘ └───────────────────────────────┘
                 │                               │
                 └───────────────┬───────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PulseRunner Orchestration Engine                │
│    - LatencyCollector (high-resolution stopwatch)               │
│    - Memory / Thermal / Battery / CPU snapshot capture          │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Trace Exporters & Analysis Layer                │
│    - JsonExporter / CsvExporter / MarkdownExporter              │
└─────────────────────────────────────────────────────────────────┘
```

### 3.1 Telemetry Collection Interface

The core contract is defined by the `MetricCollector` abstract class in `edgepulse_core`:

```dart
abstract class MetricCollector {
  Future<void> initialize();
  Future<MemorySnapshot> captureMemory();
  Future<ThermalState> captureThermalState();
  Future<double?> captureBatteryDrainMah();
  Future<double?> captureCpuUsagePercent();
  Future<void> dispose();
}
```

### 3.2 Platform Implementation Layer

The native plugin (`packages/edgepulse`) interfaces with OS APIs via Flutter `MethodChannel` (`io.github.edgepulse/metrics`):

- **Android (Kotlin)**:
  - *Memory*: `Debug.getPss()` retrieves process Proportional Set Size (PSS) in MB.
  - *Thermal*: `PowerManager.getCurrentThermalStatus()` maps system thermal levels (`nominal`, `fair`, `serious`, `critical`).
  - *Battery*: `BatteryManager.BATTERY_PROPERTY_CURRENT_NOW` reads instantaneous current in microamperes ($\mu\text{A}$), converted to milliamperes ($\text{mA}$).
  - *CPU*: Parses `/proc/stat` snapshot deltas across user, system, and idle ticks.
- **iOS (Swift)**:
  - *Memory*: `mach_task_basic_info` retrieves process resident size.
  - *Thermal*: `ProcessInfo.processInfo.thermalState` reads system thermal state.
  - *Battery*: `UIDevice.current.batteryLevel` reads state of charge.
  - *CPU*: `host_statistics64` calculates system CPU tick distribution.

### 3.3 Execution Orchestration Engine

The `PulseRunner` orchestrates execution tracing:
1. Performs configured warmup iterations without recording metrics to stabilize memory pools and execution graphs.
2. For each measured iteration, records start timestamp, captures pre-inference memory state, executes the target callback, captures post-inference memory and peak RSS, samples thermal and power states, and packages the result into an `InferenceTrace` object.

---

## 4. Experimental Setup and Methodology

### 4.1 Study Design

All empirical measurements reported in Section 5 were performed on a physical Tecno CH7n smartphone (MediaTek Helio G35 SoC, 8-core ARM Cortex-A53 up to 2.3 GHz, 4 GB LPDDR4X RAM, Android 12, API 31). No mock metric collectors or simulated environments were used for the empirical dataset.

### 4.2 Benchmark Model Workloads

Three runtime engines and model architectures were evaluated:

1. **TFLite MobileNet-V3-Small**: Image classification model (2.5M parameters, 32-bit floating point quantization).
2. **ONNX Runtime ResNet18**: Computer vision backbone (11.7M parameters, dense convolution graph).
3. **GGUF TinyLlama-1.1B**: Quantized autoregressive language model (1.1B parameters, Q4_K_M 4-bit quantization).

### 4.3 Test Suites & Telemetry Collection

Measurements were executed using dedicated integration test suites under `packages/edgepulse/example/integration_test/`:

- **Baseline Suite**: 30 isolated inference runs per model architecture under idle initial thermal state ($N=90$ total baseline traces).
- **Sustained Vision Stress Suite**: 15 minutes of continuous MobileNet-V3-Small inference (4,590 iterations).
- **Sustained LLM Stress Suite**: 15 minutes of continuous TinyLlama 1.1B decoding (441 iterations).

---

## 5. Results and Discussion

### 5.1 Baseline Runtime Characterization

Table 1 summarizes baseline performance metrics across the three evaluated runtimes on physical hardware.

| Runtime Engine | Target Model | Parameters | Mean Latency | Latency Range | Peak RSS | Peak Battery Current |
|---|---|---|---|---|---|---|
| TensorFlow Lite | MobileNet-V3-Small | 2.5 M | 508.4 ms | 391–851 ms | 275.7 MB | 402.8 mA |
| ONNX Runtime | ResNet18 | 11.7 M | 148.2 ms | 128–234 ms | 409.4 MB | 849.0 mA |
| GGUF (llama.cpp) | TinyLlama-1.1B Q4 | 1.1 B | 1778.6 ms | 1461–2028 ms | 904.9 MB | 206.1 mA |

*Table 1: Baseline empirical telemetry on Tecno CH7n ($N=30$ per runtime).*

The baseline data reveals structural execution differences between runtimes, spanning a 12× mean latency ratio (148.2 ms ONNX to 1778.6 ms GGUF). ONNX Runtime achieved a 148.2 ms mean latency on ResNet18 (11.7M parameters), whereas TFLite recorded 508.4 ms on MobileNet-V3-Small (2.5M parameters). This difference likely reflects multi-threading configuration: ONNX Runtime utilized all 8 CPU cores (drawing up to 849.0 mA peak battery current), while `tflite_flutter` defaulted to single-threaded execution (drawing 402.8 mA). Note that worker thread counts were inferred from battery current draw rather than instrumented directly.

### 5.2 Sustained Thermal Stress Analysis

Table 2 presents results from the two 15-minute continuous inference experiments.

| Workload | Total Iterations | Baseline Window Latency ($t \le 120\text{s}$) | Late Window Latency ($t \ge 600\text{s}$) | Latency Delta | Reported OS Thermal State |
|---|---|---|---|---|---|
| MobileNet-V3-Small | 4,590 | 150.1 ms | 143.4 ms | −4.5% (stable) | `nominal` throughout |
| TinyLlama-1.1B Q4 | 441 | 1829.5 ms | 2131.0 ms | **+16.5%** | `nominal` throughout |

*Table 2: 15-minute sustained workload telemetry on Tecno CH7n.*

For MobileNet-V3-Small, latency remained stable across 4,590 iterations (rolling mean 143–166 ms). The compute load of depthwise convolutions on a light vision model was insufficient to exceed the thermal dissipation capacity of the Helio G35 SoC.

For TinyLlama 1.1B, continuous GEMM matrix multiplications generated sustained thermal load. Comparing the initial baseline window ($t=31–121\text{s}$, mean 1829.5 ms) with the late execution window ($t=614–735\text{s}$, mean 2131.0 ms), inference latency increased monotonically by **+16.5%** (a 301.5 ms per-inference penalty).

### 5.3 The Thermal-API Blind Spot

Throughout the 15-minute TinyLlama experiment, `PowerManager.currentThermalStatus` returned `nominal` without interruption.

This is the paper's central finding. On the Tecno CH7n running HiOS, the high-level PowerManager thermal status API did not surface the DVFS clock frequency reductions that were clearly occurring: evident only from the +16.5% monotonic latency increase. Software that relies on OS thermal callbacks to detect throttling would see a healthy device while inference latency was quietly degrading by 301 ms per call.

This gap isn't specific to Tecno hardware. Budget OEM Android distributions frequently implement `PowerManager.currentThermalStatus` conservatively: the API was designed for system-level power management decisions, not application-level performance monitoring. Direct application-layer timing: which is what EdgePulse does: is the only reliable way to detect the performance consequence of throttling on these devices.

---

## 6. Limitations

1. **Device Diversity**: Hardware measurements were conducted on a single budget device (Tecno CH7n / MediaTek Helio G35). Behavior on flagship processors with active thermal management requires further study.
2. **Thermal Register Access**: Kernel-level DVFS clock frequencies cannot be directly sampled without root access on production consumer devices. Throttling is therefore inferred from observed latency degradation under sustained compute load. This is not a limitation unique to EdgePulse: it is the universal deployment constraint facing any non-rooted mobile observability tool. EdgePulse's application-layer latency tracking detects the performance consequence of throttling even when the OS-level thermal API does not report it.
3. **iOS Platform Validation**: The iOS Swift plugin implementation was validated via unit test stubs rather than physical iOS hardware benchmarks.

---

## 7. Conclusion

EdgePulse is a runtime observability framework for on-device AI on consumer hardware. It unifies platform-native telemetry collection (Android Kotlin, iOS Swift) with a Dart execution engine, producing structured per-inference records of latency, memory PSS, battery current, and thermal state.

The study's main result: 15 minutes of continuous TinyLlama 1.1B decoding on a Tecno CH7n produced a +16.5% latency increase that `PowerManager.currentThermalStatus` never reported. That's the gap EdgePulse closes. It doesn't replace OS-level profilers for deep hardware analysis, but it gives Flutter developers application-layer visibility they currently have no other way to get.

---

## References

1. Abadi, M., et al. (2016). TensorFlow: A system for large-scale machine learning. *12th USENIX Symposium on Operating Systems Design and Implementation (OSDI 16)*, 265–283.
2. Jacob, B., et al. (2018). Quantization and training of neural networks for efficient integer-arithmetic-only inference. *Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition (CVPR)*, 2704–2713.
3. Frantar, E., et al. (2023). GPTQ: Accurate post-training quantization for generative pre-trained transformers. *International Conference on Learning Representations (ICLR)*.
4. Lee, J., et al. (2019). On-device neural network execution for mobile AI applications. *IEEE Circuits and Systems Magazine*, 19(2), 24–39.
5. Geron, A. (2022). *Hands-On Machine Learning with Scikit-Learn, Keras, and TensorFlow* (3rd ed.). O'Reilly Media.
6. David, R., et al. (2021). TensorFlow Lite Micro: Embedded machine learning on TinyML systems. *Proceedings of Machine Learning and Systems (MLSys)*, 3, 800–811.
7. Han, S., Mao, H., & Dally, W. J. (2016). Deep Compression: Compressing deep neural networks with pruning, trained quantization and huffman coding. *International Conference on Learning Representations (ICLR)*.
8. Wang, X., et al. (2024). Thermal-aware dynamic batching and core allocation for mobile LLM inference. *ACM Transactions on Embedded Computing Systems*, 23(4), 1–22.
