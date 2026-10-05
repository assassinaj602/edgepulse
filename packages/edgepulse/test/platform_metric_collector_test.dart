import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.github.edgepulse/metrics'),
      (MethodCall call) async {
        switch (call.method) {
          case 'getDeviceInfo':
            return {
              'model': 'Pixel 8',
              'manufacturer': 'Google',
              'os_version': '14',
              'sdk_int': '34',
              'brand': 'google',
            };
          case 'captureMemory':
            return {
              'rss_mb': 312.4,
              'available_mb': 2048.0,
              'total_mb': 8192.0,
              'low_memory': false
            };
          case 'captureThermal':
            return 'nominal';
          case 'captureBattery':
            return 18.5;
          case 'captureCpu':
            return 67.3;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.github.edgepulse/metrics'),
      null,
    );
  });

  test('initialize() succeeds when getDeviceInfo returns a map', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    expect(collector.isInitialized, isTrue);
  });

  test('captureMemory() returns correct rssMb', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final snapshot = await collector.captureMemory();
    expect(snapshot.rssMb, closeTo(312.4, 0.01));
  });

  test('captureThermalState() returns ThermalState.nominal', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final state = await collector.captureThermalState();
    expect(state, ThermalState.nominal);
  });

  test('captureBatteryDrainMah() returns correct value', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final battery = await collector.captureBatteryDrainMah();
    expect(battery, closeTo(18.5, 0.01));
  });

  test('captureCpuUsagePercent() returns correct value', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final cpu = await collector.captureCpuUsagePercent();
    expect(cpu, closeTo(67.3, 0.01));
  });

  test('dispose() sets isInitialized to false', () async {
    final collector = PlatformMetricCollector();
    await collector.initialize();
    await collector.dispose();
    expect(collector.isInitialized, isFalse);
  });

  test('EdgePulse with PlatformMetricCollector runs a trace', () async {
    final pulse = EdgePulse(collector: PlatformMetricCollector());
    await pulse.initialize();
    final trace = await pulse.trace(
      modelId: 'test-model',
      modelFormat: 'tflite',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );
    expect(trace.modelId, equals('test-model'));
    expect(trace.totalDurationMs, greaterThan(0));
    await pulse.dispose();
  });

  test('captureThermalState() handles "unknown" gracefully', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.github.edgepulse/metrics'),
      (call) async => call.method == 'captureThermal' ? 'unknown' : null,
    );
    final collector = PlatformMetricCollector();
    final state = await collector.captureThermalState();
    expect(state, ThermalState.unknown);
    expect(state.isDegraded, isFalse);
  });

  test('captureBatteryDrainMah() returns null when unavailable (simulator)',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.github.edgepulse/metrics'),
      (call) async {
        if (call.method == 'getDeviceInfo') {
          return {
            'model': 'iPhone',
            'manufacturer': 'Apple',
            'os_version': '17.0',
            'sdk_int': 'ios',
            'brand': 'Apple'
          };
        }
        if (call.method == 'captureBattery') return null;
        if (call.method == 'captureMemory') {
          return {'rss_mb': 128.0, 'virtual_mb': 512.0};
        }
        if (call.method == 'captureThermal') return 'nominal';
        if (call.method == 'captureCpu') return 45.0;
        return null;
      },
    );
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final battery = await collector.captureBatteryDrainMah();
    expect(battery, isNull);
    await collector.dispose();
  });

  test('captureThermalState() returns ThermalState.serious correctly',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.github.edgepulse/metrics'),
      (call) async {
        if (call.method == 'getDeviceInfo') {
          return {
            'model': 'iPhone',
            'manufacturer': 'Apple',
            'os_version': '17.0',
            'sdk_int': 'ios',
            'brand': 'Apple'
          };
        }
        if (call.method == 'captureThermal') return 'serious';
        if (call.method == 'captureMemory') {
          return {'rss_mb': 200.0, 'virtual_mb': 600.0};
        }
        if (call.method == 'captureBattery') return 0.72;
        if (call.method == 'captureCpu') return 91.0;
        return null;
      },
    );
    final collector = PlatformMetricCollector();
    await collector.initialize();
    final state = await collector.captureThermalState();
    expect(state, ThermalState.serious);
    expect(state.isDegraded, isTrue);
    await collector.dispose();
  });

  test('ThermalState.isDegraded is true for critical', () {
    expect(ThermalState.critical.isDegraded, isTrue);
    expect(ThermalState.nominal.isDegraded, isFalse);
    expect(ThermalState.fair.isDegraded, isFalse);
  });
}
