import '../models/inference_trace.dart';

/// Abstract interface for exporting trace datasets to file formats.
abstract class TraceExporter {
  /// Exports a list of [InferenceTrace] instances into a formatted string.
  String export(List<InferenceTrace> traces);

  /// File extension associated with this export format (e.g. "json", "md", "csv").
  String get fileExtension;
}
