import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('ThermalState', () {
    test('fromString parses valid states', () {
      expect(ThermalState.fromString('nominal'), equals(ThermalState.nominal));
      expect(ThermalState.fromString('FAIR'), equals(ThermalState.fair));
      expect(ThermalState.fromString('serious'), equals(ThermalState.serious));
      expect(
          ThermalState.fromString('critical'), equals(ThermalState.critical));
      expect(ThermalState.fromString('unknown'), equals(ThermalState.unknown));
    });

    test('fromString defaults to unknown for invalid values', () {
      expect(ThermalState.fromString('invalid_state'),
          equals(ThermalState.unknown));
      expect(ThermalState.fromString(''), equals(ThermalState.unknown));
    });
  });

  group('MemorySnapshot', () {
    final now = DateTime.utc(2026, 10, 3, 12, 0, 0);

    test('toJson and fromJson round-trip', () {
      final snapshot = MemorySnapshot(
        rssMb: 256.5,
        heapMb: 102.4,
        nativeMb: 154.1,
        timestamp: now,
      );

      final json = snapshot.toJson();
      final restored = MemorySnapshot.fromJson(json);

      expect(restored, equals(snapshot));
      expect(restored.hashCode, equals(snapshot.hashCode));
      expect(restored.rssMb, equals(256.5));
      expect(restored.heapMb, equals(102.4));
      expect(restored.nativeMb, equals(154.1));
    });

    test('toString contains memory info', () {
      final snapshot = MemorySnapshot(
        rssMb: 100.0,
        heapMb: 40.0,
        nativeMb: 60.0,
        timestamp: now,
      );
      expect(snapshot.toString(), contains('rssMb: 100.0'));
    });
  });

  group('LayerTiming', () {
    test('toJson and fromJson round-trip', () {
      const timing = LayerTiming(
        layerName: 'attention_0',
        layerType: 'attention',
        duration: Duration(milliseconds: 45),
        outputSizeBytes: 4096,
      );

      final json = timing.toJson();
      final restored = LayerTiming.fromJson(json);

      expect(restored, equals(timing));
      expect(restored.hashCode, equals(timing.hashCode));
      expect(restored.layerName, equals('attention_0'));
      expect(restored.duration.inMilliseconds, equals(45));
      expect(restored.outputSizeBytes, equals(4096));
    });

    test('handles null outputSizeBytes', () {
      const timing = LayerTiming(
        layerName: 'embedding',
        layerType: 'embedding',
        duration: Duration(milliseconds: 10),
      );

      final json = timing.toJson();
      final restored = LayerTiming.fromJson(json);

      expect(restored.outputSizeBytes, isNull);
    });
  });

  group('TraceConfig', () {
    test('default values', () {
      const config = TraceConfig();
      expect(config.collectMemory, isTrue);
      expect(config.collectThermal, isTrue);
      expect(config.collectBattery, isTrue);
      expect(config.collectCpu, isTrue);
      expect(config.collectLayerTimings, isFalse);
      expect(config.warmupRuns, equals(3));
      expect(config.measuredRuns, equals(10));
    });

    test('toJson and fromJson round-trip', () {
      const config = TraceConfig(
        collectMemory: false,
        collectThermal: true,
        collectBattery: false,
        collectCpu: true,
        collectLayerTimings: true,
        samplingInterval: Duration(milliseconds: 200),
        warmupRuns: 5,
        measuredRuns: 20,
      );

      final json = config.toJson();
      final restored = TraceConfig.fromJson(json);

      expect(restored, equals(config));
      expect(restored.hashCode, equals(config.hashCode));
      expect(restored.warmupRuns, equals(5));
      expect(restored.measuredRuns, equals(20));
      expect(restored.samplingInterval.inMilliseconds, equals(200));
    });
  });

  group('InferenceTrace', () {
    final now = DateTime.utc(2026, 10, 3, 12, 0, 0);

    final startMem = MemorySnapshot(
      rssMb: 200.0,
      heapMb: 80.0,
      nativeMb: 120.0,
      timestamp: now,
    );

    final peakMem = MemorySnapshot(
      rssMb: 350.0,
      heapMb: 120.0,
      nativeMb: 230.0,
      timestamp: now.add(const Duration(milliseconds: 50)),
    );

    final endMem = MemorySnapshot(
      rssMb: 220.0,
      heapMb: 90.0,
      nativeMb: 130.0,
      timestamp: now.add(const Duration(milliseconds: 100)),
    );

    test('getters calculate correct deltas', () {
      final trace = InferenceTrace(
        traceId: 'ep_123456',
        modelId: 'test_model',
        modelFormat: 'tflite',
        timestamp: now,
        totalDuration: const Duration(milliseconds: 100),
        memoryStart: startMem,
        memoryPeak: peakMem,
        memoryEnd: endMem,
        thermalState: ThermalState.nominal,
      );

      expect(trace.totalDurationMs, equals(100));
      expect(trace.memoryDeltaMb, equals(20.0));
      expect(trace.peakRssMb, equals(350.0));
    });

    test('toJson and fromJson round-trip', () {
      final trace = InferenceTrace(
        traceId: 'ep_test01',
        modelId: 'gemma-2b',
        modelFormat: 'gguf',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 14',
        timestamp: now,
        totalDuration: const Duration(milliseconds: 847),
        memoryStart: startMem,
        memoryPeak: peakMem,
        memoryEnd: endMem,
        thermalState: ThermalState.fair,
        batteryDrainMah: 0.025,
        cpuUsagePercent: 85.4,
        layerTimings: const [
          LayerTiming(
            layerName: 'attention',
            layerType: 'attn',
            duration: Duration(milliseconds: 400),
          ),
        ],
        outputConfidence: 0.94,
        metadata: const {'scenario': 'baseline'},
      );

      final json = trace.toJson();
      final restored = InferenceTrace.fromJson(json);

      expect(restored, equals(trace));
      expect(restored.hashCode, equals(trace.hashCode));
      expect(restored.deviceModel, equals('Pixel 8'));
      expect(restored.osVersion, equals('Android 14'));
      expect(restored.batteryDrainMah, equals(0.025));
      expect(restored.cpuUsagePercent, equals(85.4));
      expect(restored.outputConfidence, equals(0.94));
      expect(restored.metadata['scenario'], equals('baseline'));
    });

    test('toCsvRow produces valid CSV row', () {
      final trace = InferenceTrace(
        traceId: 'ep_csv1',
        modelId: 'mobilenet',
        modelFormat: 'tflite',
        timestamp: now,
        totalDuration: const Duration(milliseconds: 50),
        memoryStart: startMem,
        memoryPeak: peakMem,
        memoryEnd: endMem,
        thermalState: ThermalState.nominal,
      );

      final row = trace.toCsvRow();
      expect(row, contains('ep_csv1'));
      expect(row, contains('mobilenet'));
      expect(row, contains('tflite'));
      expect(row, contains('nominal'));
    });

    test('csvHeader contains expected columns', () {
      final header = InferenceTrace.csvHeader;
      expect(header, contains('trace_id'));
      expect(header, contains('model_id'));
      expect(header, contains('duration_ms'));
      expect(header, contains('memory_start_mb'));
    });
  });
}
