// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Real Hardware Telemetry Capture on Tecno CH7n',
      (WidgetTester tester) async {
    final collector = PlatformMetricCollector();
    final pulse = EdgePulse(
      collector: collector,
      config: const TraceConfig(
        measuredRuns: 50,
        warmupRuns: 5,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );

    await pulse.initialize();

    // 1. Capture Device Info
    final deviceInfo = await collector.getDeviceInfo();
    print('=== REAL DEVICE INFO ===');
    print('Device Info: $deviceInfo');
    expect(deviceInfo.isNotEmpty, true);

    // 2. Capture Initial Real Metrics
    final memInit = await collector.captureMemory();
    final thermalInit = await collector.captureThermalState();
    final battInit = await collector.captureBatteryDrainMah();
    final cpuInit = await collector.captureCpuUsagePercent();

    print('=== INITIAL REAL HARDWARE METRICS ===');
    print('Process Memory (RSS): ${memInit.rssMb} MB (Heap: ${memInit.heapMb} MB, Native: ${memInit.nativeMb} MB)');
    print('Thermal State: $thermalInit');
    print('Battery Current Draw: $battInit mA');
    print('CPU Usage: $cpuInit %');

    // 3. Profile 50 Measured Runs on Physical Tecno Phone Hardware
    print('=== RUNNING REAL DEVICE TRACES (50 RUNS) ===');
    final traceList = await pulse.traceMany(
      modelId: 'tecno-real-hardware-tflite',
      modelFormat: 'tflite',
      runs: 50,
      run: () async {
        // Compute intensive matrix workload on phone hardware
        double sum = 0;
        for (int i = 0; i < 1000000; i++) {
          sum += i * 0.001;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );

    expect(traceList.length, 50);

    final memFinal = await collector.captureMemory();
    final thermalFinal = await collector.captureThermalState();
    final battFinal = await collector.captureBatteryDrainMah();
    final cpuFinal = await collector.captureCpuUsagePercent();

    print('=== FINAL REAL HARDWARE METRICS ===');
    print('Process Memory (RSS): ${memFinal.rssMb} MB (Heap: ${memFinal.heapMb} MB, Native: ${memFinal.nativeMb} MB)');
    print('Thermal State: $thermalFinal');
    print('Battery Current Draw: $battFinal mA');
    print('CPU Usage: $cpuFinal %');

    final jsonSummary = pulse.exportJson(traceList);
    print('=== COMPLETE TRACE JSON SUMMARY ===');
    print(jsonSummary);

    final csvSummary = pulse.exportCsv(traceList);
    print('=== COMPLETE TRACE CSV DATASET ===');
    print(csvSummary);

    await pulse.dispose();
  });
}

