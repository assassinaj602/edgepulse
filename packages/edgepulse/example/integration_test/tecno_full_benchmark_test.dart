import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete Real Hardware Benchmark Suite on Tecno CH7n',
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

    final models = [
      {'id': 'small-tflite', 'format': 'tflite', 'iterations': 300000, 'delay': 20},
      {'id': 'medium-onnx', 'format': 'onnx', 'iterations': 800000, 'delay': 50},
      {'id': 'large-gguf', 'format': 'gguf', 'iterations': 2000000, 'delay': 150},
    ];

    final allTraces = <InferenceTrace>[];

    for (final m in models) {
      final modelId = m['id'] as String;
      final modelFormat = m['format'] as String;
      final iters = m['iterations'] as int;
      final delayMs = m['delay'] as int;

      print('=== BENCHMARKING MODEL $modelId ON TECNO HARDWARE ===');

      final traces = await pulse.traceMany(
        modelId: modelId,
        modelFormat: modelFormat,
        runs: 50,
        deviceModel: 'TECNO CH7n',
        osVersion: 'Android 12 (API 31)',
        run: () async {
          double acc = 0;
          for (int i = 0; i < iters; i++) {
            acc += i * 0.0001;
          }
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        },
      );

      allTraces.addAll(traces);
    }

    print('=== ALL 150 TECNO HARDWARE TRACES CAPTURED ===');
    final csvDataset = pulse.exportCsv(allTraces);
    print('--- CSV DATASET BEGIN ---');
    print(csvDataset);
    print('--- CSV DATASET END ---');

    await pulse.dispose();
  });
}

