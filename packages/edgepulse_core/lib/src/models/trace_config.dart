import 'package:meta/meta.dart';

/// Configuration options for an EdgePulse inference tracing session.
@immutable
class TraceConfig {
  /// Whether to capture memory snapshots (RSS, heap, native).
  final bool collectMemory;

  /// Whether to capture thermal state.
  final bool collectThermal;

  /// Whether to capture battery drain.
  final bool collectBattery;

  /// Whether to capture CPU usage percentage.
  final bool collectCpu;

  /// Whether to record per-layer timings if supported by runtime.
  final bool collectLayerTimings;

  /// Sampling interval during long-running inference runs.
  final Duration samplingInterval;

  /// Number of unmeasured warmup runs before tracing begins.
  final int warmupRuns;

  /// Number of measured inference runs to execute.
  final int measuredRuns;

  /// Creates a [TraceConfig] with default settings.
  const TraceConfig({
    this.collectMemory = true,
    this.collectThermal = true,
    this.collectBattery = true,
    this.collectCpu = true,
    this.collectLayerTimings = false,
    this.samplingInterval = const Duration(milliseconds: 100),
    this.warmupRuns = 3,
    this.measuredRuns = 10,
  });

  /// Factory constructor to create a [TraceConfig] from JSON data.
  factory TraceConfig.fromJson(Map<String, dynamic> json) {
    return TraceConfig(
      collectMemory: json['collect_memory'] as bool? ?? true,
      collectThermal: json['collect_thermal'] as bool? ?? true,
      collectBattery: json['collect_battery'] as bool? ?? true,
      collectCpu: json['collect_cpu'] as bool? ?? true,
      collectLayerTimings: json['collect_layer_timings'] as bool? ?? false,
      samplingInterval: Duration(
        milliseconds: json['sampling_interval_ms'] as int? ?? 100,
      ),
      warmupRuns: json['warmup_runs'] as int? ?? 3,
      measuredRuns: json['measured_runs'] as int? ?? 10,
    );
  }

  /// Converts the config into a JSON map representation.
  Map<String, dynamic> toJson() {
    return {
      'collect_memory': collectMemory,
      'collect_thermal': collectThermal,
      'collect_battery': collectBattery,
      'collect_cpu': collectCpu,
      'collect_layer_timings': collectLayerTimings,
      'sampling_interval_ms': samplingInterval.inMilliseconds,
      'warmup_runs': warmupRuns,
      'measured_runs': measuredRuns,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraceConfig &&
          runtimeType == other.runtimeType &&
          collectMemory == other.collectMemory &&
          collectThermal == other.collectThermal &&
          collectBattery == other.collectBattery &&
          collectCpu == other.collectCpu &&
          collectLayerTimings == other.collectLayerTimings &&
          samplingInterval == other.samplingInterval &&
          warmupRuns == other.warmupRuns &&
          measuredRuns == other.measuredRuns;

  @override
  int get hashCode => Object.hash(
        collectMemory,
        collectThermal,
        collectBattery,
        collectCpu,
        collectLayerTimings,
        samplingInterval,
        warmupRuns,
        measuredRuns,
      );

  @override
  String toString() =>
      'TraceConfig(collectMemory: $collectMemory, collectThermal: $collectThermal, collectBattery: $collectBattery, collectCpu: $collectCpu, collectLayerTimings: $collectLayerTimings, samplingInterval: $samplingInterval, warmupRuns: $warmupRuns, measuredRuns: $measuredRuns)';
}
