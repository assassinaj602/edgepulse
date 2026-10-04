/// EdgePulse Flutter plugin — runtime observability for on-device AI.
///
/// This library re-exports everything from [edgepulse_core] and adds
/// [PlatformMetricCollector] for reading real device metrics.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:edgepulse/edgepulse.dart';
///
/// final collector = PlatformMetricCollector();
/// final pulse = EdgePulse(collector: collector);
///
/// await pulse.initialize();
///
/// final trace = await pulse.trace(
///   modelId: 'gemma-2b-q4',
///   modelFormat: 'gguf',
///   run: () => myModel.runInference(input),
/// );
///
/// print(trace.toMarkdown());
/// await pulse.dispose();
/// ```
library edgepulse;

export 'package:edgepulse_core/edgepulse_core.dart';
export 'src/platform_metric_collector.dart';
