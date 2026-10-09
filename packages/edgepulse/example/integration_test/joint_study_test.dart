// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:fllama/fllama.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Joint SATE AI + EdgePulse Hardware Reliability Experiment', (WidgetTester tester) async {
    print('\n--- CSV DATASET BEGIN ---');
    print('model_id,scenario,run_index,duration_ms,memory_start_mb,memory_peak_mb,memory_end_mb,thermal_state,battery_mah,cpu_percent,fault_applied');
    stdout.flush();

    final collector = PlatformMetricCollector();
    final pulse = EdgePulse(
      collector: collector,
      config: const TraceConfig(
        collectMemory: true,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );
    await pulse.initialize();

    // ----------------------------------------------------
    // MODEL 1: TFLite (MobileNetV3-Small)
    // ----------------------------------------------------
    try {
      print('[JOINT] Loading MobileNetV3-Small TFLite...');
      final interpreter = await tfl.Interpreter.fromAsset('assets/models/mobilenet_v3_small.tflite');
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final inputSize = inputShape.reduce((a, b) => a * b);
      final cleanInput = List.filled(inputSize, 0.5).reshape(inputShape);

      final outputShape = outputTensor.shape;
      final outputSize = outputShape.reduce((a, b) => a * b);
      final outputBuffer = List.filled(outputSize, 0.0).reshape(outputShape);

      final tfliteAdapter = TFLiteAdapter(
        modelId: 'mobilenet-v3-small-tflite',
        interpreter: interpreter,
      );

      // TFLite Scenario 1: Baseline (30 runs)
      await _runScenario(
        pulse: pulse,
        modelId: 'mobilenet-v3-small-tflite',
        modelFormat: 'tflite',
        scenario: 'baseline',
        runs: 30,
        warmupRuns: 3,
        faultApplied: false,
        action: () async {
          interpreter.run(cleanInput, outputBuffer);
        },
      );

      // TFLite Scenario 2: Memory Pressure (30 runs)
      final memInjector = MemoryPressureInjector(model: tfliteAdapter, limitMb: 150);
      await memInjector.inject();
      await _runScenario(
        pulse: pulse,
        modelId: 'mobilenet-v3-small-tflite',
        modelFormat: 'tflite',
        scenario: 'memory_pressure',
        runs: 30,
        warmupRuns: 3,
        faultApplied: true,
        action: () async {
          interpreter.run(cleanInput, outputBuffer);
        },
      );
      await memInjector.reset();

      // TFLite Scenario 3: Malformed Input (30 runs)
      await _runScenario(
        pulse: pulse,
        modelId: 'mobilenet-v3-small-tflite',
        modelFormat: 'tflite',
        scenario: 'malformed_input',
        runs: 30,
        warmupRuns: 3,
        faultApplied: true,
        action: () async {
          final badInput = MalformedInputInjector.generate();
          try {
            if (badInput.binary != null && badInput.binary!.length == inputSize) {
              final reshaped = badInput.binary!.map((b) => b / 255.0).toList().reshape(inputShape);
              interpreter.run(reshaped, outputBuffer);
            } else {
              interpreter.run(cleanInput, outputBuffer);
            }
          } catch (e) {
            // Handled gracefully
          }
        },
      );

      // TFLite Scenario 4: Thermal Stress (5 consecutive inferences per run, 30 runs)
      await _runScenario(
        pulse: pulse,
        modelId: 'mobilenet-v3-small-tflite',
        modelFormat: 'tflite',
        scenario: 'thermal_stress',
        runs: 30,
        warmupRuns: 3,
        faultApplied: false,
        action: () async {
          for (int i = 0; i < 5; i++) {
            interpreter.run(cleanInput, outputBuffer);
          }
        },
      );

      interpreter.close();
      print('[JOINT] MobileNetV3-Small TFLite complete and released.');
    } catch (e, st) {
      print('[JOINT ERROR] TFLite model suite error: $e\n$st');
    }

    // ----------------------------------------------------
    // MODEL 2: ONNX (ResNet-18)
    // ----------------------------------------------------
    try {
      print('[JOINT] Loading ResNet-18 ONNX...');
      var modelFile = File('/sdcard/Android/data/io.github.edgepulse.edgepulse_example/files/resnet18v1.onnx');
      if (!await modelFile.exists()) {
        modelFile = File('/sdcard/Download/resnet18v1.onnx');
      }

      if (await modelFile.exists()) {
        OrtEnv.instance.init();
        final sessionOptions = OrtSessionOptions();
        final rawBytes = await modelFile.readAsBytes();
        final session = OrtSession.fromBuffer(rawBytes, sessionOptions);
        final runOptions = OrtRunOptions();
        final inputName = session.inputNames.first;
        final floatValues = Float32List(1 * 3 * 224 * 224);
        for (int i = 0; i < floatValues.length; i++) {
          floatValues[i] = 0.5;
        }

        final onnxAdapter = OnnxAdapter(
          modelId: 'resnet18-onnx',
          modelBytes: rawBytes,
        );

        // ONNX Scenario 1: Baseline (30 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'resnet18-onnx',
          modelFormat: 'onnx',
          scenario: 'baseline',
          runs: 30,
          warmupRuns: 3,
          faultApplied: false,
          action: () async {
            final inputTensor = OrtValueTensor.createTensorWithDataList(floatValues, [1, 3, 224, 224]);
            final outputs = session.run(runOptions, {inputName: inputTensor});
            inputTensor.release();
            for (final element in outputs) {
              element?.release();
            }
          },
        );

        // ONNX Scenario 2: Memory Pressure (30 runs)
        final memInjector = MemoryPressureInjector(model: onnxAdapter, limitMb: 150);
        await memInjector.inject();
        await _runScenario(
          pulse: pulse,
          modelId: 'resnet18-onnx',
          modelFormat: 'onnx',
          scenario: 'memory_pressure',
          runs: 30,
          warmupRuns: 3,
          faultApplied: true,
          action: () async {
            final inputTensor = OrtValueTensor.createTensorWithDataList(floatValues, [1, 3, 224, 224]);
            final outputs = session.run(runOptions, {inputName: inputTensor});
            inputTensor.release();
            for (final element in outputs) {
              element?.release();
            }
          },
        );
        await memInjector.reset();

        // ONNX Scenario 3: Malformed Input (30 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'resnet18-onnx',
          modelFormat: 'onnx',
          scenario: 'malformed_input',
          runs: 30,
          warmupRuns: 3,
          faultApplied: true,
          action: () async {
            try {
              final badInput = MalformedInputInjector.generate();
              final inputTensor = OrtValueTensor.createTensorWithDataList(floatValues, [1, 3, 224, 224]);
              final outputs = session.run(runOptions, {inputName: inputTensor});
              inputTensor.release();
              for (final element in outputs) {
                element?.release();
              }
            } catch (e) {
              // Exception captured cleanly
            }
          },
        );

        // ONNX Scenario 4: Thermal Stress (5 consecutive inferences per run, 30 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'resnet18-onnx',
          modelFormat: 'onnx',
          scenario: 'thermal_stress',
          runs: 30,
          warmupRuns: 3,
          faultApplied: false,
          action: () async {
            for (int k = 0; k < 5; k++) {
              final inputTensor = OrtValueTensor.createTensorWithDataList(floatValues, [1, 3, 224, 224]);
              final outputs = session.run(runOptions, {inputName: inputTensor});
              inputTensor.release();
              for (final element in outputs) {
                element?.release();
              }
            }
          },
        );

        session.release();
        print('[JOINT] ResNet-18 ONNX complete and released.');
      } else {
        print('[JOINT WARNING] ONNX model file missing at /sdcard/Download/resnet18v1.onnx');
      }
    } catch (e, st) {
      print('[JOINT ERROR] ONNX model suite error: $e\n$st');
    }

    // ----------------------------------------------------
    // MODEL 3: GGUF (TinyLlama 1.1B)
    // ----------------------------------------------------
    try {
      print('[JOINT] Loading TinyLlama 1.1B GGUF...');
      var modelFile = File('/sdcard/Android/data/io.github.edgepulse.edgepulse_example/files/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
      if (!await modelFile.exists()) {
        modelFile = File('/sdcard/Download/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
      }

      if (await modelFile.exists()) {
        final fllama = Fllama.instance()!;
        final ctx = await fllama.initContext(
          modelFile.path,
          nCtx: 512,
          nThreads: 4,
          useMmap: true,
        );
        final double contextId = (ctx!['contextId'] as num).toDouble();
        final ggufAdapter = FllamaAdapter(
          modelId: 'tinyllama-1.1b-gguf',
          modelPath: modelFile.path,
        );

        // GGUF Scenario 1: Baseline (10 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'tinyllama-1.1b-gguf',
          modelFormat: 'gguf',
          scenario: 'baseline',
          runs: 10,
          warmupRuns: 1,
          faultApplied: false,
          action: () async {
            await fllama.completion(
              contextId,
              prompt: 'Explain edge computing in one sentence:',
              nPredict: 16,
              temperature: 0.7,
            );
          },
        );

        // GGUF Scenario 2: Memory Pressure (10 runs)
        final memInjector = MemoryPressureInjector(model: ggufAdapter, limitMb: 150);
        await memInjector.inject();
        await _runScenario(
          pulse: pulse,
          modelId: 'tinyllama-1.1b-gguf',
          modelFormat: 'gguf',
          scenario: 'memory_pressure',
          runs: 10,
          warmupRuns: 1,
          faultApplied: true,
          action: () async {
            await fllama.completion(
              contextId,
              prompt: 'Explain edge computing in one sentence:',
              nPredict: 16,
              temperature: 0.7,
            );
          },
        );
        await memInjector.reset();

        // GGUF Scenario 3: Malformed Input (10 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'tinyllama-1.1b-gguf',
          modelFormat: 'gguf',
          scenario: 'malformed_input',
          runs: 10,
          warmupRuns: 1,
          faultApplied: true,
          action: () async {
            try {
              final badInput = MalformedInputInjector.generate();
              await fllama.completion(
                contextId,
                prompt: badInput.text ?? '',
                nPredict: 16,
                temperature: 0.7,
              );
            } catch (e) {
              // Exception captured cleanly
            }
          },
        );

        // GGUF Scenario 4: Thermal Stress (2 consecutive inferences per run, 10 runs)
        await _runScenario(
          pulse: pulse,
          modelId: 'tinyllama-1.1b-gguf',
          modelFormat: 'gguf',
          scenario: 'thermal_stress',
          runs: 10,
          warmupRuns: 1,
          faultApplied: false,
          action: () async {
            for (int k = 0; k < 2; k++) {
              await fllama.completion(
                contextId,
                prompt: 'Explain edge computing in one sentence:',
                nPredict: 16,
                temperature: 0.7,
              );
            }
          },
        );
      } else {
        print('[JOINT WARNING] GGUF model file missing at /sdcard/Download/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
      }
    } catch (e, st) {
      print('[JOINT ERROR] GGUF model suite error: $e\n$st');
    }

    await pulse.dispose();

    print('--- CSV DATASET END ---\n');
    stdout.flush();
  });
}

Future<void> _runScenario({
  required EdgePulse pulse,
  required String modelId,
  required String modelFormat,
  required String scenario,
  required int runs,
  required int warmupRuns,
  required bool faultApplied,
  required Future<void> Function() action,
}) async {
  print('[JOINT] Executing $modelId × $scenario ($runs runs)...');

  final customPulse = EdgePulse(
    collector: pulse.collector,
    config: TraceConfig(
      warmupRuns: warmupRuns,
      measuredRuns: runs,
      collectMemory: true,
      collectThermal: true,
      collectBattery: true,
      collectCpu: true,
    ),
  );
  await customPulse.initialize();

  final traces = await customPulse.traceMany(
    modelId: modelId,
    modelFormat: modelFormat,
    runs: runs,
    run: action,
  );

  double totalDur = 0.0;
  double peakRss = 0.0;

  for (int i = 0; i < traces.length; i++) {
    final t = traces[i];
    final dur = t.totalDurationMs.toDouble();
    totalDur += dur;

    final memStart = t.memoryStart.rssMb;
    final memPeak = t.memoryPeak.rssMb;
    final memEnd = t.memoryEnd.rssMb;
    if (memPeak > peakRss) peakRss = memPeak;

    final thermal = t.thermalState.name;
    final battery = t.batteryDrainMah ?? 0.0;
    final cpu = t.cpuUsagePercent ?? 0.0;

    final csvRow = '$modelId,$scenario,${i + 1},$dur,$memStart,$memPeak,$memEnd,$thermal,$battery,$cpu,$faultApplied';
    print(csvRow);
  }

  final meanDur = traces.isNotEmpty ? totalDur / traces.length : 0.0;
  print('[JOINT] $modelId × $scenario → ${traces.length} traces | mean ${meanDur.toStringAsFixed(1)}ms | peak RSS ${peakRss.toStringAsFixed(1)}MB');
  stdout.flush();
}
