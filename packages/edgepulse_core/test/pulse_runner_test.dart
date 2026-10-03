import 'package:edgepulse_core/edgepulse_core.dart';
import 'package:test/test.dart';

void main() {
  group('PulseRunner', () {
    late MockMetricCollector mockCollector;
    late PulseRunner runner;

    setUp(() {
      mockCollector = MockMetricCollector();
      runner = PulseRunner(collector: mockCollector);
    });

    test('trace single inference run', () async {
      final trace = await runner.trace(
        modelId: 'resnet50',
        modelFormat: 'onnx',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
      );

      expect(trace.modelId, equals('resnet50'));
      expect(trace.modelFormat, equals('onnx'));
      expect(trace.totalDurationMs, greaterThanOrEqualTo(15));
      expect(trace.traceId, startsWith('ep_'));
      expect(trace.memoryStart.rssMb, equals(256.0));
      expect(trace.thermalState, equals(ThermalState.nominal));
      expect(trace.batteryDrainMah, equals(0.018));
      expect(trace.cpuUsagePercent, equals(72.0));
    });

    test('traceMany performs warmup and measured runs', () async {
      int runCounter = 0;
      final traces = await runner.traceMany(
        modelId: 'test_model',
        modelFormat: 'tflite',
        runs: 5,
        run: () async {
          runCounter++;
        },
      );

      // Default warmup is 3, measured is 5 -> total calls to run() = 8
      expect(runCounter, equals(8));

      // Traces returned only count measured runs
      expect(traces.length, equals(5));
      expect(mockCollector.initializeCallCount, equals(1));
      expect(mockCollector.disposeCallCount, equals(1));
    });

    test('trace summary calculates correct percentiles and metrics', () async {
      final summary = await runner.traceSummary(
        modelId: 'llama-3',
        modelFormat: 'gguf',
        runs: 10,
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      );

      expect(summary.modelId, equals('llama-3'));
      expect(summary.traces.length, equals(10));
      expect(summary.meanDuration.inMilliseconds, greaterThanOrEqualTo(5));
      expect(summary.p50Duration.inMilliseconds, greaterThanOrEqualTo(5));
      expect(summary.p95Duration.inMilliseconds, greaterThanOrEqualTo(5));
      expect(summary.p99Duration.inMilliseconds, greaterThanOrEqualTo(5));
      expect(summary.worstThermalState, equals(ThermalState.nominal));

      final json = summary.toJson();
      expect(json['total_runs'], equals(10));

      final markdown = summary.toMarkdown();
      expect(markdown, contains('# Trace Summary Report for llama-3'));
    });

    test('catches inference exceptions and records error in metadata', () async {
      final trace = await runner.trace(
        modelId: 'failing_model',
        modelFormat: 'tflite',
        run: () async {
          throw StateError('Out of memory during tensor allocation');
        },
      );

      expect(trace.metadata, contains('error'));
      expect(
        trace.metadata['error'],
        contains('Out of memory during tensor allocation'),
      );
      expect(trace.metadata, contains('stack_trace'));
    });

    test('respects TraceConfig collection flags', () async {
      final noMetricRunner = PulseRunner(
        collector: mockCollector,
        config: const TraceConfig(
          collectMemory: false,
          collectThermal: false,
          collectBattery: false,
          collectCpu: false,
        ),
      );

      final trace = await noMetricRunner.trace(
        modelId: 'light_model',
        modelFormat: 'tflite',
        run: () async {},
      );

      expect(trace.memoryStart.rssMb, equals(0.0));
      expect(trace.thermalState, equals(ThermalState.unknown));
      expect(trace.batteryDrainMah, isNull);
      expect(trace.cpuUsagePercent, isNull);
    });
  });
}
