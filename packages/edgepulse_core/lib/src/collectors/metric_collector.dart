import '../models/memory_snapshot.dart';
import '../models/thermal_state.dart';

/// Abstract interface for capturing system metrics during AI inference.
abstract class MetricCollector {
  /// Initializes the collector and underlying system monitoring resources.
  Future<void> initialize();

  /// Captures a point-in-time snapshot of process memory usage.
  Future<MemorySnapshot> captureMemory();

  /// Captures the current operating thermal state of the device.
  Future<ThermalState> captureThermalState();

  /// Captures battery energy consumption rate in milliampere-hours (mAh), or null if unsupported.
  Future<double?> captureBatteryDrainMah();

  /// Captures current average CPU usage percentage (0.0 to 100.0), or null if unsupported.
  Future<double?> captureCpuUsagePercent();

  /// Disposes and cleans up resources used by the collector.
  Future<void> dispose();
}
