import 'models/inference_trace.dart';
import 'models/thermal_state.dart';

/// Aggregated summary of multiple inference trace runs.
class TraceSummary {
  /// All raw traces included in this summary.
  final List<InferenceTrace> traces;

  /// Model ID evaluated.
  final String modelId;

  /// Mean duration across all runs.
  final Duration meanDuration;

  /// Median (50th percentile) duration across runs.
  final Duration p50Duration;

  /// 95th percentile duration across runs.
  final Duration p95Duration;

  /// 99th percentile duration across runs.
  final Duration p99Duration;

  /// Mean memory delta (end - start) in MB across runs.
  final double meanMemoryDeltaMb;

  /// Maximum peak memory observed across all runs in MB.
  final double peakMemoryMb;

  /// Most severe thermal state observed across runs.
  final ThermalState worstThermalState;

  /// Creates a [TraceSummary] calculated from [traces].
  factory TraceSummary.fromTraces({
    required String modelId,
    required List<InferenceTrace> traces,
  }) {
    if (traces.isEmpty) {
      return TraceSummary._(
        traces: const [],
        modelId: modelId,
        meanDuration: Duration.zero,
        p50Duration: Duration.zero,
        p95Duration: Duration.zero,
        p99Duration: Duration.zero,
        meanMemoryDeltaMb: 0.0,
        peakMemoryMb: 0.0,
        worstThermalState: ThermalState.nominal,
      );
    }

    final sortedDurations =
        traces.map((t) => t.totalDuration.inMilliseconds).toList()..sort();
    final totalDurationMs = sortedDurations.reduce((a, b) => a + b);
    final meanDurationMs = totalDurationMs / traces.length;

    int percentile(double p) {
      final index = (p * (sortedDurations.length - 1)).round();
      return sortedDurations[index];
    }

    final double totalMemDelta =
        traces.map((t) => t.memoryDeltaMb).reduce((a, b) => a + b);
    final double maxPeakMem =
        traces.map((t) => t.peakRssMb).reduce((a, b) => a > b ? a : b);

    ThermalState worstThermal = ThermalState.nominal;
    for (final trace in traces) {
      if (trace.thermalState.index > worstThermal.index &&
          trace.thermalState != ThermalState.unknown) {
        worstThermal = trace.thermalState;
      }
    }

    return TraceSummary._(
      traces: traces,
      modelId: modelId,
      meanDuration: Duration(milliseconds: meanDurationMs.round()),
      p50Duration: Duration(milliseconds: percentile(0.50)),
      p95Duration: Duration(milliseconds: percentile(0.95)),
      p99Duration: Duration(milliseconds: percentile(0.99)),
      meanMemoryDeltaMb: totalMemDelta / traces.length,
      peakMemoryMb: maxPeakMem,
      worstThermalState: worstThermal,
    );
  }

  const TraceSummary._({
    required this.traces,
    required this.modelId,
    required this.meanDuration,
    required this.p50Duration,
    required this.p95Duration,
    required this.p99Duration,
    required this.meanMemoryDeltaMb,
    required this.peakMemoryMb,
    required this.worstThermalState,
  });

  /// Converts summary to JSON.
  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'total_runs': traces.length,
      'mean_duration_ms': meanDuration.inMilliseconds,
      'p50_duration_ms': p50Duration.inMilliseconds,
      'p95_duration_ms': p95Duration.inMilliseconds,
      'p99_duration_ms': p99Duration.inMilliseconds,
      'mean_memory_delta_mb': meanMemoryDeltaMb,
      'peak_memory_mb': peakMemoryMb,
      'worst_thermal_state': worstThermalState.name,
      'traces': traces.map((t) => t.toJson()).toList(),
    };
  }

  /// Converts summary to Markdown format.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Trace Summary Report for $modelId');
    buffer.writeln('Total Runs: ${traces.length}');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('| --- | --- |');
    buffer.writeln('| Mean Duration | ${meanDuration.inMilliseconds}ms |');
    buffer.writeln('| P50 Duration | ${p50Duration.inMilliseconds}ms |');
    buffer.writeln('| P95 Duration | ${p95Duration.inMilliseconds}ms |');
    buffer.writeln('| P99 Duration | ${p99Duration.inMilliseconds}ms |');
    buffer.writeln(
      '| Mean Memory Delta | ${meanMemoryDeltaMb >= 0 ? "+" : ""}${meanMemoryDeltaMb.toStringAsFixed(1)} MB |',
    );
    buffer.writeln('| Peak Memory | ${peakMemoryMb.toStringAsFixed(1)} MB |');
    buffer.writeln('| Worst Thermal State | ${worstThermalState.name} |');
    return buffer.toString();
  }
}
