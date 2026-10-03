import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('MockMetricCollector', () {
    late MockMetricCollector collector;

    setUp(() {
      collector = MockMetricCollector();
    });

    test('default configuration values', () async {
      final mem = await collector.captureMemory();
      final thermal = await collector.captureThermalState();
      final battery = await collector.captureBatteryDrainMah();
      final cpu = await collector.captureCpuUsagePercent();

      expect(mem.rssMb, equals(256.0));
      expect(thermal, equals(ThermalState.nominal));
      expect(battery, equals(0.018));
      expect(cpu, equals(72.0));
    });

    test('custom configuration values', () async {
      final custom = MockMetricCollector(
        baseRssMb: 512.0,
        peakRssMb: 800.0,
        thermalState: ThermalState.serious,
        batteryDrainMah: 0.05,
        cpuUsagePercent: 95.0,
      );

      final mem = await custom.captureMemory();
      final thermal = await custom.captureThermalState();
      final battery = await custom.captureBatteryDrainMah();
      final cpu = await custom.captureCpuUsagePercent();

      expect(mem.rssMb, equals(512.0));
      expect(thermal, equals(ThermalState.serious));
      expect(battery, equals(0.05));
      expect(cpu, equals(95.0));
    });

    test('tracks call counts correctly', () async {
      expect(collector.initializeCallCount, equals(0));
      expect(collector.captureMemoryCallCount, equals(0));
      expect(collector.captureThermalCallCount, equals(0));
      expect(collector.captureBatteryCallCount, equals(0));
      expect(collector.captureCpuCallCount, equals(0));
      expect(collector.disposeCallCount, equals(0));

      await collector.initialize();
      await collector.captureMemory();
      await collector.captureMemory();
      await collector.captureThermalState();
      await collector.captureBatteryDrainMah();
      await collector.captureCpuUsagePercent();
      await collector.dispose();

      expect(collector.initializeCallCount, equals(1));
      expect(collector.captureMemoryCallCount, equals(2));
      expect(collector.captureThermalCallCount, equals(1));
      expect(collector.captureBatteryCallCount, equals(1));
      expect(collector.captureCpuCallCount, equals(1));
      expect(collector.disposeCallCount, equals(1));
    });

    test('simulates memory growth when enabled', () async {
      final growthCollector = MockMetricCollector(
        baseRssMb: 100.0,
        simulateMemoryGrowth: true,
      );

      final mem1 = await growthCollector.captureMemory();
      final mem2 = await growthCollector.captureMemory();
      final mem3 = await growthCollector.captureMemory();

      expect(mem1.rssMb, equals(105.0));
      expect(mem2.rssMb, equals(110.0));
      expect(mem3.rssMb, equals(115.0));
    });
  });
}
