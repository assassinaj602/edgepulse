// EdgePulse example code for pub.dev
import 'package:edgepulse/edgepulse.dart';

Future<void> main() async {
  // Initialize EdgePulse with MockMetricCollector (or PlatformMetricCollector)
  final pulse = EdgePulse(collector: MockMetricCollector());
  await pulse.initialize();

  // Profile an inference task
  final trace = await pulse.trace(
    modelId: 'sample-tflite',
    modelFormat: 'tflite',
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
  );

  // Output trace metrics in Markdown format
  // ignore: avoid_print
  print(trace.toMarkdown());
  await pulse.dispose();
}
