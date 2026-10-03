import '../models/inference_trace.dart';
import 'json_exporter.dart';
import 'trace_exporter.dart';

/// Exporter that formats trace datasets into human-readable Markdown reports.
class MarkdownExporter implements TraceExporter {
  /// Creates a [MarkdownExporter].
  const MarkdownExporter();

  @override
  String export(List<InferenceTrace> traces) {
    if (traces.isEmpty) {
      return '# EdgePulse Inference Trace Report\n\nNo traces available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('# EdgePulse Inference Trace Report');
    buffer.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('Total Traces: ${traces.length}');
    buffer.writeln();

    for (int i = 0; i < traces.length; i++) {
      final trace = traces[i];
      buffer.writeln('---');
      buffer.writeln('## Run ${i + 1} (${trace.traceId})');
      buffer.writeln(trace.toMarkdown());
      buffer.writeln();
      buffer.writeln('<details>');
      buffer.writeln('<summary>Raw JSON</summary>');
      buffer.writeln();
      buffer.writeln('```json');
      buffer.writeln(const JsonExporter().exportSingle(trace));
      buffer.writeln('```');
      buffer.writeln('</details>');
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  String get fileExtension => 'md';
}
