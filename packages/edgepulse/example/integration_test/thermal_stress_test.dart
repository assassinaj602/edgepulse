// ignore_for_file: avoid_print, invalid_null_aware_operator, prefer_const_declarations, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:edgepulse/edgepulse.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final samples = <Map<String, dynamic>>[];

  testWidgets('Thermal stress: sustained TFLite inference for 15 minutes',
      (tester) async {
    // Load MobileNetV3-Small (fast enough to loop, heavy enough to heat)
    final interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/mobilenet_v3_small.tflite',
      options: tfl.InterpreterOptions()..threads = 4, // burn 4 cores
    );

    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final inputSize = inputShape.reduce((a, b) => a * b);
    final outputSize = outputShape.reduce((a, b) => a * b);
    final input = List.filled(inputSize, 0.5).reshape(inputShape);
    final output = List.filled(outputSize, 0.0).reshape(outputShape);

    final pulse = EdgePulse(
      collector: PlatformMetricCollector(),
      config: const TraceConfig(
        warmupRuns: 0,
        measuredRuns: 1, // we control the loop ourselves
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
    final latencySamples = <int>[]; // last 20 latencies for rolling avg
    var lastSampleSecond = 0;

    print('[THERMAL] Starting 15-minute sustained inference loop');
    print('[THERMAL] Elapsed_s,Iteration,Thermal,Latency_ms,RSS_MB,Battery_mA');

    while (DateTime.now().difference(start) < duration) {
      final t = await pulse.trace(
        modelId: 'thermal-stress-mobilenet',
        modelFormat: 'tflite',
        run: () async {
          interpreter.run(input, output);
        },
      );

      iterations++;
      latencySamples.add(t.totalDurationMs);
      if (latencySamples.length > 20) latencySamples.removeAt(0);

      final elapsedSec = DateTime.now().difference(start).inSeconds;

      // Sample every 30 seconds
      if (elapsedSec >= lastSampleSecond + 30) {
        lastSampleSecond = elapsedSec;
        final rollingAvg =
            latencySamples.reduce((a, b) => a + b) ~/ latencySamples.length;

        samples.add({
          'elapsed_s': elapsedSec,
          'iterations': iterations,
          'thermal_state': t.thermalState.name,
          'rolling_avg_latency_ms': rollingAvg,
          'rss_mb': t.memoryEnd?.rssMb ?? 0,
          'battery_ma': t.batteryDrainMah ?? 0,
        });

        print('[THERMAL] $elapsedSec,$iterations,${t.thermalState.name},'
            '$rollingAvg,${t.memoryEnd?.rssMb?.toStringAsFixed(1)},'
            '${t.batteryDrainMah?.toStringAsFixed(1)}');
      }
    }

    await pulse.dispose();
    interpreter.close();

    print('[THERMAL] Loop finished. Total iterations: $iterations');
    print('[THERMAL] Total samples: ${samples.length}');

    // Assert we actually got data
    expect(samples.length, greaterThan(5));
    expect(iterations, greaterThan(100));
  });

  tearDownAll(() {
    print('--- THERMAL CSV BEGIN ---');
    print('elapsed_s,iterations,thermal_state,rolling_avg_latency_ms,'
        'rss_mb,battery_ma');
    for (final s in samples) {
      print('${s['elapsed_s']},${s['iterations']},${s['thermal_state']},'
          '${s['rolling_avg_latency_ms']},${s['rss_mb']},${s['battery_ma']}');
    }
    print('--- THERMAL CSV END ---');
  });
}

