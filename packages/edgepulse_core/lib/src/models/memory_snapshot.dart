import 'package:meta/meta.dart';

/// Point-in-time snapshot of process memory usage.
@immutable
class MemorySnapshot {
  /// Resident Set Size (RSS) in megabytes: actual RAM occupied in physical memory.
  final double rssMb;

  /// Dart managed heap memory in megabytes.
  final double heapMb;

  /// Native C/C++ heap allocation in megabytes (where TFLite/ONNX/GGUF allocate tensors).
  final double nativeMb;

  /// Timestamp when the snapshot was captured.
  final DateTime timestamp;

  /// Creates a [MemorySnapshot].
  const MemorySnapshot({
    required this.rssMb,
    required this.heapMb,
    required this.nativeMb,
    required this.timestamp,
  });

  /// Factory constructor to create a snapshot from JSON data.
  factory MemorySnapshot.fromJson(Map<String, dynamic> json) {
    return MemorySnapshot(
      rssMb: (json['rss_mb'] as num).toDouble(),
      heapMb: (json['heap_mb'] as num).toDouble(),
      nativeMb: (json['native_mb'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts the snapshot into a JSON map representation.
  Map<String, dynamic> toJson() {
    return {
      'rss_mb': rssMb,
      'heap_mb': heapMb,
      'native_mb': nativeMb,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorySnapshot &&
          runtimeType == other.runtimeType &&
          rssMb == other.rssMb &&
          heapMb == other.heapMb &&
          nativeMb == other.nativeMb &&
          timestamp.isAtSameMomentAs(other.timestamp);

  @override
  int get hashCode => Object.hash(rssMb, heapMb, nativeMb, timestamp);

  @override
  String toString() =>
      'MemorySnapshot(rssMb: $rssMb, heapMb: $heapMb, nativeMb: $nativeMb, timestamp: $timestamp)';
}
