// EdgePulse example code for pub.dev
import 'package:edgepulse/edgepulse.dart';

Future<void> main() async {
  // Initialize EdgePulse with MockMetricCollector (or PlatformMetricCollector)
  final pulse = EdgePulse(collector: MockMetricCollector());
  await pulse.initialize();

  // Profile an inference task
  final trace = await pulse.trace(
    modelId: 'sample-tflite',
    runCount: 5,
    action: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
  );

  print('Trace complete: ${trace.summary.meanDurationMs} ms mean duration');
  await pulse.dispose();
}
