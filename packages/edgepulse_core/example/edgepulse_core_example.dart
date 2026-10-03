// ignore_for_file: avoid_print
import 'package:edgepulse_core/edgepulse_core.dart';

Future<void> main() async {
  final pulse = EdgePulse.mock();

  await pulse.initialize();

  final traces = await pulse.traceMany(
    modelId: 'example-model',
    modelFormat: 'mock',
    runs: 3,
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
  );

  print('Captured ${traces.length} traces');
  print(pulse.exportJson(traces));

  await pulse.dispose();
}
