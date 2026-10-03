import 'package:meta/meta.dart';

import 'layer_timing.dart';
import 'memory_snapshot.dart';
import 'thermal_state.dart';

/// Top-level record of a single traced AI inference execution on an edge device.
@immutable
class InferenceTrace {
  /// Unique identifier for this trace (e.g. "ep_1a2b3c").
  final String traceId;

  /// Model identifier or filename (e.g. "gemma-2b-q4").
  final String modelId;

  /// Model format type (e.g. "tflite", "onnx", "gguf").
  final String modelFormat;

  /// Device hardware model name, if known (e.g. "Pixel 8").
  final String? deviceModel;

  /// Operating system version string, if known (e.g. "Android 14").
  final String? osVersion;

  /// Timestamp when inference started.
  final DateTime timestamp;

  /// Total duration of the inference execution.
  final Duration totalDuration;

  /// Memory snapshot at the start of inference.
  final MemorySnapshot memoryStart;

  /// Peak memory snapshot recorded during inference.
  final MemorySnapshot memoryPeak;

  /// Memory snapshot at the end of inference.
  final MemorySnapshot memoryEnd;

  /// Thermal state recorded during inference.
  final ThermalState thermalState;

  /// Battery energy consumed during inference in milliampere-hours (mAh).
  final double? batteryDrainMah;

  /// Average CPU usage percentage during inference (0.0 to 100.0).
  final double? cpuUsagePercent;

  /// Per-layer execution timing breakdown.
  final List<LayerTiming> layerTimings;

  /// Output confidence score or score metric, if supplied.
  final double? outputConfidence;

  /// Custom metadata map for arbitrary key-value context.
  final Map<String, dynamic> metadata;

  /// Creates an [InferenceTrace].
  const InferenceTrace({
    required this.traceId,
    required this.modelId,
    required this.modelFormat,
    this.deviceModel,
    this.osVersion,
    required this.timestamp,
    required this.totalDuration,
    required this.memoryStart,
    required this.memoryPeak,
    required this.memoryEnd,
    required this.thermalState,
    this.batteryDrainMah,
    this.cpuUsagePercent,
    this.layerTimings = const [],
    this.outputConfidence,
    this.metadata = const {},
  });

  /// Total duration in milliseconds.
  int get totalDurationMs => totalDuration.inMilliseconds;

  /// Net memory delta in MB between end and start of inference.
  double get memoryDeltaMb => memoryEnd.rssMb - memoryStart.rssMb;

  /// Peak RSS memory in MB.
  double get peakRssMb => memoryPeak.rssMb;

  /// Factory constructor to deserialize an [InferenceTrace] from JSON.
  factory InferenceTrace.fromJson(Map<String, dynamic> json) {
    return InferenceTrace(
      traceId: json['trace_id'] as String,
      modelId: json['model_id'] as String,
      modelFormat: json['model_format'] as String,
      deviceModel: json['device_model'] as String?,
      osVersion: json['os_version'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalDuration: Duration(milliseconds: json['total_duration_ms'] as int),
      memoryStart: MemorySnapshot.fromJson(
        json['memory_start'] as Map<String, dynamic>,
      ),
      memoryPeak: MemorySnapshot.fromJson(
        json['memory_peak'] as Map<String, dynamic>,
      ),
      memoryEnd: MemorySnapshot.fromJson(
        json['memory_end'] as Map<String, dynamic>,
      ),
      thermalState: ThermalState.fromString(json['thermal_state'] as String),
      batteryDrainMah: (json['battery_drain_mah'] as num?)?.toDouble(),
      cpuUsagePercent: (json['cpu_usage_percent'] as num?)?.toDouble(),
      layerTimings: (json['layer_timings'] as List<dynamic>?)
              ?.map((e) => LayerTiming.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      outputConfidence: (json['output_confidence'] as num?)?.toDouble(),
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  /// Serializes the trace to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'trace_id': traceId,
      'model_id': modelId,
      'model_format': modelFormat,
      'device_model': deviceModel,
      'os_version': osVersion,
      'timestamp': timestamp.toIso8601String(),
      'total_duration_ms': totalDurationMs,
      'memory_start': memoryStart.toJson(),
      'memory_peak': memoryPeak.toJson(),
      'memory_end': memoryEnd.toJson(),
      'thermal_state': thermalState.name,
      'battery_drain_mah': batteryDrainMah,
      'cpu_usage_percent': cpuUsagePercent,
      'layer_timings': layerTimings.map((e) => e.toJson()).toList(),
      'output_confidence': outputConfidence,
      'metadata': metadata,
    };
  }

  /// Returns a formatted Markdown string representation of the trace.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Inference Trace: $traceId');
    buffer.writeln('**Model:** $modelId ($modelFormat)');
    if (deviceModel != null || osVersion != null) {
      buffer.writeln(
        '**Device:** ${deviceModel ?? "Unknown"} (${osVersion ?? "Unknown OS"})',
      );
    }
    buffer.writeln('**Timestamp:** ${timestamp.toIso8601String()}');
    buffer.writeln();
    buffer.writeln('## Metric Summary');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('| --- | --- |');
    buffer.writeln('| Duration | ${totalDurationMs}ms |');
    buffer.writeln(
        '| Memory Start | ${memoryStart.rssMb.toStringAsFixed(1)} MB |');
    buffer
        .writeln('| Memory Peak | ${memoryPeak.rssMb.toStringAsFixed(1)} MB |');
    buffer.writeln('| Memory End | ${memoryEnd.rssMb.toStringAsFixed(1)} MB |');
    buffer.writeln(
        '| Memory Delta | ${memoryDeltaMb >= 0 ? "+" : ""}${memoryDeltaMb.toStringAsFixed(1)} MB |');
    buffer.writeln('| Thermal State | ${thermalState.name} |');
    if (cpuUsagePercent != null) {
      buffer.writeln('| CPU Usage | ${cpuUsagePercent!.toStringAsFixed(1)}% |');
    }
    if (batteryDrainMah != null) {
      buffer.writeln(
          '| Battery Drain | ${batteryDrainMah!.toStringAsFixed(4)} mAh |');
    }
    if (outputConfidence != null) {
      buffer.writeln(
          '| Output Confidence | ${(outputConfidence! * 100).toStringAsFixed(1)}% |');
    }

    if (layerTimings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Layer Timings');
      buffer.writeln('| Layer | Type | Duration | Output Size |');
      buffer.writeln('| --- | --- | --- | --- |');
      for (final layer in layerTimings) {
        buffer.writeln(
          '| ${layer.layerName} | ${layer.layerType} | ${layer.duration.inMilliseconds}ms | ${layer.outputSizeBytes ?? "-"} B |',
        );
      }
    }

    return buffer.toString();
  }

  /// Converts the trace row values into a CSV line format.
  String toCsvRow() {
    final values = [
      traceId,
      modelId,
      modelFormat,
      deviceModel ?? '',
      timestamp.toIso8601String(),
      totalDurationMs,
      memoryStart.rssMb,
      memoryPeak.rssMb,
      memoryEnd.rssMb,
      thermalState.name,
      batteryDrainMah ?? '',
      cpuUsagePercent ?? '',
      outputConfidence ?? '',
    ];
    return values.join(',');
  }

  /// CSV header row matching [toCsvRow].
  static String get csvHeader =>
      'trace_id,model_id,model_format,device_model,timestamp,duration_ms,memory_start_mb,memory_peak_mb,memory_end_mb,thermal_state,battery_mah,cpu_percent,confidence';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InferenceTrace &&
          runtimeType == other.runtimeType &&
          traceId == other.traceId &&
          modelId == other.modelId &&
          modelFormat == other.modelFormat &&
          deviceModel == other.deviceModel &&
          osVersion == other.osVersion &&
          timestamp.isAtSameMomentAs(other.timestamp) &&
          totalDuration == other.totalDuration &&
          memoryStart == other.memoryStart &&
          memoryPeak == other.memoryPeak &&
          memoryEnd == other.memoryEnd &&
          thermalState == other.thermalState &&
          batteryDrainMah == other.batteryDrainMah &&
          cpuUsagePercent == other.cpuUsagePercent &&
          outputConfidence == other.outputConfidence;

  @override
  int get hashCode => Object.hash(
        traceId,
        modelId,
        modelFormat,
        deviceModel,
        osVersion,
        timestamp,
        totalDuration,
        memoryStart,
        memoryPeak,
        memoryEnd,
        thermalState,
        batteryDrainMah,
        cpuUsagePercent,
        outputConfidence,
      );
}
