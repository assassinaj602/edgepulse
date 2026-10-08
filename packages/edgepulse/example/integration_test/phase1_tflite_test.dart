// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final results = <Map<String, dynamic>>[];

  testWidgets('Real TFLite inference on device — MobileNetV3-Small',
      (tester) async {
    // 1. Load the real TFLite model
    print('[EdgePulse] Loading MobileNetV3-Small...');
    final interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/mobilenet_v3_small.tflite',
    );

    // 2. Inspect actual input/output shapes (robust against quantized variants)
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    print('[EdgePulse] Input shape:  ${inputTensor.shape}');
    print('[EdgePulse] Input type:   ${inputTensor.type}');
    print('[EdgePulse] Output shape: ${outputTensor.shape}');
    print('[EdgePulse] Output type:  ${outputTensor.type}');

    // 3. Build a matching input buffer
    final inputShape = inputTensor.shape; // e.g. [1, 224, 224, 3]
    final inputSize = inputShape.reduce((a, b) => a * b);
    final input = List.filled(inputSize, 0.5).reshape(inputShape);

    final outputShape = outputTensor.shape; // e.g. [1, 1001]
    final outputSize = outputShape.reduce((a, b) => a * b);
    final output = List.filled(outputSize, 0.0).reshape(outputShape);

    // 4. Run 30 real traces through EdgePulse
    final pulse = EdgePulse(
      collector: PlatformMetricCollector(),
      config: const TraceConfig(
        warmupRuns: 5,
        measuredRuns: 30,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );
    await pulse.initialize();

    print('[EdgePulse] Starting 30 real inference traces...');

    final traces = await pulse.traceMany(
      modelId: 'mobilenet-v3-small-tflite',
      modelFormat: 'tflite',
      runs: 30,
      run: () async {
        interpreter.run(input, output);
      },
    );

    print('[EdgePulse] Captured ${traces.length} traces');

    for (final t in traces) {
      results.add({
        'model_id': t.modelId,
        'model_format': t.modelFormat,
        'duration_ms': t.totalDurationMs,
        'memory_start_mb': t.memoryStart?.rssMb,
        'memory_peak_mb': t.memoryPeak?.rssMb,
        'memory_end_mb': t.memoryEnd?.rssMb,
        'thermal_state': t.thermalState.name,
        'battery_mah': t.batteryDrainMah,
        'cpu_percent': t.cpuUsagePercent,
      });
    }

    await pulse.dispose();
    interpreter.close();

    // 5. Sanity assertions
    expect(traces.length, 30);
    expect(traces.every((t) => t.totalDurationMs > 0), isTrue);

    print('[EdgePulse] Phase 1 PASSED');
  });

  tearDownAll(() {
    print('--- CSV DATASET BEGIN ---');
    print('model_id,model_format,duration_ms,memory_start_mb,memory_peak_mb,'
        'memory_end_mb,thermal_state,battery_mah,cpu_percent');
    for (final r in results) {
      print('${r['model_id']},${r['model_format']},${r['duration_ms']},'
          '${r['memory_start_mb']},${r['memory_peak_mb']},${r['memory_end_mb']},'
          '${r['thermal_state']},${r['battery_mah']},${r['cpu_percent']}');
    }
    print('--- CSV DATASET END ---');
  });
}

