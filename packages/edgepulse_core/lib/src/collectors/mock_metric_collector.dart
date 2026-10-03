import '../models/memory_snapshot.dart';
import '../models/thermal_state.dart';
import 'metric_collector.dart';

/// Configurable mock implementation of [MetricCollector] for testing without hardware.
class MockMetricCollector implements MetricCollector {
  /// Base Resident Set Size (RSS) memory in MB.
  double baseRssMb;

  /// Peak Resident Set Size (RSS) memory in MB.
  double peakRssMb;

  /// Thermal state returned by the mock.
  ThermalState thermalState;

  /// Battery drain rate returned by the mock in mAh.
  double? batteryDrainMah;

  /// CPU usage percentage returned by the mock.
  double? cpuUsagePercent;

  /// If true, memory reading increases slightly on each call to simulate memory leak/growth.
  bool simulateMemoryGrowth;

  /// Call counts for verification in unit tests.
  int initializeCallCount = 0;
  int disposeCallCount = 0;
  int captureMemoryCallCount = 0;
  int captureThermalCallCount = 0;
  int captureBatteryCallCount = 0;
  int captureCpuCallCount = 0;

  /// Creates a [MockMetricCollector].
  MockMetricCollector({
    this.baseRssMb = 256.0,
    this.peakRssMb = 480.0,
    this.thermalState = ThermalState.nominal,
    this.batteryDrainMah = 0.018,
    this.cpuUsagePercent = 72.0,
    this.simulateMemoryGrowth = false,
  });

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Future<MemorySnapshot> captureMemory() async {
    captureMemoryCallCount++;
    if (simulateMemoryGrowth) {
      baseRssMb += 5.0;
    }
    return MemorySnapshot(
      rssMb: baseRssMb,
      heapMb: baseRssMb * 0.4,
      nativeMb: baseRssMb * 0.6,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<ThermalState> captureThermalState() async {
    captureThermalCallCount++;
    return thermalState;
  }

  @override
  Future<double?> captureBatteryDrainMah() async {
    captureBatteryCallCount++;
    return batteryDrainMah;
  }

  @override
  Future<double?> captureCpuUsagePercent() async {
    captureCpuCallCount++;
    return cpuUsagePercent;
  }

  @override
  Future<void> dispose() async {
    disposeCallCount++;
  }
}
