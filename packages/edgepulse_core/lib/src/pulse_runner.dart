import 'dart:async';
import 'dart:math';

import 'collectors/metric_collector.dart';
import 'models/inference_trace.dart';
import 'models/layer_timing.dart';
import 'models/memory_snapshot.dart';
import 'models/thermal_state.dart';
import 'models/trace_config.dart';
import 'trace_summary.dart';

/// Orchestrates timed, multi-run AI inference tracing sessions.
class PulseRunner {
  /// Metric collector implementation to sample hardware/OS metrics.
  final MetricCollector collector;

  /// Configuration for tracing.
  final TraceConfig config;

  /// Creates a [PulseRunner].
  PulseRunner({
    required this.collector,
    this.config = const TraceConfig(),
  });

  /// Trace a single inference execution [run].
  Future<InferenceTrace> trace({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    String? deviceModel,
    String? osVersion,
    double? outputConfidence,
    List<LayerTiming> layerTimings = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final traceId = _generateTraceId();
    final timestamp = DateTime.now();

    final MemorySnapshot memStart = config.collectMemory
        ? await collector.captureMemory()
        : MemorySnapshot(
            rssMb: 0,
            heapMb: 0,
            nativeMb: 0,
            timestamp: timestamp,
          );

    final stopwatch = Stopwatch()..start();

    dynamic runError;
    StackTrace? runStackTrace;

    try {
      await run();
    } catch (e, st) {
      runError = e;
      runStackTrace = st;
    } finally {
      stopwatch.stop();
    }

    final MemorySnapshot memEnd = config.collectMemory
        ? await collector.captureMemory()
        : MemorySnapshot(
            rssMb: 0,
            heapMb: 0,
            nativeMb: 0,
            timestamp: DateTime.now(),
          );

    final peakRss = max(memStart.rssMb, memEnd.rssMb);
    final MemorySnapshot memPeak = MemorySnapshot(
      rssMb: peakRss,
      heapMb: max(memStart.heapMb, memEnd.heapMb),
      nativeMb: max(memStart.nativeMb, memEnd.nativeMb),
      timestamp: DateTime.now(),
    );

    final ThermalState thermal = config.collectThermal
        ? await collector.captureThermalState()
        : ThermalState.unknown;

    final double? battery = config.collectBattery
        ? await collector.captureBatteryDrainMah()
        : null;

    final double? cpu =
        config.collectCpu ? await collector.captureCpuUsagePercent() : null;

    final traceMetadata = Map<String, dynamic>.from(metadata);
    if (runError != null) {
      traceMetadata['error'] = runError.toString();
      if (runStackTrace != null) {
        traceMetadata['stack_trace'] = runStackTrace.toString();
      }
    }

    return InferenceTrace(
      traceId: traceId,
      modelId: modelId,
      modelFormat: modelFormat,
      deviceModel: deviceModel,
      osVersion: osVersion,
      timestamp: timestamp,
      totalDuration: stopwatch.elapsed,
      memoryStart: memStart,
      memoryPeak: memPeak,
      memoryEnd: memEnd,
      thermalState: thermal,
      batteryDrainMah: battery,
      cpuUsagePercent: cpu,
      layerTimings: layerTimings,
      outputConfidence: outputConfidence,
      metadata: traceMetadata,
    );
  }

  /// Trace multiple inference runs and return all resulting [InferenceTrace] records.
  Future<List<InferenceTrace>> traceMany({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    int? runs,
    String? deviceModel,
    String? osVersion,
    double? outputConfidence,
    Map<String, dynamic> metadata = const {},
  }) async {
    await collector.initialize();

    final int targetRuns = runs ?? config.measuredRuns;
    final int warmup = config.warmupRuns;

    // Warmup runs (not recorded)
    for (int i = 0; i < warmup; i++) {
      try {
        await run();
      } catch (_) {}
    }

    final List<InferenceTrace> results = [];

    for (int i = 0; i < targetRuns; i++) {
      final traceResult = await trace(
        modelId: modelId,
        modelFormat: modelFormat,
        run: run,
        deviceModel: deviceModel,
        osVersion: osVersion,
        outputConfidence: outputConfidence,
        metadata: metadata,
      );
      results.add(traceResult);
    }

    await collector.dispose();

    return results;
  }

  /// Trace multiple inference runs and return an aggregated [TraceSummary].
  Future<TraceSummary> traceSummary({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    int? runs,
    String? deviceModel,
    String? osVersion,
    double? outputConfidence,
    Map<String, dynamic> metadata = const {},
  }) async {
    final traces = await traceMany(
      modelId: modelId,
      modelFormat: modelFormat,
      run: run,
      runs: runs,
      deviceModel: deviceModel,
      osVersion: osVersion,
      outputConfidence: outputConfidence,
      metadata: metadata,
    );

    return TraceSummary.fromTraces(
      modelId: modelId,
      traces: traces,
    );
  }

  static String _generateTraceId() {
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'ep_$rand';
  }
}
