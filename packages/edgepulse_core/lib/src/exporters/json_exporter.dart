import 'dart:convert';

import '../models/inference_trace.dart';
import 'trace_exporter.dart';

/// Exporter that produces pretty-printed JSON output.
class JsonExporter implements TraceExporter {
  /// Whether to format the output JSON with indentations.
  final bool prettyPrint;

  /// Creates a [JsonExporter].
  const JsonExporter({this.prettyPrint = true});

  @override
  String export(List<InferenceTrace> traces) {
    final Map<String, dynamic> outputMap = {
      'total_traces': traces.length,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'traces': traces.map((t) => t.toJson()).toList(),
    };

    if (prettyPrint) {
      return const JsonEncoder.withIndent('  ').convert(outputMap);
    } else {
      return jsonEncode(outputMap);
    }
  }

  /// Exports a single trace object directly.
  String exportSingle(InferenceTrace trace) {
    if (prettyPrint) {
      return const JsonEncoder.withIndent('  ').convert(trace.toJson());
    } else {
      return jsonEncode(trace.toJson());
    }
  }

  @override
  String get fileExtension => 'json';
}
