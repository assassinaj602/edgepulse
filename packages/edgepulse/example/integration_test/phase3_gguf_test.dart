import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fllama/fllama.dart';
import 'package:edgepulse/edgepulse.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final results = <Map<String, dynamic>>[];

  testWidgets('Real GGUF inference on device — TinyLlama 1.1B Q4_K_M', (WidgetTester tester) async {
    var modelFile = File('/sdcard/Android/data/io.github.edgepulse.edgepulse_example/files/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
    if (!await modelFile.exists()) {
      modelFile = File('/sdcard/Download/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
    }
    expect(await modelFile.exists(), isTrue, reason: 'GGUF model file must exist at app storage path');

    print('[EdgePulse] Initializing Fllama context for TinyLlama 1.1B GGUF...');
    final fllama = Fllama.instance()!;
    final ctx = await fllama.initContext(
      modelFile.path,
      nCtx: 512,
      nThreads: 4,
      useMmap: true,
    );
    expect(ctx, isNotNull, reason: 'Fllama context initialization must succeed');
    final double contextId = (ctx!['contextId'] as num).toDouble();
    print('[EdgePulse] Fllama context initialized successfully (ID: $contextId)');

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

    print('[EdgePulse] Starting 30 real GGUF inference traces...');
    final traces = await pulse.traceMany(
      modelId: 'tinyllama-1.1b-gguf',
      modelFormat: 'gguf',
      runs: 30,
      run: () async {
        await fllama.completion(
          contextId,
          prompt: 'Explain edge computing in one sentence:',
          nPredict: 16,
          temperature: 0.7,
        );
      },
    );

    print('[EdgePulse] Captured ${traces.length} GGUF traces');
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
    await fllama.releaseContext(contextId);

    expect(traces.length, equals(30));
    print('[EdgePulse] Phase 3 PASSED');
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

