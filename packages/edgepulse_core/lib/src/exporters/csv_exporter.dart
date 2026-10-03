import '../models/inference_trace.dart';
import 'trace_exporter.dart';

/// Exporter that exports trace datasets to CSV format.
class CsvExporter implements TraceExporter {
  /// Creates a [CsvExporter].
  const CsvExporter();

  @override
  String export(List<InferenceTrace> traces) {
    final buffer = StringBuffer();
    buffer.writeln(InferenceTrace.csvHeader);
    for (final trace in traces) {
      buffer.writeln(trace.toCsvRow());
    }
    return buffer.toString();
  }

  @override
  String get fileExtension => 'csv';
}
