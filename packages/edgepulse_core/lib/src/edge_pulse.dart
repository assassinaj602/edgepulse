import 'collectors/metric_collector.dart';
import 'collectors/mock_metric_collector.dart';
import 'exporters/csv_exporter.dart';
import 'exporters/json_exporter.dart';
import 'exporters/markdown_exporter.dart';
import 'models/inference_trace.dart';
import 'models/trace_config.dart';
import 'pulse_runner.dart';
import 'trace_summary.dart';

/// The main user-facing API of EdgePulse.
///
/// Wraps a [MetricCollector] and provides a clean lifecycle:
///
/// ```dart
/// final pulse = EdgePulse.mock();
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
class EdgePulse {
  /// The metric collector backing this instance.
  final MetricCollector collector;

  /// The tracing configuration.
  final TraceConfig config;

  PulseRunner? _runner;
  bool _initialized = false;

  /// Creates an [EdgePulse] instance with the given collector and config.
  EdgePulse({
    required this.collector,
    this.config = const TraceConfig(),
  });

  /// Creates an [EdgePulse] instance wired to a [MockMetricCollector].
  /// Ideal for tests, CI environments, and CLI runs without a real device.
  factory EdgePulse.mock({
    TraceConfig config = const TraceConfig(),
    MockMetricCollector? collector,
  }) {
    return EdgePulse(
      collector: collector ?? MockMetricCollector(),
      config: config,
    );
  }

  /// Whether [initialize] has been called and [dispose] has not.
  bool get isInitialized => _initialized;

  /// Prepares the collector for use.
  /// Must be called before any tracing methods.
  Future<void> initialize() async {
    if (_initialized) return;
    await collector.initialize();
    _runner = PulseRunner(collector: collector, config: config);
    _initialized = true;
  }

  void _assertInitialized() {
    if (!_initialized || _runner == null) {
      throw StateError(
        'EdgePulse has not been initialized. Call initialize() first.',
      );
    }
  }

  /// Traces a single inference run.
  Future<InferenceTrace> trace({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    double? outputConfidence,
    String? deviceModel,
    String? osVersion,
    Map<String, dynamic> metadata = const {},
  }) {
    _assertInitialized();
    return _runner!.trace(
      modelId: modelId,
      modelFormat: modelFormat,
      run: run,
      outputConfidence: outputConfidence,
      deviceModel: deviceModel,
      osVersion: osVersion,
      metadata: metadata,
    );
  }

  /// Traces multiple inference runs and returns all traces.
  Future<List<InferenceTrace>> traceMany({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    int? runs,
    String? deviceModel,
    String? osVersion,
    Map<String, dynamic> metadata = const {},
  }) {
    _assertInitialized();
    return _runner!.traceMany(
      modelId: modelId,
      modelFormat: modelFormat,
      run: run,
      runs: runs,
      deviceModel: deviceModel,
      osVersion: osVersion,
      metadata: metadata,
    );
  }

  /// Traces multiple runs and returns an aggregated [TraceSummary].
  Future<TraceSummary> summary({
    required String modelId,
    required String modelFormat,
    required Future<dynamic> Function() run,
    String? deviceModel,
    String? osVersion,
  }) {
    _assertInitialized();
    return _runner!.traceSummary(
      modelId: modelId,
      modelFormat: modelFormat,
      run: run,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  /// Convenience: export a list of traces to pretty JSON.
  String exportJson(List<InferenceTrace> traces) =>
      const JsonExporter().export(traces);

  /// Convenience: export a list of traces to Markdown.
  String exportMarkdown(List<InferenceTrace> traces) =>
      const MarkdownExporter().export(traces);

  /// Convenience: export a list of traces to CSV.
  String exportCsv(List<InferenceTrace> traces) =>
      const CsvExporter().export(traces);

  /// Releases the underlying collector.
  Future<void> dispose() async {
    await collector.dispose();
    _runner = null;
    _initialized = false;
  }
}
