// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';
import 'package:fllama/fllama.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final samples = <Map<String, dynamic>>[];

  testWidgets('Thermal stress: sustained TinyLlama inference for 15 minutes',
      (tester) async {
    var modelFile = File('/data/local/tmp/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
    if (!await modelFile.exists()) {
      modelFile = File('/sdcard/Android/data/io.github.edgepulse.edgepulse_example/files/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
    }
    if (!await modelFile.exists()) {
      modelFile = File('/sdcard/Download/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf');
    }
    expect(await modelFile.exists(), isTrue, reason: 'GGUF model file must exist');

    print('[THERMAL-GGUF] Initializing Fllama context for TinyLlama 1.1B GGUF...');
    final fllama = Fllama.instance()!;
    final initResult = await fllama.initContext(
      modelFile.path,
      nCtx: 512,
      nThreads: 4,
      useMmap: true,
    );
    expect(initResult, isNotNull, reason: 'Fllama context initialization must succeed');
    final double contextId = (initResult!['contextId'] as num).toDouble();
    print('[THERMAL-GGUF] Fllama context initialized successfully (ID: $contextId)');

    final pulse = EdgePulse(
      collector: PlatformMetricCollector(),
      config: const TraceConfig(
        warmupRuns: 0,
        measuredRuns: 1,
        collectMemory: true,
        collectThermal: true,
        collectBattery: true,
        collectCpu: true,
      ),
    );
    await pulse.initialize();

    final start = DateTime.now();
    final duration = const Duration(minutes: 15);
    var iterations = 0;
    var lastSampleSec = 0;

    print('[THERMAL-GGUF] Starting 15-minute TinyLlama loop');
    print('[THERMAL-GGUF] Elapsed_s,Iteration,Thermal,Latency_ms,RSS_MB,Battery_mA');

    while (DateTime.now().difference(start) < duration) {
      final t = await pulse.trace(
        modelId: 'thermal-stress-tinyllama',
        modelFormat: 'gguf',
        run: () async {
          await fllama.completion(
            contextId,
            prompt: 'Explain edge computing and neural networks in detail:',
            nPredict: 16,
            temperature: 0.7,
          );
        },
      );

      iterations++;
      final elapsedSec = DateTime.now().difference(start).inSeconds;

      if (elapsedSec >= lastSampleSec + 30) {
        lastSampleSec = elapsedSec;
        samples.add({
          'elapsed_s': elapsedSec,
          'iterations': iterations,
          'thermal_state': t.thermalState.name,
          'latency_ms': t.totalDurationMs,
          'rss_mb': t.memoryEnd?.rssMb ?? 0,
          'battery_ma': t.batteryDrainMah ?? 0,
        });

        print('[THERMAL-GGUF] $elapsedSec,$iterations,${t.thermalState.name},'
            '${t.totalDurationMs},'
            '${t.memoryEnd?.rssMb?.toStringAsFixed(1)},'
            '${t.batteryDrainMah?.toStringAsFixed(1)}');
      }
    }

    await pulse.dispose();
    await fllama.releaseContext(contextId);

    print('[THERMAL-GGUF] Total iterations: $iterations');
    expect(samples.length, greaterThan(5));
  });

  tearDownAll(() {
    print('--- THERMAL-GGUF CSV BEGIN ---');
    print('elapsed_s,iterations,thermal_state,latency_ms,rss_mb,battery_ma');
    for (final s in samples) {
      print('${s['elapsed_s']},${s['iterations']},${s['thermal_state']},'
          '${s['latency_ms']},${s['rss_mb']},${s['battery_ma']}');
    }
    print('--- THERMAL-GGUF CSV END ---');
  });
}
