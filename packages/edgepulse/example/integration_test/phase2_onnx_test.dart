// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final results = <Map<String, dynamic>>[];

  testWidgets('Real ONNX inference on device — ResNet-18', (WidgetTester tester) async {
    var modelFile = File('/sdcard/Android/data/io.github.edgepulse.edgepulse_example/files/resnet18v1.onnx');
    if (!await modelFile.exists()) {
      modelFile = File('/sdcard/Download/resnet18v1.onnx');
    }
    expect(await modelFile.exists(), isTrue, reason: 'ONNX model file must exist at app storage path');

    print('[EdgePulse] Initializing OrtEnv...');
    OrtEnv.instance.init();

    print('[EdgePulse] Creating OrtSession for ResNet-18...');
    final sessionOptions = OrtSessionOptions();
    final rawBytes = await modelFile.readAsBytes();
    final session = OrtSession.fromBuffer(rawBytes, sessionOptions);

    final runOptions = OrtRunOptions();

    // ResNet-18 input: [1, 3, 224, 224] Float32 tensor (150,528 elements)
    final inputShape = [1, 3, 224, 224];
    final floatValues = Float32List(1 * 3 * 224 * 224);
    for (int i = 0; i < floatValues.length; i++) {
      floatValues[i] = 0.5;
    }

    final inputName = session.inputNames.first;
    print('[EdgePulse] Input name: $inputName');
    print('[EdgePulse] Output names: ${session.outputNames}');

    final pulse = EdgePulse(
      collector: PlatformMetricCollector(),
      config: const TraceConfig(
        warmupRuns: 2,
        measuredRuns: 30,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );
    await pulse.initialize();

    print('[EdgePulse] Starting 30 real ONNX inference traces...');
    final traces = await pulse.traceMany(
      modelId: 'resnet-18-onnx',
      modelFormat: 'onnx',
      runs: 30,
      run: () async {
        final inputTensor = OrtValueTensor.createTensorWithDataList(
          floatValues,
          inputShape,
        );
        final runInputs = {inputName: inputTensor};
        final outputs = session.run(runOptions, runInputs);
        inputTensor.release();
        for (final o in outputs) {
          o?.release();
        }
      },
    );

    print('[EdgePulse] Captured ${traces.length} ONNX traces');
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
    runOptions.release();
    sessionOptions.release();
    session.release();
    OrtEnv.instance.release();

    expect(traces.length, equals(30));
    print('[EdgePulse] Phase 2 PASSED');
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
